import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/route_model.dart';
import '../services/booking_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _start;
  LatLng? _end;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;

  final String _apiKey = '5b3ce3597851110001cf6248bc471630a22e479f8bc23ec4a6b5b086';

  Future<void> _getRoute(LatLng start, LatLng end) async {
    setState(() => _isLoadingRoute = true);

    final url = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$_apiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final coords = data['features'][0]['geometry']['coordinates'] as List;
          final route = coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList();

          setState(() {
            _routePoints = route;
            _isLoadingRoute = false;
          });

          if (route.isNotEmpty) {
            double minLat = route.first.latitude;
            double maxLat = route.first.latitude;
            double minLng = route.first.longitude;
            double maxLng = route.first.longitude;

            for (final point in route) {
              if (point.latitude < minLat) minLat = point.latitude;
              if (point.latitude > maxLat) maxLat = point.latitude;
              if (point.longitude < minLng) minLng = point.longitude;
              if (point.longitude > maxLng) maxLng = point.longitude;
            }

            final center = LatLng(
              (minLat + maxLat) / 2,
              (minLng + maxLng) / 2,
            );

            double zoom = 10.0;

            final latDiff = maxLat - minLat;
            final lngDiff = maxLng - minLng;
            final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

            if (maxDiff > 0) {
              zoom = 14 - (maxDiff * 20);
              if (zoom < 5) zoom = 5;
              if (zoom > 15) zoom = 15;
            }

            _mapController.move(center, zoom);
          }
        } else {
          setState(() => _isLoadingRoute = false);
          _showSnackBar('Nie można wyznaczyć trasy');
        }
      } else {
        setState(() => _isLoadingRoute = false);
        _showSnackBar('Błąd API: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoadingRoute = false);
      _showSnackBar('Błąd sieci: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<Polyline> _buildSavedPolylines() {
    try {
      final box = Hive.box<RouteModel>('routes');
      return box.values
          .where((route) => route.routePoints.isNotEmpty && route.isActive)
          .map((route) => Polyline(
        points: route.routePoints,
        color: Colors.blue.withOpacity(0.5),
        strokeWidth: 3,
      ))
          .toList();
    } catch (e) {
      return [];
    }
  }

  List<Marker> _buildSavedMarkers() {
    try {
      final box = Hive.box<RouteModel>('routes');
      List<Marker> markers = [];
      for (var route in box.values.where((r) => r.isActive)) {
        markers.add(Marker(
          point: route.start,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.green, size: 30),
        ));
        markers.add(Marker(
          point: route.end,
          width: 40,
          height: 40,
          child: const Icon(Icons.flag, color: Colors.red, size: 30),
        ));
      }
      return markers;
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveRouteToFirestore(Map<String, dynamic> routeData, User user) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final routeId = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}';

      final route = RouteModel(
        id: routeId,
        start: _start!,
        end: _end!,
        date: routeData['date'] as DateTime,
        seats: routeData['seats'] as int,
        routePoints: _routePoints,
        bookedSeats: 0,
        driverId: user.uid,
        driverName: user.displayName ?? 'Kierowca',
        totalCost: routeData['cost'] as double,
        passengerIds: [],
        isActive: true,
      );

      await firestore.collection('routes').doc(routeId).set(route.toFirestore());

      final box = Hive.box<RouteModel>('routes');
      await box.put(routeId, route);

      _showSnackBar('Trasa dodana do Firestore!');
    } catch (e) {
      _showSnackBar('Błąd zapisu do Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa tras'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(52.2297, 21.0122), // Warszawa
              initialZoom: 6,
              onTap: (tapPosition, point) {
                if (_isLoadingRoute) return;

                setState(() {
                  if (_start == null) {
                    _start = point;
                  } else if (_end == null) {
                    _end = point;
                    _getRoute(_start!, _end!);
                  } else {
                    _start = point;
                    _end = null;
                    _routePoints = [];
                  }
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.carpooling',
              ),
              PolylineLayer(
                polylines: [
                  if (_routePoints.isNotEmpty)
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4,
                      color: Colors.blue,
                    ),
                  ..._buildSavedPolylines(),
                ],
              ),
              MarkerLayer(
                markers: [
                  if (_start != null)
                    Marker(
                      point: _start!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: Colors.green, size: 30),
                    ),
                  if (_end != null)
                    Marker(
                      point: _end!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.flag, color: Colors.red, size: 30),
                    ),
                  ..._buildSavedMarkers(),
                ],
              ),
            ],
          ),
          if (_isLoadingRoute)
            const Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wybierz trasę',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_start != null)
                      Text('Start: ${_start!.latitude.toStringAsFixed(4)}, ${_start!.longitude.toStringAsFixed(4)}'),
                    if (_end != null)
                      Text('Koniec: ${_end!.latitude.toStringAsFixed(4)}, ${_end!.longitude.toStringAsFixed(4)}'),
                    if (_start != null && _end == null)
                      const Text('Kliknij na mapę, aby wybrać punkt końcowy'),
                    if (_start == null)
                      const Text('Kliknij na mapę, aby wybrać punkt startowy'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: () {
              setState(() {
                _start = null;
                _end = null;
                _routePoints = [];
              });
            },
            label: const Text('Wyczyść'),
            icon: const Icon(Icons.delete),
            backgroundColor: Colors.redAccent,
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            onPressed: () async {
              if (user == null) {
                _showSnackBar('Musisz być zalogowany');
                return;
              }

              if (_start != null && _end != null) {
                if (_routePoints.isEmpty) {
                  _showSnackBar('Najpierw wyznacz trasę!');
                  return;
                }

                final routeData = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (context) => RouteFormDialog(
                    start: _start!,
                    end: _end!,
                    routePoints: _routePoints,
                  ),
                );

                if (routeData != null) {
                  await _saveRouteToFirestore(routeData, user);
                }
              } else {
                _showSnackBar('Wybierz punkt startu i końca!');
              }
            },
            label: const Text('Dodaj trasę'),
            icon: const Icon(Icons.save),
          ),
        ],
      ),
    );
  }
}

class RouteFormDialog extends StatefulWidget {
  final LatLng start;
  final LatLng end;
  final List<LatLng> routePoints;

  const RouteFormDialog({
    super.key,
    required this.start,
    required this.end,
    required this.routePoints,
  });

  @override
  State<RouteFormDialog> createState() => _RouteFormDialogState();
}

class _RouteFormDialogState extends State<RouteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _date;
  int _seats = 4;
  double _cost = 50.0;
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _costController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _date = DateTime.now().add(const Duration(hours: 1));
    _timeController.text = '${_date!.hour.toString().padLeft(2, '0')}:${_date!.minute.toString().padLeft(2, '0')}';
    _costController.text = _cost.toString();
  }

  @override
  void dispose() {
    _timeController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dodaj trasę'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.location_on, color: Colors.green),
                title: const Text('Start:'),
                subtitle: Text('${widget.start.latitude.toStringAsFixed(4)}, ${widget.start.longitude.toStringAsFixed(4)}'),
              ),
              ListTile(
                leading: const Icon(Icons.flag, color: Colors.red),
                title: const Text('Koniec:'),
                subtitle: Text('${widget.end.latitude.toStringAsFixed(4)}, ${widget.end.longitude.toStringAsFixed(4)}'),
              ),
              const Divider(),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Data odjazdu',
                  hintText: _date == null ? 'Wybierz datę' : '${_date!.day}.${_date!.month}.${_date!.year}',
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _date = date;
                    });
                  }
                },
                validator: (val) => _date == null ? 'Wybierz datę' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Godzina odjazdu (HH:MM)',
                  suffixIcon: Icon(Icons.access_time),
                ),
                keyboardType: TextInputType.datetime,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Wpisz godzinę';
                  final parts = val.split(':');
                  if (parts.length != 2) return 'Niepoprawny format';
                  final h = int.tryParse(parts[0]);
                  final m = int.tryParse(parts[1]);
                  if (h == null || m == null) return 'Niepoprawny format';
                  if (h < 0 || h > 23 || m < 0 || m > 59) return 'Niepoprawny czas';

                  final selectedDateTime = DateTime(
                    _date!.year,
                    _date!.month,
                    _date!.day,
                    h,
                    m,
                  );
                  if (selectedDateTime.isBefore(DateTime.now())) {
                    return 'Czas nie może być wstecz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _seats.toString(),
                decoration: const InputDecoration(
                  labelText: 'Liczba miejsc',
                  suffixIcon: Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  _seats = int.tryParse(val) ?? 4;
                },
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Wpisz liczbę miejsc';
                  final seats = int.tryParse(val);
                  if (seats == null || seats <= 0) return 'Niepoprawna liczba';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  labelText: 'Koszt całkowity (PLN)',
                  suffixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  _cost = double.tryParse(val) ?? 50.0;
                },
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Wpisz koszt';
                  final cost = double.tryParse(val);
                  if (cost == null || cost < 0) return 'Niepoprawny koszt';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Anuluj'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final timeParts = _timeController.text.split(':');
              final h = int.parse(timeParts[0]);
              final m = int.parse(timeParts[1]);

              final departureDateTime = DateTime(
                _date!.year,
                _date!.month,
                _date!.day,
                h,
                m,
              );

              Navigator.pop(
                context,
                {
                  'date': departureDateTime,
                  'seats': _seats,
                  'cost': _cost,
                },
              );
            }
          },
          child: const Text('Zapisz'),
        ),
      ],
    );
  }
}