import 'package:flutter/material.dart';

class MyVehiclesScreen extends StatelessWidget {
  const MyVehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Moje pojazdy")),
      body: ListView(
        children: [

          // TUTAJ backend: pobieranie pojazdów użytkownika
          // await Backend.getVehicles()

          ListTile(
            leading: const Icon(Icons.directions_car),
            title: const Text("BMW 3 E90"),
            subtitle: const Text("Rejestracja: KR 6969"),
          ),
          ListTile(
            leading: const Icon(Icons.directions_car),
            title: const Text("Audi A4 B8"),
            subtitle: const Text("Rejestracja: WI 42069"),
          ),
        ],
      ),
    );
  }
}
