import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'models/route_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'routes_menu_screen.dart';
import 'home_screen.dart';

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

  final String _apiKey = '5b3ce3597851110001cf6248bc471630a22e479f8bc23ec4a6b5b086';

  Future<void> _getRoute(LatLng start, LatLng end) async {
    final url = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$_apiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final coords = data['features'][0]['geometry']['coordinates'] as List;
      final route = coords.map((c) => LatLng(c[1], c[0])).toList();

      setState(() => _routePoints = route);
    } else {
      debugPrint('Błąd pobierania trasy: ${response.body}');
    }
  }

  List<Polyline> _buildSavedPolylines() {
    final box = Hive.box<RouteModel>('routes');
    return box.values
        .where((route) => route.routePoints.isNotEmpty)
        .map((route) => Polyline(
      points: route.routePoints,
      color: Colors.blue,
      strokeWidth: 4,
    ))
        .toList();
  }

  List<Marker> _buildSavedMarkers() {
    final box = Hive.box<RouteModel>('routes');
    List<Marker> markers = [];
    for (var route in box.values) {
      if (route.routePoints.isNotEmpty) {
        markers.add(Marker(
          point: route.start,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.green),
        ));
        markers.add(Marker(
          point: route.end,
          width: 40,
          height: 40,
          child: const Icon(Icons.flag, color: Colors.red),
        ));
      }
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa tras'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RoutesMenuScreen()),
              );
            },
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(52.2297, 21.0122),
          initialZoom: 13,
          onTap: (tapPosition, point) async {
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
                Polyline(points: _routePoints, strokeWidth: 4, color: Colors.blue),
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
                  child: const Icon(Icons.location_on, color: Colors.green),
                ),
              if (_end != null)
                Marker(
                  point: _end!,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.flag, color: Colors.red),
                ),
              ..._buildSavedMarkers(),
            ],
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: () => setState(() {
              _start = null;
              _end = null;
              _routePoints = [];
            }),
            label: const Text('Wyczyść'),
            icon: const Icon(Icons.delete),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            onPressed: () async {
              if (_start != null && _end != null) {
                if (_routePoints.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nie udało się pobrać trasy! Spróbuj ponownie.'))
                  );
                  return;
                }

                final newRoute = await showDialog<RouteModel>(
                  context: context,
                  builder: (context) => RouteFormDialog(
                    start: _start!,
                    end: _end!,
                    routePoints: _routePoints,
                  ),
                );
                if (newRoute != null) {
                  final box = Hive.box<RouteModel>('routes');
                  await box.add(newRoute);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Trasa zapisana!')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wybierz punkt startu i końca!')),
                );
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
  const RouteFormDialog({super.key, required this.start, required this.end, required this.routePoints});

  @override
  State<RouteFormDialog> createState() => _RouteFormDialogState();
}

class _RouteFormDialogState extends State<RouteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _date;
  int _seats = 1;
  final TextEditingController _timeController = TextEditingController();

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dodaj trasę'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: _date == null
                      ? 'Wybierz datę odjazdu'
                      : '${_date!.day}.${_date!.month}.${_date!.year}',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _date = date;
                    });
                  }
                },
                validator: (val) =>
                _date == null ? 'Wybierz datę odjazdu' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Godzina odjazdu (HH:MM)',
                  hintText: '00:00',
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
              const SizedBox(height: 10),
              TextFormField(
                initialValue: '1',
                decoration: const InputDecoration(labelText: 'Liczba miejsc'),
                keyboardType: TextInputType.number,
                onSaved: (val) => _seats = int.parse(val!),
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
              _formKey.currentState!.save();

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
                RouteModel(
                  start: widget.start,
                  end: widget.end,
                  date: departureDateTime,
                  seats: _seats,
                  routePoints: widget.routePoints,
                ),
              );
            }
          },
          child: const Text('Zapisz'),
        ),
      ],
    );
  }
}