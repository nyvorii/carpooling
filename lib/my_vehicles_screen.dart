import 'package:flutter/material.dart';

class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  final List<Map<String, String>> vehicles = [];

  final _formKey = GlobalKey<FormState>();
  String brand = '';
  String model = '';
  String color = '';
  String plate = '';

  void _showAddVehicleDialog() {
    brand = '';
    model = '';
    color = '';
    plate = '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Dodaj pojazd'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Marka'),
                  validator: (value) => value == null || value.isEmpty ? 'Wpisz markę' : null,
                  onSaved: (value) => brand = value!.trim(),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Model'),
                  validator: (value) => value == null || value.isEmpty ? 'Wpisz model' : null,
                  onSaved: (value) => model = value!.trim(),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Kolor'),
                  validator: (value) => value == null || value.isEmpty ? 'Wpisz kolor' : null,
                  onSaved: (value) => color = value!.trim(),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Numer rejestracyjny'),
                  validator: (value) => value == null || value.isEmpty ? 'Wpisz numer rejestracyjny' : null,
                  onSaved: (value) => plate = value!.trim(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();

                setState(() {
                  vehicles.add({
                    'brand': brand,
                    'model': model,
                    'color': color,
                    'plate': plate,
                  });
                });

                // TODO: Wyślij dane do backendu np. Firebase
                // await Backend.addVehicle(userId, brand, model, color, plate);

                Navigator.pop(context);
              }
            },
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Moje pojazdy"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Dodaj pojazd',
            onPressed: _showAddVehicleDialog,
          ),
        ],
      ),
      body: vehicles.isEmpty
          ? const Center(child: Text('Brak pojazdów. Dodaj nowy pojazd.'))
          : ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (_, index) {
                final vehicle = vehicles[index];
                return ListTile(
                  leading: const Icon(Icons.directions_car),
                  title: Text('${vehicle['brand']} ${vehicle['model']}'),
                  subtitle: Text('Kolor: ${vehicle['color']}\nRejestracja: ${vehicle['plate']}'),
                  isThreeLine: true,
                );
              },
            ),
    );
  }
}
