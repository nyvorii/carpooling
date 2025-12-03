import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'latlng_adapter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'route_model.g.dart';

@HiveType(typeId: 0)
class RouteModel {
  @HiveField(0)
  String id;

  @HiveField(1)
  LatLng start;

  @HiveField(2)
  LatLng end;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  int seats;

  @HiveField(5)
  List<LatLng> routePoints;

  @HiveField(6)
  int bookedSeats;

  @HiveField(7)
  String driverId;

  @HiveField(8)
  String driverName;

  @HiveField(9)
  double totalCost;

  @HiveField(10)
  List<String> passengerIds;

  @HiveField(11)
  bool isActive;

  RouteModel({
    this.id = '',
    LatLng? start,
    LatLng? end,
    DateTime? date,
    this.seats = 4,
    this.routePoints = const [],
    this.bookedSeats = 0,
    this.driverId = '',
    this.driverName = 'Kierowca',
    this.totalCost = 0.0,
    this.passengerIds = const [],
    this.isActive = true,
  })  : start = start ?? const LatLng(0, 0),
        end = end ?? const LatLng(0, 0),
        date = date ?? DateTime.now();

  int get availableSeats => seats - bookedSeats;

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
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

  factory RouteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final startData = data['start'] as Map<String, dynamic>;
    final endData = data['end'] as Map<String, dynamic>;

    return RouteModel(
      id: doc.id,
      start: LatLng(startData['lat'] as double, startData['lng'] as double),
      end: LatLng(endData['lat'] as double, endData['lng'] as double),
      date: (data['date'] as Timestamp).toDate(),
      seats: data['seats'] as int,
      routePoints: (data['routePoints'] as List).map((point) =>
          LatLng(point['lat'] as double, point['lng'] as double)).toList(),
      bookedSeats: data['bookedSeats'] ?? 0,
      driverId: data['driverId'] ?? '',
      driverName: data['driverName'] ?? 'Kierowca',
      totalCost: (data['totalCost'] ?? 0.0).toDouble(),
      passengerIds: List<String>.from(data['passengerIds'] ?? []),
      isActive: data['isActive'] ?? true,
    );
  }
}