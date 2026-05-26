import 'dart:convert'; // Do obsługi zdjęć base64
import 'dart:io';      // Do obsługi plików zdjęć
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_statistics_screen.dart';

// Importy ekranów pomocniczych
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'home_screen.dart'; 
import 'admin_applications_screen.dart';

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  int _currentIndex = 0;

  // Lista ekranów
final List<Widget> _screens = const [
  AdminUsersScreen(),
  AdminApplicationsScreen(),
  AdminStatisticsScreen(), 
  AdminProfileScreen(),
];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }
  bool isDesktop(BuildContext context) =>
    MediaQuery.of(context).size.width >= 900;

  bool isTablet(BuildContext context) =>
    MediaQuery.of(context).size.width >= 600 &&
    MediaQuery.of(context).size.width < 900;

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
        automaticallyImplyLeading: !isDesktop(context),
      ),

      drawer: isDesktop(context)
          ? null
          : _buildDrawer(userName, userEmail, themeColor),

      body: isDesktop(context)
          ? Row(
              children: [
                _buildSidebar(userName, userEmail, themeColor),
                Expanded(
                  child: Container(
                    color: Colors.grey[100],
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: _screens[_currentIndex],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : _screens[_currentIndex],

      bottomNavigationBar: isDesktop(context)
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: themeColor,
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.manage_accounts),
                  label: 'Użytkownicy',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.assignment),
                  label: 'Zgłoszenia',
                ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.bar_chart),
                   label: 'Statystyki', // <-- DODAJ
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profil',
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
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              // Opcjonalne przekierowanie, jeśli main.dart tego nie obsłuży
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(String userName, String userEmail, Color color) {
    return Container(
      width: 260,
      color: color,
      child: Column(
        children: [
          const SizedBox(height: 40),

          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: Text(
              userName.isNotEmpty ? userName[0] : "A",
              style: TextStyle(fontSize: 28, color: color),
            ),
          ),

          const SizedBox(height: 10),
          Text(userName, style: const TextStyle(color: Colors.white)),
          Text(userEmail,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),

          const SizedBox(height: 30),

          _sidebarItem(Icons.manage_accounts, "Użytkownicy", 0),
          _sidebarItem(Icons.assignment, "Zgłoszenia", 1),
          _sidebarItem(Icons.bar_chart, "Statystyki", 2), 
          _sidebarItem(Icons.person, "Profil", 3),

          const Spacer(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text("Wyloguj",
                style: TextStyle(color: Colors.white)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String title, int index) {
    final isSelected = _currentIndex == index;

    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      tileColor: isSelected ? Colors.black26 : null,
      onTap: () => _onTabTapped(index),
    );
  }
}

// ==================================================================
// EKRAN 1: ZARZĄDZANIE UŻYTKOWNIKAMI
// ==================================================================

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  String _getRoleName(int role) {
    switch (role) {
      case 0: return 'Admin';
      case 2: return 'Kierowca';
      default: return 'Pasażer';
    }
  }

  void _showEditRoleDialog(BuildContext context, String uid, int currentRole, String email,bool isBlocked) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edycja użytkownika:\n$email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Rola:", style: TextStyle(fontWeight: FontWeight.bold)),
              _buildRoleOption(context, uid, 1, 'Pasażer', currentRole),
              _buildRoleOption(context, uid, 2, 'Kierowca', currentRole),
              _buildRoleOption(context, uid, 0, 'Admin', currentRole),

              const SizedBox(height: 20),

              const Divider(),

              const Text("Status konta:", style: TextStyle(fontWeight: FontWeight.bold)),

              SwitchListTile(
                title: Text(isBlocked ? "Konto zablokowane" : "Konto aktywne"),
                value: isBlocked,
                onChanged: (value) async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .update({
                    'isBlocked': value,
                  });

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value ? "Konto zablokowane" : "Konto aktywowane",
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleOption(BuildContext context, String uid, int roleValue, String label, int currentRole) {
    return SimpleDialogOption(
      onPressed: () async {
        Navigator.pop(context); 
        if (roleValue == currentRole) return;

        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'role': roleValue,
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Zmieniono rolę na: $label')),
          );
        }
      },
      child: Row(
        children: [
          Icon(
            roleValue == currentRole ? Icons.radio_button_checked : Icons.radio_button_off,
            color: roleValue == currentRole ? Colors.blue : Colors.grey,
          ),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }

  void _deleteUser(BuildContext context, String uid, String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potwierdzenie'),
        content: Text('Czy na pewno chcesz usunąć profil użytkownika $email? \n(To nie usunie konta logowania, ale usunie dane z bazy).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('users').doc(uid).delete();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Użytkownik usunięty z bazy.')),
                );
              }
            },
            child: const Text('USUŃ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            final doc = users[index];
            final userData = doc.data() as Map<String, dynamic>;
            
            final isBlocked = userData['isBlocked'] ?? false;
            final email = userData['email'] ?? 'Brak email';
            final displayName = userData['displayName'] ?? 'Brak nazwy';
            final role = userData['role'] ?? 1;
            final uid = doc.id;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: Icon(
                  role == 0 ? Icons.admin_panel_settings : (role == 2 ? Icons.drive_eta : Icons.person),
                  color: role == 0 ? Colors.red : (role == 2 ? Colors.green : Colors.blue),
                ),
                title: Text(
                  displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "$email\nRola: ${_getRoleName(role)}",
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isBlocked ? Icons.block : Icons.check_circle,
                      color: isBlocked ? Colors.red : Colors.green,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => _showEditRoleDialog(
                        context, uid, role, email, isBlocked
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteUser(context, uid, email),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ==================================================================
// EKRAN 2: ZGŁOSZENIA
// ==================================================================

// przeniesione do admin_application_screen.dart

// ==================================================================
// EKRAN 3: PROFIL ADMINA (NOWA WERSJA)
// ==================================================================

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  File? imageFile;
  String userName = "Administrator";
  String userSurname = "";
  String? photoUrl;
  String? customPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Pobieranie danych Admina z bazy (żeby widział swoje zdjęcie/imię)
  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final data = doc.data();
        if (data != null) {
          final String? fullName = data['displayName'];
          setState(() {
            if (fullName != null && fullName.isNotEmpty) {
              userName = fullName.split(' ').first;
              userSurname = fullName.split(' ').skip(1).join(' ');
            }
            photoUrl = user.photoURL;
            customPhotoUrl = data['customPhotoUrl'];
          });
        }
      } catch (e) {
        debugPrint("Błąd ładowania profilu admina: $e");
      }
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

  // Funkcja budująca awatar
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
        debugPrint("Błąd base64: $e");
      }
    }
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: size,
              height: size,
              color: Colors.red[900],
              child: const Icon(Icons.admin_panel_settings,
                  size: 60, color: Colors.white),
            );
          },
        ),
      );
    }
    // Domyślna ikona admina
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: Colors.red[900], 
        child: const Icon(Icons.admin_panel_settings, size: 60, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: <Widget>[
        // --- ZDJĘCIE ---
        Center(
          child: buildProfilePhoto(
            imageFile: imageFile,
            customBase64: customPhotoUrl,
            photoUrl: photoUrl,
            size: 120,
          ),
        ),
        const SizedBox(height: 12),
        
        // --- IMIĘ I NAZWISKO ---
        Center(
          child: Text(
            '$userName $userSurname',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            "(Uprawnienia Administratora)",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 30),
        
        const Divider(indent: 16, endIndent: 16),

        // --- MENU ADMINA (OKROJONE) ---
        
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
          leading: const Icon(Icons.settings_outlined),
          title: const Text('Ustawienia aplikacji'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),

        const Divider(indent: 16, endIndent: 16),

        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text('Wyloguj', style: TextStyle(color: Colors.redAccent)),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            // Przekierowanie do HomeScreen (ekran startowy/logowania)
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            }
          },
        ),
      ],
    );
  }
}