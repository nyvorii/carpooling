import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/booking_service.dart';
import 'models/booking_model.dart';
import 'package:latlong2/latlong.dart';
import 'models/route_model.dart';

class BookScreen extends StatelessWidget {
  const BookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Moje rezerwacje"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(
        child: Text(
          'Zaloguj się, aby zobaczyć rezerwacje',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : Consumer<BookingService>(
        builder: (context, bookingService, child) {
          return StreamBuilder<List<BookingModel>>(
            stream: bookingService.getPassengerBookings(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Błąd: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final bookings = snapshot.data ?? [];

              if (bookings.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Brak aktywnych rezerwacji',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('routes').doc(booking.routeId).get(),
                    builder: (context, routeSnapshot) {
                      if (routeSnapshot.connectionState == ConnectionState.waiting) {
                        return const Card(
                          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: ListTile(
                            leading: CircularProgressIndicator(),
                            title: Text('Ładowanie...'),
                          ),
                        );
                      }

                      if (!routeSnapshot.hasData || !routeSnapshot.data!.exists) {
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: ListTile(
                            leading: const Icon(Icons.error, color: Colors.red),
                            title: const Text('Trasa nie istnieje'),
                            subtitle: Text('ID: ${booking.routeId}'),
                          ),
                        );
                      }

                      final routeData = routeSnapshot.data!.data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(Icons.directions_car_filled, color: Colors.blueAccent),
                          title: Text(
                            '${_getLocationName(routeData['start']) ?? 'Start'} → ${_getLocationName(routeData['end']) ?? 'Koniec'}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Data: ${_formatDate((routeData['date'] as Timestamp).toDate())}'),
                              Text('Koszt: ${booking.costShare.toStringAsFixed(2)} PLN'),
                              Text('Miejsca: ${booking.seatsBooked}'),
                              Text('Kierowca: ${routeData['driverName'] ?? 'Nieznany'}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            // POPRAWIONE: przekazujemy wszystkie 4 argumenty
                            onPressed: () => _showCancelDialog(context, booking, routeData, bookingService),
                          ),
                          onTap: () {
                            _showBookingDetails(context, booking, routeData);
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String? _getLocationName(dynamic location) {
    if (location is Map) {
      return location['address'] ?? 'Lokalizacja';
    }
    return null;
  }

  // POPRAWIONE: funkcja przyjmuje wszystkie 4 argumenty w poprawnej kolejności
  void _showCancelDialog(BuildContext context, BookingModel booking, Map<String, dynamic> routeData, BookingService bookingService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anulowanie rezerwacji'),
        content: const Text('Czy na pewno chcesz anulować tę rezerwację?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nie'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Utwórz tymczasowy RouteModel dla anulowania
              final startData = routeData['start'] as Map<String, dynamic>;
              final endData = routeData['end'] as Map<String, dynamic>;

              final route = RouteModel(
                start: LatLng(startData['lat'], startData['lng']),
                end: LatLng(endData['lat'], endData['lng']),
                date: (routeData['date'] as Timestamp).toDate(),
                seats: routeData['seats'] ?? 1,
                routePoints: [],
                driverId: routeData['driverId'] ?? '',
                driverName: routeData['driverName'] ?? '',
                totalCost: (routeData['totalCost'] ?? 0.0).toDouble(),
              );

              final success = await bookingService.cancelBooking(booking.id, route);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rezerwacja anulowana'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Błąd anulowania rezerwacji'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Tak', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(BuildContext context, BookingModel booking, Map<String, dynamic> routeData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Szczegóły rezerwacji'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Trasa: ${_getLocationName(routeData['start']) ?? 'Start'} → ${_getLocationName(routeData['end']) ?? 'Koniec'}'),
              const SizedBox(height: 8),
              Text('Data: ${_formatDate((routeData['date'] as Timestamp).toDate())}'),
              const SizedBox(height: 8),
              Text('Koszt: ${booking.costShare.toStringAsFixed(2)} PLN'),
              const SizedBox(height: 8),
              Text('Miejsca: ${booking.seatsBooked}'),
              const SizedBox(height: 8),
              Text('Kierowca: ${routeData['driverName'] ?? 'Nieznany'}'),
              const SizedBox(height: 8),
              Text('Status: ${_getStatusText(booking.status)}'),
              const SizedBox(height: 8),
              Text('Data rezerwacji: ${_formatDate(booking.createdAt)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Potwierdzona';
      case 'cancelled':
        return 'Anulowana';
      case 'pending':
        return 'Oczekująca';
      default:
        return status;
    }
  }
}