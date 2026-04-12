import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import '../services/booking_service.dart';
import '../models/route_model.dart';
import '../services/cached_geocoding_service.dart';
import '../models/route_filters_model.dart';

class AvailableRoutesScreen extends StatefulWidget {
  const AvailableRoutesScreen({super.key});

  @override
  State<AvailableRoutesScreen> createState() => _AvailableRoutesScreenState();
}

class _AvailableRoutesScreenState extends State<AvailableRoutesScreen> {
  final Map<String, String> _addressCache = {};
  bool _isLoadingStats = false;
  final CachedGeocodingService _geocodingService = CachedGeocodingService();

  RouteFilters _activeFilters = RouteFilters.defaultFilters;
  bool _showFilters = false;
  final TextEditingController _maxPriceController = TextEditingController();
  final TextEditingController _minRatingController = TextEditingController();
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;
  int _selectedMinSeats = 1;
  TimeOfDay? _selectedTimeFrom;
  TimeOfDay? _selectedTimeTo;
  double _selectedMinRating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadRouteStats();
  }

  @override
  void dispose() {
    _maxPriceController.dispose();
    _minRatingController.dispose();
    super.dispose();
  }

  Future<void> _loadRouteStats() async {
    setState(() => _isLoadingStats = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoadingStats = false);
  }

  // odleglosc miedzy dystansami
  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, point1, point2);
  }

  bool _isTimeBefore(TimeOfDay t1, TimeOfDay t2) {
    return t1.hour < t2.hour || (t1.hour == t2.hour && t1.minute < t2.minute);
  }

  bool _isTimeAfter(TimeOfDay t1, TimeOfDay t2) {
    return t1.hour > t2.hour || (t1.hour == t2.hour && t1.minute > t2.minute);
  }

  // funckcja dla filtrow
  List<RouteModel> _applyFilters(List<RouteModel> routes) {
    if (!_activeFilters.hasFilters) return routes;

    return routes.where((route) {
      // fffiltr daty
      if (_activeFilters.dateFrom != null &&
          route.date.isBefore(_activeFilters.dateFrom!)) {
        return false;
      }
      if (_activeFilters.dateTo != null &&
          route.date.isAfter(_activeFilters.dateTo!)) {
        return false;
      }

      // filtr czasu
      final routeTime = TimeOfDay.fromDateTime(route.date);
      if (_activeFilters.timeFrom != null &&
          _isTimeBefore(routeTime, _activeFilters.timeFrom!)) {
        return false;
      }
      if (_activeFilters.timeTo != null &&
          _isTimeAfter(routeTime, _activeFilters.timeTo!)) {
        return false;
      }

      // filtr ceny
      if (_activeFilters.maxPrice != null &&
          route.totalCost > _activeFilters.maxPrice!) {
        return false;
      }

      // filtr dostępnych miejsc
      if (_activeFilters.minSeats != null &&
          route.availableSeats < _activeFilters.minSeats!) {
        return false;
      }

      // filtr oceny kierowcy
      if (_activeFilters.minRating != null &&
          route.driverRating < _activeFilters.minRating!) {
        return false;
      }

      // filtr odleglosci (jesli znami lokalizacje uzytkownika)
      if (_activeFilters.userLocation != null &&
          _activeFilters.searchRadiusKm != null) {
        final distanceToStart = _calculateDistance(
            _activeFilters.userLocation!,
            route.start
        );
        if (distanceToStart > _activeFilters.searchRadiusKm!) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _showFilterDialog(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtruj trasy',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // data od
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        _selectedDateFrom == null
                            ? 'Data od (dowolna)'
                            : 'Od: ${_selectedDateFrom!.day}.${_selectedDateFrom!.month}.${_selectedDateFrom!.year}',
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => _selectedDateFrom = date);
                        }
                      },
                    ),

                    // data do
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        _selectedDateTo == null
                            ? 'Data do (dowolna)'
                            : 'Do: ${_selectedDateTo!.day}.${_selectedDateTo!.month}.${_selectedDateTo!.year}',
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => _selectedDateTo = date);
                        }
                      },
                    ),

                  const Divider(),

                    // od czasu
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(
                        _selectedTimeFrom == null
                            ? 'Od godziny (dowolna)'
                            : 'Od: ${_selectedTimeFrom!.format(context)}',
                      ),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() => _selectedTimeFrom = time);
                        }
                      },
                    ),

                    // do czasu
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(
                        _selectedTimeTo == null
                            ? 'Do godziny (dowolna)'
                            : 'Do: ${_selectedTimeTo!.format(context)}',
                      ),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() => _selectedTimeTo = time);
                        }
                      },
                    ),

                    const Divider(),

                    // cena maksymalna
                    TextField(
                      controller: _maxPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Maksymalna cena (PLN)',
                        prefixIcon: Icon(Icons.attach_money),
                        hintText: 'np. 50.00',
                      ),
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 16),

                    // minimalna ilosc miejsc
                    DropdownButtonFormField<int>(
                      initialValue: _selectedMinSeats,
                      decoration: const InputDecoration(
                        labelText: 'Minimalna liczba miejsc',
                        prefixIcon: Icon(Icons.people),
                      ),
                      items: [1, 2, 3, 4, 5, 6, 7, 8]
                          .map((seats) => DropdownMenuItem(
                        value: seats,
                        child: Text('$seats ${seats == 1 ? 'miejsce' : 'miejsca'}'),
                      ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedMinSeats = value);
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // minimalna ocena kierowcy
                    const Text('Minimalna ocena kierowcy'),
                    Slider(
                      value: _selectedMinRating,
                      min: 0,
                      max: 5,
                      divisions: 10,
                      label: _selectedMinRating.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() => _selectedMinRating = value);
                      },
                    ),
                    Text('Ocena ≥ ${_selectedMinRating.toStringAsFixed(1)}'),

                    const SizedBox(height: 24),

                    // przyciski
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            // czysc filtry
                            setState(() {
                              _selectedDateFrom = null;
                              _selectedDateTo = null;
                              _maxPriceController.clear();
                              _selectedMinSeats = 1;
                              _selectedTimeFrom = null;
                              _selectedTimeTo = null;
                              _selectedMinRating = 0.0;
                            });
                          },
                          child: const Text('Wyczyść'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // zastosowanie filtrow
                            _activeFilters = RouteFilters(
                              dateFrom: _selectedDateFrom,
                              dateTo: _selectedDateTo,
                              maxPrice: _maxPriceController.text.isNotEmpty
                                  ? double.tryParse(_maxPriceController.text)
                                  : null,
                              minSeats: _selectedMinSeats,
                              timeFrom: _selectedTimeFrom,
                              timeTo: _selectedTimeTo,
                              minRating: _selectedMinRating > 0 ? _selectedMinRating : null,
                            );
                            Navigator.pop(context);
                            setState(() => _showFilters = _activeFilters.hasFilters);
                          },
                          child: const Text('Zastosuj filtry'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String> _getRouteTitle(RouteModel route) async {
    if (route.startAddress.isNotEmpty && route.endAddress.isNotEmpty) {
      final shortenedStart = _shortenAddress(route.startAddress);
      final shortenedEnd = _shortenAddress(route.endAddress);
      return '$shortenedStart → $shortenedEnd';
    }

    try {
      final startAddress = await _geocodingService.coordinatesToAddress(route.start);
      final endAddress = await _geocodingService.coordinatesToAddress(route.end);

      final shortenedStart = _shortenAddress(startAddress);
      final shortenedEnd = _shortenAddress(endAddress);
      return '$shortenedStart → $shortenedEnd';
    } catch (e) {
      print('[RouteTitle] Błąd geokodowania: $e');
      return '${_formatLocation(route.start)} → ${_formatLocation(route.end)}';
    }
  }

  Future<String> _getFullAddress(RouteModel route) async {
    if (route.startAddress.isNotEmpty && route.endAddress.isNotEmpty) {
      return 'Z: ${route.startAddress}\nDo: ${route.endAddress}';
    }

    try {
      final startAddress = await _geocodingService.coordinatesToAddress(route.start);
      final endAddress = await _geocodingService.coordinatesToAddress(route.end);

      return 'Z: $startAddress\nDo: $endAddress';
    } catch (e) {
      return 'Z: ${_formatLocation(route.start)}\nDo: ${_formatLocation(route.end)}';
    }
  }

  String _shortenAddress(String address) {
    if (address.length <= 30) return address;

    final parts = address.split(',');
    if (parts.isNotEmpty) {
      return parts.first;
    }

    return '${address.substring(0, 27)}...';
  }

  String _formatLocation(LatLng location) {
    return '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(2)} PLN';
  }

  Widget _buildActiveFiltersIndicator() {
    if (!_activeFilters.hasFilters) return const SizedBox.shrink();

    int filterCount = 0;
    if (_activeFilters.dateFrom != null) filterCount++;
    if (_activeFilters.dateTo != null) filterCount++;
    if (_activeFilters.timeFrom != null) filterCount++;
    if (_activeFilters.timeTo != null) filterCount++;
    if (_activeFilters.maxPrice != null) filterCount++;
    if (_activeFilters.minSeats != null && _activeFilters.minSeats! > 1) filterCount++;
    if (_activeFilters.minRating != null) filterCount++;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_alt, size: 16, color: Colors.blueAccent),
          const SizedBox(width: 4),
          Text(
            '$filterCount ${filterCount == 1 ? 'filtr' : 'filtry'}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(BuildContext context, RouteModel route,
      BookingService bookingService, User user) {
    int selectedSeats = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Rezerwacja miejsca'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<String>(
                future: _getRouteTitle(route),
                builder: (context, snapshot) {
                  return Text(snapshot.data ?? '${_formatLocation(route.start)} → ${_formatLocation(route.end)}');
                },
              ),
              const SizedBox(height: 16),
              Text('Dostępne miejsca: ${route.availableSeats}'),
              const SizedBox(height: 8),
              DropdownButton<int>(
                value: selectedSeats,
                onChanged: (value) => setState(() => selectedSeats = value!),
                items: List.generate(route.availableSeats, (index) => index + 1)
                    .map((seats) =>
                    DropdownMenuItem(value: seats, child: Text('$seats miejsc')))
                    .toList(),
              ),
              const SizedBox(height: 8),
              Text(
                  'Koszt: ${(route.totalCost / route.seats * selectedSeats).toStringAsFixed(2)} PLN'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await bookingService.bookSeat(
                  route,
                  selectedSeats,
                  user.displayName ?? 'Pasażer',
                  user.email ?? '',
                );

                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pomyślnie zarezerwowano!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Błąd rezerwacji!')),
                  );
                }
              },
              child: const Text('Potwierdź'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final bookingService = Provider.of<BookingService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text("Dostępne trasy"),
            const SizedBox(width: 8),
            _buildActiveFiltersIndicator(),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoadingStats)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadRouteStats,
            ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_alt),
                if (_activeFilters.hasFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: const SizedBox(),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<RouteModel>>(
        stream: bookingService.getAvailableRoutes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Błąd ładowania tras',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Spróbuj ponownie'),
                    onPressed: () {
                      (context as Element).markNeedsBuild();
                    },
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Brak dostępnych tras',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sprawdź później lub dodaj własną trasę',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  if (_activeFilters.hasFilters)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _activeFilters = RouteFilters.defaultFilters;
                            _selectedDateFrom = null;
                            _selectedDateTo = null;
                            _maxPriceController.clear();
                            _selectedMinSeats = 1;
                            _selectedTimeFrom = null;
                            _selectedTimeTo = null;
                            _selectedMinRating = 0.0;
                          });
                        },
                        child: const Text('Wyczyść filtry'),
                      ),
                    ),
                ],
              ),
            );
          }

          final allRoutes = snapshot.data!;
          final filteredRoutes = _applyFilters(allRoutes);

          return Column(
            children: [
              if (_activeFilters.hasFilters && filteredRoutes.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.blueAccent.withOpacity(0.05),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Znaleziono ${filteredRoutes.length} z ${allRoutes.length} tras',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _activeFilters = RouteFilters.defaultFilters;
                            _selectedDateFrom = null;
                            _selectedDateTo = null;
                            _maxPriceController.clear();
                            _selectedMinSeats = 1;
                            _selectedTimeFrom = null;
                            _selectedTimeTo = null;
                            _selectedMinRating = 0.0;
                          });
                        },
                        child: const Text(
                          'Wyczyść filtry',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredRoutes.length,
                  itemBuilder: (context, index) {
                    final route = filteredRoutes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.directions_car, color: Colors.blue),
                        title: FutureBuilder<String>(
                          future: _getRouteTitle(route),
                          builder: (context, titleSnapshot) {
                            if (titleSnapshot.connectionState == ConnectionState.waiting) {
                              return Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${_formatLocation(route.start)} → ${_formatLocation(route.end)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              );
                            }

                            if (titleSnapshot.hasError) {
                              return Text(
                                '${_formatLocation(route.start)} → ${_formatLocation(route.end)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                              );
                            }

                            return Text(
                              titleSnapshot.data ?? '${_formatLocation(route.start)} → ${_formatLocation(route.end)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('📅 ${_formatDate(route.date)}'),
                            Text('👤 Kierowca: ${route.driverName}'),
                            Text('⭐ Ocena: ${route.driverRating.toStringAsFixed(1)}'),
                            Text('💰 Koszt: ${_formatPrice(route.totalCost)}'),
                            Text('🪑 Miejsca: ${route.availableSeats}/${route.seats}'),
                            FutureBuilder<String>(
                              future: _getFullAddress(route),
                              builder: (context, addressSnapshot) {
                                if (addressSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Text('Ładowanie szczegółów...');
                                }
                                return Text(
                                  addressSnapshot.data ?? _formatLocation(route.end),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                );
                              },
                            ),
                          ],
                        ),
                        trailing: user != null
                            ? ElevatedButton(
                          onPressed: () => _showBookingDialog(
                              context, route, bookingService, user),
                          child: const Text('Rezerwuj'),
                        )
                            : const Text('Zaloguj się'),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}