import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pomoc i wsparcie")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: const [
            Text(
              "Infolinia wsparcia:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),
            Text(
              "📞 696 969 696",
              style: TextStyle(fontSize: 24, color: Colors.blueAccent),
            ),
          ],
        ),
      ),
    );
  }
}
