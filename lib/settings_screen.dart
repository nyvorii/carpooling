import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';



class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _deleteAccount(BuildContext context) async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;
    final user = auth.currentUser;

    if (user == null) return;

    final uid = user.uid;

    try {
      // WYMUSZENIE LOGOWANIA GOOGLE
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut(); // ⬅️ KLUCZOWE
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception("Logowanie anulowane");
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await user.reauthenticateWithCredential(credential);

      // USUWANIE DANYCH FIRESTORE

      // Trasy kierowcy
      final routes = await firestore
          .collection('routes')
          .where('driverId', isEqualTo: uid)
          .get();

      for (final route in routes.docs) {
        final routeId = route.id;

        final bookings = await firestore
            .collection('bookings')
            .where('routeId', isEqualTo: routeId)
            .get();

        for (final booking in bookings.docs) {
          await booking.reference.delete();
        }

        await route.reference.delete();
      }

      // Bookingi pasażera
      final passengerBookings = await firestore
          .collection('bookings')
          .where('passengerId', isEqualTo: uid)
          .get();

      for (final booking in passengerBookings.docs) {
        await booking.reference.delete();
      }

      // Dokument user
      await firestore.collection('users').doc(uid).delete();

      // USUNIĘCIE KONTA AUTH
      await user.delete();

      // WYLOGOWANIE + PRZEJŚCIE NA LOGIN
      await auth.signOut();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );


      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Błąd"),
            content: Text("Nie udało się usunąć konta:\n$e"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              )
            ],
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ustawienia")),
      body: ListTile(
        leading: const Icon(Icons.delete_forever, color: Colors.red),
        title: const Text(
          "Usuń konto",
          style: TextStyle(color: Colors.red),
        ),
        onTap: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Potwierdzenie"),
              content: const Text(
                "Czy na pewno chcesz usunąć konto? Tej operacji nie da się cofnąć.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Anuluj"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    "Usuń",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await _deleteAccount(context);
          }
        },
      ),
    );
  }
}
