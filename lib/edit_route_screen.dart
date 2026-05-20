import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';
import '../services/cached_geocoding_service.dart';
import '../services/notification_service.dart';

class EditRouteScreen extends StatefulWidget {
  final RouteModel route;
  const EditRouteScreen({super.key, required this.route});

  @override
  State<EditRouteScreen> createState() => _EditRouteScreenState();
}

class _EditRouteScreenState extends State<EditRouteScreen> {
  late TextEditingController _startAddressCtrl;
  late TextEditingController _endAddressCtrl;
  late TextEditingController _dateCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _seatsCtrl;
  late TextEditingController _costCtrl;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _seats = 4;
  double _cost = 0.0;

  final CachedGeocodingService _geocoding = CachedGeocodingService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _startAddressCtrl = TextEditingController(text: widget.route.startAddress);
    _endAddressCtrl = TextEditingController(text: widget.route.endAddress);
    _selectedDate = widget.route.date;
    _selectedTime = TimeOfDay.fromDateTime(widget.route.date);
    _seats = widget.route.seats;
    _cost = widget.route.totalCost;
    _dateCtrl = TextEditingController(
      text: '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}',
    );
    _timeCtrl = TextEditingController(); // puste na razie
    _seatsCtrl = TextEditingController(text: _seats.toString());
    _costCtrl = TextEditingController(text: _cost.toString());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timeCtrl.text = _selectedTime!.format(context);
  }

  @override
  void dispose() {
    _startAddressCtrl.dispose();
    _endAddressCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _seatsCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    Map<String, dynamic> changes = {};

    if (_startAddressCtrl.text.trim() != widget.route.startAddress) {
      changes['startAddress'] = _startAddressCtrl.text.trim();
      final coords = await _geocoding.addressToCoordinates(_startAddressCtrl.text.trim());
      if (coords != null) {
        changes['start'] = {'lat': coords.latitude, 'lng': coords.longitude};
      }
    }

    if (_endAddressCtrl.text.trim() != widget.route.endAddress) {
      changes['endAddress'] = _endAddressCtrl.text.trim();
      final coords = await _geocoding.addressToCoordinates(_endAddressCtrl.text.trim());
      if (coords != null) {
        changes['end'] = {'lat': coords.latitude, 'lng': coords.longitude};
      }
    }

    final newDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    if (newDateTime != widget.route.date) {
      changes['date'] = Timestamp.fromDate(newDateTime);
    }

    if (_seats != widget.route.seats) {
      changes['seats'] = _seats;
    }

    if (_cost != widget.route.totalCost) {
      changes['totalCost'] = _cost;
    }

    if (changes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brak zmian do zapisania')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('routes')
        .doc(widget.route.id)
        .update({
      ...changes,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _notificationService.notifyPassengersAboutRouteChange(
      widget.route.id,
      changes,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trasa zaktualizowana. Powiadomienia wysłane.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edytuj trasę'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _startAddressCtrl,
              decoration: const InputDecoration(
                labelText: 'Adres startowy',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on, color: Colors.green),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _endAddressCtrl,
              decoration: const InputDecoration(
                labelText: 'Adres końcowy',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag, color: Colors.red),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dateCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Data odjazdu',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate!,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                    _dateCtrl.text = '${date.day}.${date.month}.${date.year}';
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _timeCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Godzina odjazdu',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.access_time),
              ),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime!,
                );
                if (time != null) {
                  setState(() {
                    _selectedTime = time;
                    _timeCtrl.text = time.format(context);
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _seatsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Liczba miejsc',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people),
              ),
              onChanged: (val) => _seats = int.tryParse(val) ?? 4,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _costCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Koszt całkowity (PLN)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              onChanged: (val) => _cost = double.tryParse(val) ?? 0.0,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save),
              label: const Text('Zapisz zmiany i powiadom pasażerów'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}