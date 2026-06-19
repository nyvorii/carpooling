import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String routeId;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? changes;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.routeId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.changes,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'routeId': routeId,
      'title': title,
      'body': body,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'changes': changes ?? {},
    };
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] as String,
      routeId: data['routeId'] as String,
      title: data['title'] as String,
      body: data['body'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      changes: data['changes'] as Map<String, dynamic>?,
    );
  }
}