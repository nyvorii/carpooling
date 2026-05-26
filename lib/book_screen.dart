import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/booking_service.dart';
import 'models/booking_model.dart';
import 'package:latlong2/latlong.dart';
import 'models/route_model.dart';
import 'services/cached_geocoding_service.dart'; // DODAJ
import 'models/review_model.dart';

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

                      final routeData = routeSnapshot.data!;
                      final route = RouteModel.fromFirestore(routeData);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(Icons.directions_car_filled, color: Colors.blueAccent),
                          title: FutureBuilder<Map<String, String>>(
                            future: _getRouteAddresses(route.toFirestore()),
                            builder: (context, addressSnapshot) {
                              if (addressSnapshot.connectionState == ConnectionState.waiting) {
                                return const Text('Ładowanie trasy...');
                              }
                              final addresses = addressSnapshot.data ?? {'start': 'Start', 'end': 'Koniec'};
                              final start = _shortenAddress(addresses['start']!);
                              final end = _shortenAddress(addresses['end']!);
                              return Text(
                                '$start → $end',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              );
                            },
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Data: ${_formatDate(route.date)}'),
                              Text('Koszt: ${booking.costShare.toStringAsFixed(2)} PLN'),
                              Text('Miejsca: ${booking.seatsBooked}'),
                              Text('Kierowca: ${route.driverName}'),
                              FutureBuilder<Map<String, String>>(
                                future: _getRouteAddresses(route.toFirestore()),
                                builder: (context, addressSnapshot) {
                                  if (addressSnapshot.connectionState == ConnectionState.waiting) {
                                    return const Text('Ładowanie adresów...');
                                  }
                                  final addresses = addressSnapshot.data ?? {'start': 'Start', 'end': 'Koniec'};
                                  return Text(
                                    'Z: ${addresses['start']}\nDo: ${addresses['end']}',
                                    style: const TextStyle(fontSize: 12),
                                  );
                                },
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (booking.status != 'completed')
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () => _showCancelDialog(context, booking, route, bookingService),
                                ),

                              if (route.date.isBefore(DateTime.now()) && booking.status == 'completed')
                                  TextButton(
                                    onPressed: () => _showReviewDialog(context, booking, route),
                                    child: const Text('Oceń', style: TextStyle(fontSize: 12)),
                                  ),
                            ],
                          ),
                          onTap: () {
                            _showBookingDetails(context, booking, route);
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

  Future<Map<String, String>> _getRouteAddresses(Map<String, dynamic> routeData) async {
    try {
      final geocodingService = CachedGeocodingService();

      // Sprawdź czy adresy są już zapisane w routeData
      final startAddressFromData = routeData['startAddress'] as String?;
      final endAddressFromData = routeData['endAddress'] as String?;

      String startAddress;
      String endAddress;

      if (startAddressFromData != null && startAddressFromData.isNotEmpty) {
        startAddress = startAddressFromData;
      } else {
        // Geokoduj start
        final startCoords = routeData['start'] as Map<String, dynamic>;
        final startLatLng = LatLng(
          startCoords['lat'] as double,
          startCoords['lng'] as double,
        );
        startAddress = await geocodingService.coordinatesToAddress(startLatLng);
      }

      if (endAddressFromData != null && endAddressFromData.isNotEmpty) {
        endAddress = endAddressFromData;
      } else {
        // Geokoduj end
        final endCoords = routeData['end'] as Map<String, dynamic>;
        final endLatLng = LatLng(
          endCoords['lat'] as double,
          endCoords['lng'] as double,
        );
        endAddress = await geocodingService.coordinatesToAddress(endLatLng);
      }

      return {
        'start': startAddress,
        'end': endAddress,
      };
    } catch (e) {
      // W razie błędu pokaż współrzędne
      final startCoords = routeData['start'] as Map<String, dynamic>;
      final endCoords = routeData['end'] as Map<String, dynamic>;
      return {
        'start': '${startCoords['lat']?.toStringAsFixed(4) ?? 0}, ${startCoords['lng']?.toStringAsFixed(4) ?? 0}',
        'end': '${endCoords['lat']?.toStringAsFixed(4) ?? 0}, ${endCoords['lng']?.toStringAsFixed(4) ?? 0}',
      };
    }
  }

  String _shortenAddress(String address) {
    if (address.length <= 25) return address;

    final parts = address.split(',');
    if (parts.length > 2) {
      return '${parts[0]}, ${parts[1]}...';
    }

    return '${address.substring(0, 22)}...';
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showCancelDialog(BuildContext context, BookingModel booking, RouteModel route, BookingService bookingService) {
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

  void _showBookingDetails(BuildContext context, BookingModel booking, RouteModel route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Szczegóły rezerwacji'),
        content: FutureBuilder<Map<String, String>>(
          future: _getRouteAddresses(route.toFirestore()),
          builder: (context, addressSnapshot) {
            if (addressSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final addresses = addressSnapshot.data ?? {'start': 'Start', 'end': 'Koniec'};

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Trasa: ${addresses['start']} → ${addresses['end']}'),
                  const SizedBox(height: 8),
                  Text('Data: ${_formatDate(route.date)}'),
                  const SizedBox(height: 8),
                  Text('Koszt: ${booking.costShare.toStringAsFixed(2)} PLN'),
                  const SizedBox(height: 8),
                  Text('Miejsca: ${booking.seatsBooked}'),
                  const SizedBox(height: 8),
                  Text('Kierowca: ${route.driverName}'),
                  const SizedBox(height: 8),
                  Text('Status: ${_getStatusText(booking.status)}'),
                  const SizedBox(height: 8),
                  Text('Data rezerwacji: ${_formatDate(booking.createdAt)}'),
                ],
              ),
            );
          },
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

  void _showReviewDialog(BuildContext context, BookingModel booking, RouteModel route) {
    int rating = 5;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oceń podróż'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: rating,
                items: List.generate(5, (i) => i + 1)
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text('$e ⭐'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => rating = v!),
              ),
              TextField(
                controller: controller,
                maxLength: 300,
                decoration: const InputDecoration(
                  hintText: 'Dodaj komentarz...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () async {
              final comment = controller.text.trim();

              final review = ReviewModel(
                id: '',
                routeId: route.id,
                reviewerId: booking.passengerId,
                reviewedUserId: route.driverId,
                rating: rating,
                comment: comment,
                createdAt: DateTime.now(),
              );

              final success = await Provider.of<BookingService>(context, listen: false)
                  .addReview(review);

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      success ? 'Dodano opinię' : 'Już oceniłeś tę podróż'),
                ),
              );
            },
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );
  }
}
