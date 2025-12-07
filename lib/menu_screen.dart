import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  final List<Widget> _passengerScreens = [
    const MapScreen(),
    const AvailableRoutesScreen(),
    const BookScreen(),
    const ProfileScreen(),
  ];

  final List<Widget> _driverScreens = [
    const MapScreen(),
    const DriverBookingsScreen(),
    const ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final userModeProvider = Provider.of<UserModeProvider>(context);
    final isDriver = userModeProvider.isDriverMode;

    final userName = user?.displayName ?? 'Użytkownik';
    final userEmail = user?.email ?? '';

    final currentScreens = isDriver ? _driverScreens : _passengerScreens;

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
          )
        ],
      ),
      body: currentScreens[_currentIndex],
      drawer: _buildDrawer(userName, userEmail, isDriver, themeColor),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: themeColor,
        unselectedItemColor: Colors.grey,
        items: isDriver ? _buildDriverNavItems() : _buildPassengerNavItems(),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildPassengerNavItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.map_outlined),
        activeIcon: Icon(Icons.map),
        label: 'Mapa',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.search),
        activeIcon: Icon(Icons.search_off),
        label: 'Szukaj',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.confirmation_number_outlined),
        activeIcon: Icon(Icons.confirmation_number),
        label: 'Rezerwacje',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profil',
      ),
    ];
  }

  List<BottomNavigationBarItem> _buildDriverNavItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.map_outlined),
        activeIcon: Icon(Icons.map),
        label: 'Mapa',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.people_outline),
        activeIcon: Icon(Icons.people),
        label: 'Pasażerowie',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profil',
      ),
    ];
  }

  Widget _buildDrawer(String userName, String userEmail, bool isDriver, Color color) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: TextStyle(fontSize: 20, color: color),
              ),
            ),
            decoration: BoxDecoration(
              color: color,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Ustawienia'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Wyloguj'),
            onTap: () {
              _signOut(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }
}