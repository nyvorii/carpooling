import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String routeId;
  final String reviewerId;
  final String reviewedUserId;
  final int rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.routeId,
    required this.reviewerId,
    required this.reviewedUserId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'routeId': routeId,
      'reviewerId': reviewerId,
      'reviewedUserId': reviewedUserId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
    };
  }

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      routeId: data['routeId'],
      reviewerId: data['reviewerId'],
      reviewedUserId: data['reviewedUserId'],
      rating: data['rating'],
      comment: data['comment'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

}