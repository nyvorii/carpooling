import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'booking_model.g.dart';

@HiveType(typeId: 2)
class BookingModel {
  @HiveField(0)
  String id;

  @HiveField(1)
  String routeId;

  @HiveField(2)
  String passengerId;

  @HiveField(3)
  String passengerName;

  @HiveField(4)
  String passengerEmail;

  @HiveField(5)
  String status; // 'confirmed', 'cancelled', 'pending'

  @HiveField(6)
  double costShare;

  @HiveField(7)
  int seatsBooked;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  BookingModel({
    required this.id,
    required this.routeId,
    required this.passengerId,
    required this.passengerName,
    required this.passengerEmail,
    this.status = 'confirmed',
    required this.costShare,
    this.seatsBooked = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      routeId: data['routeId'] ?? '',
      passengerId: data['passengerId'] ?? '',
      passengerName: data['passengerName'] ?? '',
      passengerEmail: data['passengerEmail'] ?? '',
      status: data['status'] ?? 'confirmed',
      costShare: (data['costShare'] ?? 0.0).toDouble(),
      seatsBooked: data['seatsBooked'] ?? 1,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'routeId': routeId,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'passengerEmail': passengerEmail,
      'status': status,
      'costShare': costShare,
      'seatsBooked': seatsBooked,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}