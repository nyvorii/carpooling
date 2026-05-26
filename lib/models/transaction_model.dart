import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String type;
  final double amount;
  final String title;
  final DateTime createdAt;
  final String routeId;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.title,
    required this.createdAt,
    required this.routeId,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      title: data['title'] ?? '',
      routeId: data['routeId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}