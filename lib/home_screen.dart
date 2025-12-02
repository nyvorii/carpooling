import 'package:flutter/material.dart';
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
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  // Funkcja logowania
  Future<void> _loginWithGoogle() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;

      // 1️ Próba szybkiego logowania z cache
      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();

      // 2️ Jeśli brak konta w cache — otwórz UI wyboru konta
      googleUser ??= await _googleSignIn.signIn();
      if (googleUser == null) return; // użytkownik anulował

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await auth.signInWithCredential(credential);
      final user = auth.currentUser;
      if (user == null) return;

      // 3️ Zapis do Firestore w tle (minimalny)
      _saveUserToFirestore(user);

      // 4️ Przejście do MenuScreen od razu
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MenuScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Błąd logowania: $e")));
      }
    }
  }

  // Zapis profilu do Firestore w tle
  Future<void> _saveUserToFirestore(User user) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

    await userDoc.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _startLoginFlow() {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    // Mikrotask → UI od razu pokaże loader
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
            const Icon(Icons.directions_car, color: Colors.white, size: 120),
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
