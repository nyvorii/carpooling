import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<DocumentSnapshot> _getUserStream() {
    final user = _auth.currentUser;
    return _firestore.collection('users').doc(user!.uid).snapshots();
  }

  Stream<QuerySnapshot> _getTransactionsStream() {
    final user = _auth.currentUser;
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: user!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfel'),
        backgroundColor: Colors.green[700],
      ),
      body: Column(
        children: [
          // 💰 BALANS
          StreamBuilder<DocumentSnapshot>(
            stream: _getUserStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                );
              }

              final data =
                  snapshot.data!.data() as Map<String, dynamic>?;

              final balance = data?['balance'] ?? 0;

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Twoje saldo',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${balance.toString()} PLN',
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Historia transakcji',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

       
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getTransactionsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Brak transakcji'),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data =
                        docs[index].data() as Map<String, dynamic>;

                    final type = data['type'] ?? '';
                    final amount = data['amount'] ?? 0;
                    final title = data['title'] ?? 'Transakcja';

                    Color color;
                    IconData icon;

                    switch (type) {
                      case 'payment':
                        color = Colors.red;
                        icon = Icons.remove_circle;
                        break;
                      case 'income':
                        color = Colors.green;
                        icon = Icons.add_circle;
                        break;
                      case 'refund':
                        color = Colors.orange;
                        icon = Icons.refresh;
                        break;
                      default:
                        color = Colors.blue;
                        icon = Icons.info;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: Icon(icon, color: color),
                        title: Text(title),
                        subtitle: Text(type),
                        trailing: Text(
                          '${amount.toString()} PLN',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}