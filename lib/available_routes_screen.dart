import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'services/booking_service.dart';
import 'models/route_model.dart';

class AvailableRoutesScreen extends StatelessWidget {
  const AvailableRoutesScreen({super.key});

  // trasy do testa
  List<RouteModel> _getTestRoutes() {
    return [
      RouteModel(
        start: const LatLng(52.2297, 21.0122), // Warszawa
        end: const LatLng(50.0647, 19.9450),   // Krakow
        date: DateTime.now().add(const Duration(hours: 3)),
        seats: 4,
        bookedSeats: 1,
        routePoints: [],
        driverName: "Szybki John",
        driverId: "test_1",
        totalCost: 60.0,
        isActive: true,
      ),
      RouteModel(
        start: const LatLng(51.1079, 17.0385), // Breslau
        end: const LatLng(52.4064, 16.9252),   // Poznań
        date: DateTime.now().add(const Duration(hours: 5)),
        seats: 3,
        bookedSeats: 0,
        routePoints: [],
        driverName: "Robert Kubica",
        driverId: "test_2",
        totalCost: 45.0,
        isActive: true,
      ),
      RouteModel(
        start: const LatLng(54.3520, 18.6466), // Gdansk
        end: const LatLng(53.4289, 14.5530),   // Szczecin
        date: DateTime.now().add(const Duration(days: 1)),
        seats: 2,
        bookedSeats: 1,
        routePoints: [],
        driverName: "Andrzej Gazownik",
        driverId: "test_3",
        totalCost: 80.0,
        isActive: true,
      ),
    ];
  }

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
          final routes = snapshot.hasData ? snapshot.data! : _getTestRoutes();

          if (routes.isEmpty) {
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
                    'Firestore może być niedostępny',
                    style: TextStyle(fontSize: 14, color: Colors.orange),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.directions_car, color: Colors.blue),
                  title: Text(
                    '${_formatLocation(route.start)} → ${_formatLocation(route.end)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Data: ${_formatDate(route.date)}'),
                      Text('Kierowca: ${route.driverName}'),
                      Text('Koszt: ${route.totalCost.toStringAsFixed(2)} PLN'),
                      Text('Miejsca: ${route.avaiableSeats}/${route.seats}'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _showBookingDialog(context, route, bookingService, user!),
                    child: const Text('Rezerwuj'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatLocation(LatLng location) {
    return '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showBookingDialog(BuildContext context, RouteModel route, BookingService bookingService, User user) {
    int selectedSeats = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Rezerwacja miejsca'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Trasa: ${_formatLocation(route.start)} → ${_formatLocation(route.end)}'),
              const SizedBox(height: 16),
              Text('Dostępne miejsca: ${route.avaiableSeats}'),
              const SizedBox(height: 8),
              DropdownButton<int>(
                value: selectedSeats,
                onChanged: (value) => setState(() => selectedSeats = value!),
                items: List.generate(route.avaiableSeats, (index) => index + 1)
                    .map((seats) => DropdownMenuItem(value: seats, child: Text('$seats miejsc')))
                    .toList(),
              ),
              const SizedBox(height: 8),
              Text('Koszt: ${(route.totalCost / route.seats * selectedSeats).toStringAsFixed(2)} PLN'),
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
                    const SnackBar(content: Text('Błąd rezerwacji! Sprawdź połączenie z Firebase.')),
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