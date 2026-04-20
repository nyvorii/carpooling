import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStatisticsScreen extends StatelessWidget {
  const AdminStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('routes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final routes = snapshot.data!.docs;

        if (routes.isEmpty) {
          return const Center(child: Text("Brak danych do statystyk"));
        }

        // ===== ANALIZA =====
        Map<String, int> driverStats = {};
        int totalPassengers = 0;
        int activeRoutes = 0;
        int inactiveRoutes = 0;

        for (var doc in routes) {
          final data = doc.data() as Map<String, dynamic>;

          final driver = data['driverName'] ?? 'Nieznany';
          final seats = data['bookedSeats'] ?? 0;
          final isActive = data['isActive'] ?? false;

          // kierowcy
          driverStats[driver] = (driverStats[driver] ?? 0) + 1;

          // pasażerowie
          totalPassengers += (seats as int);

          // status
          if (isActive) {
            activeRoutes++;
          } else {
            inactiveRoutes++;
          }
        }

        String topDriver = _getTop(driverStats);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCard("📈 Liczba wszystkich tras", "${routes.length}"),

            _buildCard("👥 Łączna liczba pasażerów", "$totalPassengers"),

            _buildCard("🟢 Aktywne trasy", "$activeRoutes"),
            _buildCard("🔴 Zakończone trasy", "$inactiveRoutes"),

            const SizedBox(height: 20),

            _buildSectionTitle("🏆 Najaktywniejszy kierowca"),
            _buildCard("", topDriver),

            const SizedBox(height: 20),

            _buildSectionTitle("👨‍✈️ Statystyki kierowców"),
            ...driverStats.entries.map((e) => _buildListItem(
                  e.key,
                  "${e.value} tras",
                )),
          ],
        );
      },
    );
  }

  String _getTop(Map<String, int> map) {
    if (map.isEmpty) return "Brak danych";

    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return "${sorted.first.key} (${sorted.first.value})";
  }

  Widget _buildCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: title.isNotEmpty ? Text(title) : null,
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildListItem(String title, String subtitle) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(subtitle),
      ),
    );
  }
}