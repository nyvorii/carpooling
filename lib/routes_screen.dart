import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'services/booking_service.dart';
import 'models/route_model.dart';
import 'services/nominatim_service.dart';

class AvailableRoutesScreen extends StatelessWidget {
  const AvailableRoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final bookingService = Provider.of<BookingService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dostępne trasy"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Brak dostępnych tras',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sprawdź później lub dodaj własną trasę',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          final routes = snapshot.data!;

          return ListView.builder(
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
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
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_formatLocation(route.start)} → ${_formatLocation(route.end)}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        );
                      }

                      if (titleSnapshot.hasError) {
                        return Text(
                          '${_formatLocation(route.start)} → ${_formatLocation(route.end)}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                        );
                      }

                      return Text(
                        titleSnapshot.data ?? '${_formatLocation(route.start)} → ${_formatLocation(route.end)}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Data: ${_formatDate(route.date)}'),
                      Text('Kierowca: ${route.driverName}'),
                      Text('Koszt: ${route.totalCost.toStringAsFixed(2)} PLN'),
                      Text('Miejsca: ${route.availableSeats}/${route.seats}'),
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
          );
        },
      ),
    );
  }

  Future<String> _getRouteTitle(RouteModel route) async {
    print('[RouteTitle] Sprawdzam trasę: ${route.id}');
    print('[RouteTitle] Adresy w modelu: "${route.startAddress}" -> "${route.endAddress}"');

    if (route.startAddress.isNotEmpty && route.endAddress.isNotEmpty) {
      print('[RouteTitle] Używam zapisanych adresów');
      final shortenedStart = _shortenAddress(route.startAddress);
      final shortenedEnd = _shortenAddress(route.endAddress);
      return '$shortenedStart → $shortenedEnd';
    }

    print('[RouteTitle] Brak adresów - geokoduję...');
    try {
      final startAddress = await NominatimService.coordinatesToAddress(route.start);
      final endAddress = await NominatimService.coordinatesToAddress(route.end);

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
      final startAddress = await NominatimService.coordinatesToAddress(route.start);
      final endAddress = await NominatimService.coordinatesToAddress(route.end);

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

    return address.substring(0, 27) + '...';
  }

  String _formatLocation(LatLng location) {
    return '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
}