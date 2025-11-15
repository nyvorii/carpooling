import 'dart:io';
import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';
import 'rides_history_passenger.dart';
import 'rides_history_driver.dart';
import 'my_vehicles_screen.dart';
import 'settings_screen.dart';
import 'support_screen.dart';
import 'home_screen.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? imageFile;
  String userName = "Jaro";
  String userSurname = "Krul";

  void _updateProfile(File? newImage, String newName, String newSurname) {
    setState(() {
      imageFile = newImage;
      userName = newName;
      userSurname = newSurname;

      // TUTAJ backend: odświeżenie danych profilu
      // await Backend.getUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: <Widget>[
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.blueAccent,
          backgroundImage: imageFile != null ? FileImage(imageFile!) : null,
          child: imageFile == null
              ? const Icon(Icons.person, size: 60, color: Colors.white)
              : null,
        ),

        const SizedBox(height: 12),

        Center(
          child: Text(
            '$userName $userSurname',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RidesHistoryPassengerScreen(),
                  ),
                );
              },
              child: _buildStatItem('Przejazdy', '102'),
            ),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RidesHistoryDriverScreen(),
                  ),
                );
              },
              child: _buildStatItem('Jako kierowca', '35'),
            ),

            _buildStatItem('Ocena', '4.9 ★'),
          ],
        ),

        const SizedBox(height: 24),
        const Divider(indent: 16, endIndent: 16),

        // Edytuj profil
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Edytuj profil'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditProfileScreen(
                  currentImage: imageFile,
                  currentName: userName,
                  currentSurname: userSurname,
                ),
              ),
            );

            if (result != null) {
              _updateProfile(result['image'], result['name'], result['surname']);
            }
          },
        ),

        // Moje pojazdy
        ListTile(
          leading: const Icon(Icons.directions_car_outlined),
          title: const Text('Moje pojazdy'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyVehiclesScreen()),
            );
          },
        ),

        // Ustawienia
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('Ustawienia'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),

        // Pomoc i wsparcie
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Pomoc i wsparcie'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupportScreen()),
            );
          },
        ),

        const Divider(indent: 16, endIndent: 16),

        // Wyloguj
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text('Wyloguj', style: TextStyle(color: Colors.redAccent)),
          onTap: () {
            // TUTAJ backend: wylogowanie
            // await Backend.logout();

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
