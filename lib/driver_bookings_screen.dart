import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/booking_service.dart';
import 'models/booking_model.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';


class DriverBookingsScreen extends StatelessWidget {
  const DriverBookingsScreen({super.key});

  void _showContactInfo(
    BuildContext context, {
    required String type,
  }) {
    String message;

    if (type == 'email') {
      message =
          'Funkcja wysyłania emaila działa na telefonie z zainstalowaną aplikacją pocztową.';
    } else {
      message =
          'Funkcja dzwonienia działa na telefonie z możliwością wykonywania połączeń.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phone,
    );

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }


  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Rezerwacje pasażerów"),
        backgroundColor: Colors.green[700],
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
            stream: bookingService.getDriverBookings(user.uid),
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
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Brak rezerwacji',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Twoi pasażerowie pojawią się tutaj',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              // przychód
              final totalRevenue = bookings.fold(0.0, (sum, booking) => sum + booking.costShare);

              return Column(
                children: [
                  // Podsumowanie finansowe
                  Card(
                    margin: const EdgeInsets.all(16),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Podsumowanie finansowe',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Łączny przychód: ${totalRevenue.toStringAsFixed(2)} PLN',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Liczba pasażerów: ${bookings.length}',
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Średnio na pasażera: ${(totalRevenue / bookings.length).toStringAsFixed(2)} PLN',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Lista pasazerow
                  Expanded(
                    child: ListView.builder(
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(booking.status),
                              child: Text(
                                booking.passengerName[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              booking.passengerName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Email: ${booking.passengerEmail}'),
                                Text('Miejsca: ${booking.seatsBooked}'),
                                Text('Koszt: ${booking.costShare.toStringAsFixed(2)} PLN'),
                                Text('Data rezerwacji: ${_formatDate(booking.createdAt)}'),
                                Text(
                                  'Status: ${_getStatusText(booking.status)}',
                                  style: TextStyle(
                                    color: _getStatusColor(booking.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) {
                                if (value == 'details') {
                                  _showPassengerDetails(context, booking);
                                } else if (value == 'contact') {
                                  _contactPassenger(context, booking);
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                const PopupMenuItem<String>(
                                  value: 'details',
                                  child: ListTile(
                                    leading: Icon(Icons.info),
                                    title: Text('Szczegóły'),
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'contact',
                                  child: ListTile(
                                    leading: Icon(Icons.email),
                                    title: Text('Kontakt'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blueAccent;
    }
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

  void _showPassengerDetails(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil pasażera'),
        content: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(booking.passengerId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Text('Nie znaleziono profilu pasażera');
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final String displayName = data['displayName'] ?? 'Brak imienia';
            final String? customPhotoUrl = data['customPhotoUrl'];
            final String? photoUrl = data['photoURL'];

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPassengerAvatar(
                  customBase64: customPhotoUrl,
                  photoUrl: photoUrl,
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
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

  Widget _buildPassengerAvatar({
    String? customBase64,
    String? photoUrl,
    double size = 90,
  }) {
    if (customBase64 != null && customBase64.isNotEmpty) {
      try {
        return ClipOval(
          child: Image.memory(
            base64Decode(customBase64),
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {}
    }

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: Colors.blueAccent,
        child: const Icon(Icons.person, size: 48, color: Colors.white),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _contactPassenger(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kontakt z pasażerem'),
        content: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(booking.passengerId)
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Text('Brak danych kontaktowych');
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final String? email = data['contactEmail'];
            final String? phone = data['contactPhone'];

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (email != null && email.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: Text(email),
                    onTap: () {
                      Navigator.pop(context);
                      _showContactInfo(context, type: 'email');
                      // to użyć jak telefon z funkcją 
                      // mail_sendEmail(email);
                    },
                  ),

                if (phone != null && phone.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: Text(phone),
                    onTap: () {
                      Navigator.pop(context);
                      _showContactInfo(context, type: 'phone');
                      // to użyć jak telefon z funkcją dzwonienia 
                      //_makePhoneCall(phone);
                    },
                  ),

                if ((email == null || email.isEmpty) &&
                    (phone == null || phone.isEmpty))
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Pasażer nie udostępnił danych kontaktowych',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
              ],
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


  Widget _buildContactOption(BuildContext context, String text, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(text),
      onTap: onTap,
    );
  }
}