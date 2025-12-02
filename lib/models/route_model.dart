import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'latlng_adapter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'route_model.g.dart';

@HiveType(typeId: 0)
class RouteModel extends HiveObject {
  @HiveField(0)
  LatLng start;

  @HiveField(1)
  LatLng end;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  int seats;

  @HiveField(4)
  List<LatLng> routePoints;

  @HiveField(5)
  int bookedSeats;

  @HiveField(6)
  String driverId;

  @HiveField(7)
  String driverName;

  @HiveField(8)
  double totalCost;

  @HiveField(9)
  List<String> passengerIds;

  @HiveField(10)
  bool isActive;

  RouteModel({
    required this.start,
    required this.end,
    required this.date,
    required this.seats,
    required this.routePoints,
    this.bookedSeats = 0,
    this.driverId = 'default_driver',
    this.driverName = 'Kierowca',
    this.totalCost = 0.0,
    this.passengerIds = const [],
    this.isActive = true,
  });

  int get avaiableSeats => seats - bookedSeats;

  Map<String, dynamic> toFirestore() {
    return {
      'start': {'lat': start.latitude, 'lng': start.longitude},
      'end': {'lat': end.latitude, 'lng': end.longitude},
      'date': Timestamp.fromDate(date),
      'seats': seats,
      'bookedSeats': bookedSeats,
      'driverId': driverId,
      'driverName': driverName,
      'totalCost': totalCost,
      'passengerIds': passengerIds,
      'isActive': isActive,
      'routePoints': routePoints.map((point) =>
      {'lat': point.latitude, 'lng': point.longitude}).toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static RouteModel fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final startData = data['start'] as Map<String, dynamic>;
    final endData = data['end'] as Map<String, dynamic>;

    return RouteModel(
      start: LatLng(startData['lat'], startData['lng']),
      end: LatLng(endData['lat'], endData['lng']),
      date: (data['date'] as Timestamp).toDate(),
      seats: data['seats'],
      routePoints: (data['routePoints'] as List).map((point) =>
          LatLng(point['lat'], point['lng'])).toList(),
      bookedSeats: data['bookedSeats'] ?? 0,
      driverId: data['driverId'] ?? '',
      driverName: data['driverName'] ?? 'Kierowca',
      totalCost: (data['totalCost'] ?? 0.0).toDouble(),
      passengerIds: List<String>.from(data['passengerIds'] ?? []),
      isActive: data['isActive'] ?? true,
    );
  }
}