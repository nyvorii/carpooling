import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminApplicationsScreen extends StatelessWidget {
  const AdminApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('driver_applications')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Brak zgłoszeń na kierowcę."));
        }

        final applications = snapshot.data!.docs;

        return ListView.builder(
          itemCount: applications.length,
          itemBuilder: (context, index) {
            final doc = applications[index];
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                title: Text("${data['firstName']} ${data['lastName']}"),
                subtitle: Text(data['email'] ?? ''),
                trailing: Text(
                  status,
                  style: TextStyle(
                    color: status == 'pending'
                        ? Colors.orange
                        : (status == 'accepted' ? Colors.green : Colors.red),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  _showApplicationDetails(context, doc.id, data);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showApplicationDetails(
      BuildContext context, String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${data['firstName']} ${data['lastName']}",
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text("Email: ${data['email']}"),
                const SizedBox(height: 8),
                Text("Kolor samochodu: ${data['carColor']}"),
                Text("Rejestracja: ${data['carPlate']}"),
                const SizedBox(height: 12),
                _buildImagePreview("Samochód", data['carPhoto']),
                _buildImagePreview("Dowód / Paszport", data['idDocumentPhoto']),
                _buildImagePreview("Licencja taksówkarska", data['taxiLicensePhoto']),
                _buildImagePreview("Prawo jazdy", data['driverLicensePhoto']),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () async {
                          await _acceptApplication(docId, data['email']);
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text("Akceptuj"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () {
                          _showRejectDialog(context, docId);
                        },
                        child: const Text("Odrzuć"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePreview(String label, String? base64Image) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        base64Image != null && base64Image.isNotEmpty
            ? Image.memory(
                base64Decode(base64Image),
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            : Container(
                height: 150,
                color: Colors.grey[300],
                child: const Center(child: Icon(Icons.image, size: 50)),
              ),
      ],
    );
  }

  Future<void> _acceptApplication(String docId, String userEmail) async {
    final appDoc = FirebaseFirestore.instance
        .collection('driver_applications')
        .doc(docId);

    // Aktualizacja statusu zgłoszenia
    await appDoc.update({'status': 'accepted'});

    // Aktualizacja roli użytkownika w kolekcji users
    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: userEmail)
        .get();

    if (userQuery.docs.isNotEmpty) {
      final userDoc = userQuery.docs.first;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userDoc.id)
          .update({'role': 2});
    }
  }

  void _showRejectDialog(BuildContext context, String docId) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Podaj powód odrzucenia"),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(hintText: "Powód odrzucenia"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Anuluj"),
            ),
            TextButton(
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) return;

                await FirebaseFirestore.instance
                    .collection('driver_applications')
                    .doc(docId)
                    .update({
                  'status': 'rejected',
                  'rejectionReason': reasonController.text.trim(),
                });

                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text("Odrzuć", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}