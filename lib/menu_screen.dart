import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

// Importujemy nasz nowy plik (gdzie jest wszystko dla admina)
import 'admin_menu_screen.dart';

// Importy dla pasażera/kierowcy
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
  
  // Zmienna lokalna do sterowania trybem (tylko dla kierowcy)
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

        // === 1. JEŚLI ADMIN (0) -> IDŹ DO PLIKU ADMINA ===
        if (role == 0) {
          return const AdminMenuScreen();
        }

        // === 2. LOGIKA DLA KIEROWCY (2) I PASAŻERA (1) ===
        
        // Sprawdzamy, czy użytkownik ma uprawnienia kierowcy (Rola 2)
        final bool canBeDriver = (role == 2);

        // Decyzja, jaki interfejs pokazać:
        // - Jeśli nie jest kierowcą (role 1) -> zawsze false (pasażer)
        // - Jeśli jest kierowcą (role 2) -> zależy od przełącznika _isDriverMode
        final bool showDriverInterface = canBeDriver && _isDriverMode;
        
        // Listy ekranów
        final passengerScreens = <Widget>[
          const MapScreen(),
          const BookScreen(),
          const ProfileScreen(),
        ];

        final driverScreens = <Widget>[
          const MapScreen(),
          const DriverBookingsScreen(),
          const ProfileScreen(),
        ];

        final currentScreens = showDriverInterface ? driverScreens : passengerScreens;

        // Zabezpieczenie indeksu przy przełączaniu
        if (_currentIndex >= currentScreens.length) _currentIndex = 0;

        // Ustawienia wyglądu (kolor i tytuł)
        final themeColor = showDriverInterface ? Colors.green[700]! : Colors.blueAccent;
        final title = showDriverInterface ? 'PANEL KIEROWCY' : 'PANEL PASAŻERA';

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            centerTitle: true,
            backgroundColor: themeColor,
            foregroundColor: Colors.white,
            actions: [
              // === PRZEŁĄCZNIK TYLKO DLA ROLI 2 ===
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
                          _currentIndex = 0; // Resetujemy zakładkę, żeby nie było błędu
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