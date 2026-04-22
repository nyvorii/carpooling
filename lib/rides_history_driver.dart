import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/route_model.dart';
import 'models/booking_model.dart';

class RidesHistoryDriverScreen extends StatelessWidget {
  const RidesHistoryDriverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Twoje trasy (Kierowca)"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: Text('Zaloguj się, aby zobaczyć historię'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('routes')
                  .where('driverId', isEqualTo: user.uid)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Błąd: ${snapshot.error}'));
                }

                final routes = snapshot.data?.docs.map((doc) => RouteModel.fromFirestore(doc)).toList() ?? [];

                if (routes.isEmpty) {
                  return const Center(
                    child: Text('Nie utworzyłeś jeszcze żadnych tras'),
                  );
                }

                return Column(
                  children: [
                    _buildGlobalSummary(routes),
                    Expanded(
                      child: ListView.builder(
                        itemCount: routes.length,
                        itemBuilder: (context, index) {
                          final route = routes[index];
                          return _buildRouteCard(context, route);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildGlobalSummary(List<RouteModel> routes) {
    double totalExpected = routes.fold(0, (sum, r) => sum + r.totalCost);
    // Note: We'd need to fetch bookings to see actual collected money,
    // but for the driver, we show the total cost of their trips.

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.green[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem("Trasy", routes.length.toString()),
          _summaryItem("Suma kosztów", "${totalExpected.toStringAsFixed(2)} PLN"),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
      ],
    );
  }

  Widget _buildRouteCard(BuildContext context, RouteModel route) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        leading: Icon(
          route.isActive ? Icons.directions_car : Icons.history,
          color: route.isActive ? Colors.green : Colors.grey,
        ),
        title: Text("${route.startAddress} → ${route.endAddress}"),
        subtitle: Text("Data: ${_formatDate(route.date)}\nKoszt trasy: ${route.totalCost.toStringAsFixed(2)} PLN"),
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('routeId', isEqualTo: route.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();

              final bookings = snapshot.data!.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();

              if (bookings.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Brak pasażerów"),
                );
              }

              double collected = bookings.fold(0, (sum, b) => sum + b.costShare);

              return Column(
                children: [
                  ...bookings.map((b) => ListTile(
                    dense: true,
                    title: Text(b.passengerName),
                    trailing: Text("${b.costShare.toStringAsFixed(2)} PLN"),
                    subtitle: Text("Status: ${b.status}"),
                  )),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Zebrano od pasażerów:", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("${collected.toStringAsFixed(2)} PLN", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      "Twój udział: ${(route.totalCost - collected).toStringAsFixed(2)} PLN",
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  )
                ],
              );
            },
          )
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
