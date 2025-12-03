import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/booking_service.dart';
import 'models/booking_model.dart';

class DriverBookingsScreen extends StatelessWidget {
  const DriverBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Rezerwacje pasażerów"),
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
        title: Text('Szczegóły pasażera: ${booking.passengerName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email:', booking.passengerEmail),
              _buildDetailRow('Zarezerwowane miejsca:', booking.seatsBooked.toString()),
              _buildDetailRow('Udział w kosztach:', '${booking.costShare.toStringAsFixed(2)} PLN'),
              _buildDetailRow('Data rezerwacji:', _formatDate(booking.createdAt)),
              _buildDetailRow('Ostatnia aktualizacja:', _formatDate(booking.updatedAt)),
              _buildDetailRow('Status:', _getStatusText(booking.status)),
              _buildDetailRow('ID rezerwacji:', booking.id),
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
        title: Text('Kontakt z ${booking.passengerName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${booking.passengerEmail}'),
            const SizedBox(height: 16),
            const Text(
              'Możesz skontaktować się z pasażerem poprzez:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildContactOption(
              context,
              'Wyślij email',
              Icons.email,
                  () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funkcja wysyłania emaila wkrótce dostępna')),
                );
              },
            ),
            _buildContactOption(
              context,
              'Zadzwoń',
              Icons.phone,
                  () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funkcja dzwonienia wkrótce dostępna')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
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