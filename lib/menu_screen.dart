import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'wallet_screen.dart';
import 'admin_menu_screen.dart';
import 'profile_screen.dart';
import 'book_screen.dart';
import 'map_screen.dart';
import 'driver_bookings_screen.dart';
import 'available_routes_screen.dart';
import 'notifications_screen.dart';
import 'my_routes_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _currentIndex = 0;

  // Domyślnie włączony tryb kierowcy
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

        final bool showDriverInterface = canBeDriver && _isDriverMode;



        final passengerScreens = <Widget>[
          const MapScreen(isDriverMode: false),
          const AvailableRoutesScreen(),       
          const BookScreen(),                   
          const ProfileScreen(),                
        ];

        final driverScreens = <Widget>[
          const MapScreen(isDriverMode: true),  
          const DriverBookingsScreen(),       
          const ProfileScreen(),                
        ];

        final currentScreens = showDriverInterface ? driverScreens : passengerScreens;

       
        if (_currentIndex >= currentScreens.length) _currentIndex = 0;

        final themeColor = showDriverInterface ? Colors.green[700]! : Colors.blueAccent;
        final title = showDriverInterface ? 'KIEROWCA' : 'PASAŻER';

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            centerTitle: true,
            backgroundColor: themeColor,
            foregroundColor: Colors.white,
            actions: [

              // BALANCE
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(firebaseUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {

                  double balance = 0;

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    balance = (data['balance'] ?? 0).toDouble();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WalletScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "${balance.toStringAsFixed(2)} PLN",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

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
                      activeThumbColor: Colors.white,
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
                  ],
                ),
              // IKONKA POWIADOMIEŃ - POWIADOMIENIA TEŻ SĄ W ROZSUWANYM MENU PO LEWEJ STRONIE
              IconButton(
                icon: const Icon(Icons.notifications),
                tooltip: 'Powiadomienia',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: currentScreens[_currentIndex],
          drawer: _buildDrawer(
            firebaseUser?.displayName ?? 'Użytkownik',
            firebaseUser?.email ?? '',
            themeColor,
            canBeDriver,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: themeColor,
            unselectedItemColor: Colors.grey,
            // Wybór ikon w zależności od trybu
            items: showDriverInterface ? _buildDriverNavItems() : _buildPassengerNavItems(),
          ),
        );
      },
    );
  }

  // --- IKONY DLA PASAŻERA (4 sztuki) ---
  List<BottomNavigationBarItem> _buildPassengerNavItems() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
      BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Szukaj'),
      BottomNavigationBarItem(icon: Icon(Icons.confirmation_number), label: 'Rezerwacje'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
    ];
  }

  // --- IKONY DLA KIEROWCY (3 sztuki) ---
  List<BottomNavigationBarItem> _buildDriverNavItems() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
      BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pasażerowie'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
    ];
  }

  Widget _buildDrawer(String userName, String userEmail, Color color, bool isDriver) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(userName),
            accountEmail: Text(userEmail),
            decoration: BoxDecoration(color: color),
          ),
          // Moje trasy (tylko dla kierowcy)
          if (isDriver)
            ListTile(
              leading: const Icon(Icons.directions_car),
              title: const Text('Moje trasy'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyRoutesScreen()),
                );
              },
            ),
          // Powiadomienia (dla każdego)
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Powiadomienia'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
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