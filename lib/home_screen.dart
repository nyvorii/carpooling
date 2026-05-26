import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  final GoogleSignIn _googleSignIn =
      GoogleSignIn(scopes: ['email', 'profile']);

  Future<void> _loginWithGoogle() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;

      UserCredential userCredential;

      if (kIsWeb) {
        userCredential =
          await auth.signInWithPopup(GoogleAuthProvider());
      } else {
        GoogleSignInAccount? googleUser =
            await _googleSignIn.signInSilently();

        googleUser ??= await _googleSignIn.signIn();
        if (googleUser == null) return;

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential =
          await auth.signInWithCredential(credential);
      }

      final user = auth.currentUser;
      if (user == null) return;

      await _saveUserToFirestore(user);

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();
      if (kIsWeb) {
        if (data == null || data['role'] != 0) {
          await auth.signOut();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Dostęp tylko dla administratora"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
      await _saveUserToFirestore(user);

      final isBlocked = doc.data()?['isBlocked'] ?? false;

      if (isBlocked) {
        await FirebaseAuth.instance.signOut();
        if(!kIsWeb){
          await _googleSignIn.signOut();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Twoje konto zostało zablokowane przez administratora."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MenuScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Błąd logowania: $e")),
        );
      }
    }
  }

  /// 🔐 ZAPIS + MIGRACJA ROLI
  Future<void> _saveUserToFirestore(User user) async {
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      // 🆕 NOWY USER
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'contactEmail': user.email,
        'contactPhone': '',
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'isBlocked': false,
        'role': 1, // 👤 zwykły użytkownik
        'createdAt': FieldValue.serverTimestamp(),
        'balance': 0.0,
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } else {
      final data = snapshot.data()!;

      // 🔁 STARY USER – brak role → migracja
      if (!data.containsKey('role')) {
        await userDoc.update({
          'role': 1,
        });
      }
      if (!data.containsKey('contactEmail')) {
        await userDoc.update({
          'contactEmail': data['email'],
        });
      }
      if (!data.containsKey('isBlocked')) {
        await userDoc.update({
          'isBlocked': false,
        });
      }
      if (!data.containsKey('contactPhone')) {
        await userDoc.update({
          'contactPhone': '',
        });
      }
            if (!data.containsKey('balance')) {
        await userDoc.update({
          'balance': 0.0,
        });
      }


      // aktualizacja logowania
      await userDoc.update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
  }

  void _startLoginFlow() {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    Future.microtask(() async {
      await _loginWithGoogle();
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_car,
                color: Colors.white, size: 120),
            const SizedBox(height: 20),
            const Text(
              'Carpooling App',
              style: TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : ElevatedButton.icon(
                    icon: const Icon(Icons.login),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    label: const Text(
                      'Zaloguj przez Google',
                      style: TextStyle(fontSize: 18),
                    ),
                    onPressed: _startLoginFlow,
                  ),
          ],
        ),
      ),
    );
  }
}
