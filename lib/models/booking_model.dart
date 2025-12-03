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
    String? id,
    String? routeId,
    String? passengerId,
    String? passengerName,
    String? passengerEmail,
    String? status,
    double? costShare,
    int? seatsBooked,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? '',
        routeId = routeId ?? '',
        passengerId = passengerId ?? '',
        passengerName = passengerName ?? '',
        passengerEmail = passengerEmail ?? '',
        status = status ?? 'confirmed',
        costShare = costShare ?? 0.0,
        seatsBooked = seatsBooked ?? 1,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory BookingModel.empty() {
    return BookingModel(
      id: '',
      routeId: '',
      passengerId: '',
      passengerName: '',
      passengerEmail: '',
      status: 'confirmed',
      costShare: 0.0,
      seatsBooked: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  factory BookingModel.create({
    required String id,
    required String routeId,
    required String passengerId,
    required String passengerName,
    required String passengerEmail,
    String status = 'confirmed',
    required double costShare,
    int seatsBooked = 1,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return BookingModel(
      id: id,
      routeId: routeId,
      passengerId: passengerId,
      passengerName: passengerName,
      passengerEmail: passengerEmail,
      status: status,
      costShare: costShare,
      seatsBooked: seatsBooked,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return BookingModel.create(
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