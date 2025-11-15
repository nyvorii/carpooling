import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ustawienia")),
      body: ListTile(
        leading: const Icon(Icons.delete_forever, color: Colors.red),
        title: const Text("Usuń konto", style: TextStyle(color: Colors.red)),
        onTap: () {
          // TUTAJ backend: usuń konto użytkownika
          // await Backend.deleteAccount();

          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Konto usunięte"),
              content: const Text("Twoje konto zostało usunięte (tymczasowo lokalnie)."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
