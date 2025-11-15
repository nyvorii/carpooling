import 'package:flutter/material.dart';

class RidesHistoryPassengerScreen extends StatelessWidget {
  const RidesHistoryPassengerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Historia przejazdów (pasażer)")),
      body: ListView(
        children: [
          // TUTAJ backend: pobierz przejazdy użytkownika jako pasażer
          // Example:
          // final rides = await Backend.getPassengerRides();

          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text("Warszawa → Kraków"),
            subtitle: const Text("12.04.2024, 14:00"),
          ),
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text("Gdańsk → Poznań"),
            subtitle: const Text("20.04.2024, 09:00"),
          ),
        ],
      ),
    );
  }
}
