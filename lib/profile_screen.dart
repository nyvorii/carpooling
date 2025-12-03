import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  String userName = "";
  String userSurname = "";
  String? photoUrl;
  String? customPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final String? fullName = doc.data()?['displayName'];

      setState(() {
        userName = fullName?.split(' ').first ?? '';
        userSurname = fullName?.split(' ').skip(1).join(' ') ?? '';
        photoUrl = user.photoURL;
        customPhotoUrl = doc.data()?['customPhotoUrl'];
      });
    }
  }

  void _updateProfile(File? newImage, String newName, String newSurname, String? newPhotoUrl) {
    setState(() {
      imageFile = newImage;
      userName = newName;
      userSurname = newSurname;
      photoUrl = newPhotoUrl;
    });
  }

  Widget buildProfilePhoto({
    File? imageFile,
    String? customBase64,
    String? photoUrl,
    double size = 120,
  }) {
    if (imageFile != null) {
      return ClipOval(
        child: Image.file(imageFile, width: size, height: size, fit: BoxFit.cover),
      );
    }

    if (customBase64 != null && customBase64.isNotEmpty) {
      try {
        return ClipOval(
          child: Image.memory(base64Decode(customBase64), width: size, height: size, fit: BoxFit.cover),
        );
      } catch (e) {
        print("Błąd dekodowania Base64: $e");
      }
    }

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(photoUrl, width: size, height: size, fit: BoxFit.cover),
      );
    }

    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: Colors.blueAccent,
        child: const Icon(Icons.person, size: 60, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: <Widget>[
        Center(
          child: buildProfilePhoto(
            imageFile: imageFile,
            customBase64: customPhotoUrl,
            photoUrl: photoUrl,
            size: 120,
          ),
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
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RidesHistoryPassengerScreen()));
              },
              child: _buildStatItem('Przejazdy', '102'),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RidesHistoryDriverScreen()));
              },
              child: _buildStatItem('Jako kierowca', '35'),
            ),
            _buildStatItem('Ocena', '4.9 ★'),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(indent: 16, endIndent: 16),
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
              _updateProfile(result['image'], result['name'], result['surname'], result['photoUrl']);
            }
          },
        ),
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
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text('Wyloguj', style: TextStyle(color: Colors.redAccent)),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
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
