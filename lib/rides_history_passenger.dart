import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/booking_service.dart';
import 'models/booking_model.dart';
import 'models/route_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RidesHistoryPassengerScreen extends StatelessWidget {
  const RidesHistoryPassengerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final bookingService = Provider.of<BookingService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Historia Twoich przejazdów"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: Text('Zaloguj się, aby zobaczyć historię'))
          : StreamBuilder<List<BookingModel>>(
              stream: bookingService.getPassengerBookings(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Błąd: ${snapshot.error}'));
                }

                final bookings = snapshot.data ?? [];

                if (bookings.isEmpty) {
                  return const Center(
                    child: Text('Nie brałeś udziału w żadnych przejazdach'),
                  );
                }

                return ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('routes')
                          .doc(booking.routeId)
                          .get(),
                      builder: (context, routeSnapshot) {
                        String routeTitle = "Ładowanie...";
                        if (routeSnapshot.hasData && routeSnapshot.data!.exists) {
                          final routeData = routeSnapshot.data!.data() as Map<String, dynamic>;
                          routeTitle = "${routeData['startAddress'] ?? 'Punkt A'} → ${routeData['endAddress'] ?? 'Punkt B'}";
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: Icon(
                              booking.status == 'completed' ? Icons.check_circle : Icons.directions_car,
                              color: booking.status == 'completed' ? Colors.green : Colors.blue,
                            ),
                            title: Text(routeTitle),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Data: ${_formatDate(booking.createdAt)}'),
                                Text('Status: ${_getStatusText(booking.status)}'),
                                Text(
                                  'Twój koszt: ${booking.costShare.toStringAsFixed(2)} PLN',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ],
                            ),
                          ),
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

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed': return 'Potwierdzona';
      case 'cancelled': return 'Anulowana';
      case 'pending': return 'Oczekująca';
      case 'completed': return 'Zakończona';
      default: return status;
    }
  }
}
