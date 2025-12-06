import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vehicle_service.dart';

class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  final _formKey = GlobalKey<FormState>();

  String brand = '';
  String model = '';
  String color = '';
  String plate = '';
  File? pickedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        pickedImage = File(image.path);
      });
    }
  }

  void _showVehicleDialog({String? vehicleId, Map<String, dynamic>? vehicleData}) {
    if (vehicleData != null) {
      brand = vehicleData['brand'] ?? '';
      model = vehicleData['model'] ?? '';
      color = vehicleData['color'] ?? '';
      plate = vehicleData['plate'] ?? '';
      pickedImage = null;
    } else {
      brand = '';
      model = '';
      color = '';
      plate = '';
      pickedImage = null;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(vehicleId == null ? 'Dodaj pojazd' : 'Edytuj pojazd'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: brand,
                  decoration: const InputDecoration(labelText: 'Marka'),
                  validator: (value) => value == null || value.isEmpty ? 'Wpisz markę' : null,
                  onSaved: (value) => brand = value!.trim(),
                ),
                TextFormField(
                  initialValue: model,
                  decoration: const InputDecoration(labelText: 'Model'),
                  validator: (value) => value == null || value.isEmpty ? 'Wpisz model' : null,
                  onSaved: (value) => model = value!.trim(),
                ),
                TextFormField(
                  initialValue: color,
                  decoration: const InputDecoration(labelText: 'Kolor'),
                  validator: (value) => value == null || value.isEmpty ? 'Wpisz kolor' : null,
                  onSaved: (value) => color = value!.trim(),
                ),
                TextFormField(
                  initialValue: plate,
                  decoration: const InputDecoration(labelText: 'Numer rejestracyjny'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Wpisz numer';
                    final reg = RegExp(r'^[A-Z0-9]{1,3} [A-Z0-9]{1,4}$', caseSensitive: false);
                    if (!reg.hasMatch(value)) return 'Nieprawidłowy format tablicy';
                    return null;
                  },
                  onSaved: (value) => plate = value!.trim(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo),
                      label: const Text('Wybierz zdjęcie'),
                    ),
                    const SizedBox(width: 10),
                    if (pickedImage != null)
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: Image.file(pickedImage!, fit: BoxFit.cover),
                      ),
                  ],
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
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();

                try {
                  if (vehicleId == null) {
                    await VehicleService.addVehicle(
                      brand: brand,
                      model: model,
                      color: color,
                      plate: plate,
                      imageFile: pickedImage,
                    );
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pojazd dodany')),
                    );
                  } else {
                    await VehicleService.updateVehicle(
                      vehicleId,
                      brand: brand,
                      model: model,
                      color: color,
                      plate: plate,
                      imageFile: pickedImage,
                    );
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pojazd zaktualizowany')),
                    );
                  }
                  Navigator.pop(context);
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Błąd: $e')));
                }
              }
            },
            child: Text(vehicleId == null ? 'Dodaj' : 'Zapisz'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVehicle(String vehicleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Potwierdź'),
        content: const Text('Czy na pewno chcesz usunąć pojazd?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Nie')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Tak')),
        ],
      ),
    );

    if (confirmed == true) {
      await VehicleService.deleteVehicle(vehicleId);
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pojazd usunięty')));
    }
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
            onPressed: () => _showVehicleDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: VehicleService.getVehiclesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Brak pojazdów. Dodaj nowy pojazd.'));
          }

          final vehicles = snapshot.data!.docs;

          return ListView.builder(
            itemCount: vehicles.length,
            itemBuilder: (_, index) {
              final doc = vehicles[index];
              final data = doc.data();

              Widget leadingWidget;
              if (data['imageBase64'] != null) {
                final bytes = base64Decode(data['imageBase64']);
                leadingWidget = GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        child: InteractiveViewer(
                          child: Image.memory(bytes, fit: BoxFit.contain),
                        ),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: Image.memory(bytes, fit: BoxFit.cover),
                  ),
                );
              } else {
                leadingWidget = const Icon(Icons.directions_car);
              }

              return ListTile(
                leading: leadingWidget,
                title: Text('${data['brand']} ${data['model']}'),
                subtitle: Text('Kolor: ${data['color']}\nRejestracja: ${data['plate']}'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showVehicleDialog(vehicleId: doc.id, vehicleData: data),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteVehicle(doc.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
