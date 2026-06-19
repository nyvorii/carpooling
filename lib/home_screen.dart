import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:carpooling/services/auth_service.dart';
import 'package:carpooling/services/user_service.dart';
import 'menu_screen.dart';

class HomeScreen extends StatefulWidget {
  final AuthService authService;
  final UserService userService;

  HomeScreen({super.key, AuthService? authService, UserService? userService})
      : authService = authService ?? GoogleAuthService(),
        userService = userService ?? FirebaseUserService();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  Future<void> _loginWithGoogle() async {
    try {
      final user = await widget.authService.signInWithGoogle();
      if (user == null) return;

      await widget.userService.saveUserToFirestore(user);

      final data = await widget.userService.getUserDoc(user.uid);
      if (kIsWeb) {
        if (data == null || data['role'] != 0) {
          await widget.authService.signOutGoogle();

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Dostęp tylko dla administratora"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      final isBlocked = data?['isBlocked'] ?? false;

      if (isBlocked) {
        await widget.authService.signOutGoogle();

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

  // Zapis i migracja roli przeniesione do UserService.

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
