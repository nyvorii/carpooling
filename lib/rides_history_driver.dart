import 'package:flutter/material.dart';

class RidesHistoryDriverScreen extends StatelessWidget {
  const RidesHistoryDriverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Historia przejazdów (kierowca)")),
      body: ListView(
        children: [
          // TUTAJ backend: pobierz przejazdy użytkownika jako kierowca

          ListTile(
            leading: const Icon(Icons.directions_car, color: Colors.blue),
            title: const Text("Łódź → Warszawa"),
            subtitle: const Text("02.04.2024, 07:30"),
          ),
        ],
      ),
    );
  }
}
