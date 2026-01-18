import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Pamiętaj tylko o imporcie profilu, bo on jest wspólny
import 'profile_screen.dart';

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  int _currentIndex = 0;

  // Lista ekranów zdefiniowanych w tym samym pliku (poniżej)
  final List<Widget> _screens = const [
    AdminUsersScreen(),        // Klasa zdefiniowana na dole tego pliku
    AdminApplicationsScreen(), // Klasa zdefiniowana na dole tego pliku
    ProfileScreen(),           // Wspólny profil z importu
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = Provider.of<User?>(context);
    final userName = firebaseUser?.displayName ?? 'Admin';
    final userEmail = firebaseUser?.email ?? 'admin@app.com';
    final themeColor = Colors.red[900]!; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('PANEL ADMINA'),
        centerTitle: true,
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      drawer: _buildDrawer(userName, userEmail, themeColor),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: themeColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts), 
            label: 'Użytkownicy'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment), 
            label: 'Zgłoszenia'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person), 
            label: 'Profil'
          ),
        ],
      ),
    );
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

// ==================================================================
// TUTAJ SĄ EKRANY WEWNĘTRZNE ADMINA (W TYM SAMYM PLIKU)
// ==================================================================

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Przykładowy kod pobierania użytkowników z Firestore
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Brak użytkowników."));
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            final email = userData['email'] ?? 'Brak email';
            final role = userData['role'] ?? 1;

            return ListTile(
              leading: Icon(
                role == 0 ? Icons.admin_panel_settings : (role == 2 ? Icons.drive_eta : Icons.person),
                color: role == 0 ? Colors.red : (role == 2 ? Colors.green : Colors.blue),
              ),
              title: Text(email),
              subtitle: Text("Rola: $role"),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  // Tu dodasz logikę edycji użytkownika
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Edycja użytkownika: $email")),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class AdminApplicationsScreen extends StatelessWidget {
  const AdminApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder na listę zgłoszeń
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text("Lista zgłoszeń na kierowcę", style: TextStyle(fontSize: 18)),
          Text("(Tu podepniesz kolekcję 'driver_applications')"),
        ],
      ),
    );
  }
}