import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'admin_menu_screen.dart';
import 'profile_screen.dart';
import 'book_screen.dart';
import 'map_screen.dart';
import 'driver_bookings_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _currentIndex = 0;
  
  // Domyślnie włączony tryb kierowcy (jeśli rola na to pozwala)
  bool _isDriverMode = true; 

  Future<int> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 1; 
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data()?['role'] ?? 1;
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = Provider.of<User?>(context);

    return FutureBuilder<int>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final int role = snapshot.data ?? 1;

        // === 1. ADMIN ===
        if (role == 0) {
          return const AdminMenuScreen();
        }

        // === 2. KIEROWCA / PASAŻER ===
        final bool canBeDriver = (role == 2);
        
        // Interfejs kierowcy pokazujemy TYLKO gdy jest rola 2 ORAZ włączony suwak
        final bool showDriverInterface = canBeDriver && _isDriverMode;
        
        // --- ZMIANA: PRZEKAZUJEMY Parametr isDriverMode do MapScreen ---
        
        final passengerScreens = <Widget>[
          // Pasażer nie może dodawać tras -> isDriverMode: false
          const MapScreen(isDriverMode: false), 
          const BookScreen(),
          const ProfileScreen(),
        ];

        final driverScreens = <Widget>[
          // Kierowca może dodawać trasy -> isDriverMode: true
          const MapScreen(isDriverMode: true),
          const DriverBookingsScreen(),
          const ProfileScreen(),
        ];

        final currentScreens = showDriverInterface ? driverScreens : passengerScreens;

        if (_currentIndex >= currentScreens.length) _currentIndex = 0;

        final themeColor = showDriverInterface ? Colors.green[700]! : Colors.blueAccent;
        final title = showDriverInterface ? 'PANEL KIEROWCY' : 'PANEL PASAŻERA';

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            centerTitle: true,
            backgroundColor: themeColor,
            foregroundColor: Colors.white,
            actions: [
              if (canBeDriver) 
                Row(
                  children: [
                    Icon(
                      _isDriverMode ? Icons.drive_eta : Icons.person, 
                      color: Colors.white,
                      size: 20,
                    ),
                    Switch(
                      value: _isDriverMode,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.lightGreenAccent,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.blue[200],
                      onChanged: (val) {
                        setState(() {
                          _isDriverMode = val;
                          _currentIndex = 0; 
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
            ],
          ),
          body: currentScreens[_currentIndex],
          drawer: _buildDrawer(
             firebaseUser?.displayName ?? 'Użytkownik', 
             firebaseUser?.email ?? '', 
             themeColor
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: themeColor,
            unselectedItemColor: Colors.grey,
            items: showDriverInterface ? _buildDriverNavItems() : _buildPassengerNavItems(),
          ),
        );
      },
    );
  }

  List<BottomNavigationBarItem> _buildPassengerNavItems() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
      BottomNavigationBarItem(icon: Icon(Icons.confirmation_number), label: 'Rezerwacje'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
    ];
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