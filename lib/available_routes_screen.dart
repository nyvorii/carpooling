import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'services/booking_service.dart';
import 'models/route_model.dart';

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

          // obsluga bledow
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

          // dla braku danych
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
                      Text('Miejsca: ${route.availableSeats}/${route.seats}'),
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

  String _formatLocation(LatLng location) {
    /* mozna jeszcze dodać geocoding API zeby zamieniac wspolrzedne na adres TODO */
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
              Text('Trasa: ${_formatLocation(route.start)} → ${_formatLocation(route.end)}'),
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