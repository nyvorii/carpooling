import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'providers/user_mode_provider.dart';
import 'profile_screen.dart';
import 'book_screen.dart';
import 'map_screen.dart';
import 'driver_bookings_screen.dart';
import 'available_routes_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _currentIndex = 0;

  Future<int> _getUserRole() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['role'] ?? 1;
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = Provider.of<User?>(context);
    final userName = firebaseUser?.displayName ?? 'Użytkownik';
    final userEmail = firebaseUser?.email ?? '';

    return FutureBuilder<int>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data!;
        final canBeDriver = role == 0 || role == 2; // admin lub kierowca

        final userModeProvider = Provider.of<UserModeProvider>(context);
        final isDriver = canBeDriver && userModeProvider.isDriverMode;

        // Lista ekranów pasażera
        final passengerScreens = <Widget>[
          const MapScreen(),
          if (role != 1) const AvailableRoutesScreen(), // ukryj dla zwykłego usera
          const BookScreen(),
          const ProfileScreen(),
        ];

        // Lista ekranów kierowcy
        final driverScreens = const [
          MapScreen(),
          DriverBookingsScreen(),
          ProfileScreen(),
        ];

        final currentScreens = isDriver ? driverScreens : passengerScreens;

        if (_currentIndex >= currentScreens.length) {
          _currentIndex = 0;
        }

        final themeColor = isDriver ? Colors.green[700]! : Colors.blueAccent;

        return Scaffold(
          appBar: AppBar(
            title: Text(isDriver ? 'KIEROWCA' : 'PASAŻER'),
            centerTitle: true,
            backgroundColor: themeColor,
            foregroundColor: Colors.white,
            actions: [
              if (canBeDriver)
                Row(
                  children: [
                    const Icon(Icons.person, size: 20),
                    Switch(
                      value: isDriver,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.lightGreenAccent,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.blue[200],
                      onChanged: (value) {
                        userModeProvider.setDriverMode(value);
                        setState(() {
                          _currentIndex = 0;
                        });
                      },
                    ),
                    const Icon(Icons.drive_eta, size: 20),
                    const SizedBox(width: 12),
                  ],
                ),
            ],
          ),
          body: currentScreens[_currentIndex],
          drawer: _buildDrawer(userName, userEmail, themeColor),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: themeColor,
            unselectedItemColor: Colors.grey,
            items: isDriver
                ? _buildDriverNavItems()
                : _buildPassengerNavItems(role),
          ),
        );
      },
    );
  }

  List<BottomNavigationBarItem> _buildPassengerNavItems(int role) {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
      if (role != 1)
        const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Szukaj'), // dodawanie tras
      const BottomNavigationBarItem(icon: Icon(Icons.confirmation_number), label: 'Rezerwacje'),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
    ];
    return items;
  }

  List<BottomNavigationBarItem> _buildDriverNavItems() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
      BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pasażerowie'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
    ];
  }

  Widget _buildDrawer(String userName, String userEmail, Color color) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(userName),
            accountEmail: Text(userEmail),
            decoration: BoxDecoration(color: color),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Wyloguj'),
            onTap: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
    );
  }
}
