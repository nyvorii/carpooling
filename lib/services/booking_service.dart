import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/booking_model.dart';
import '../models/route_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Stream<List<RouteModel>> getAvailableRoutes() {
    return _firestore
        .collection('routes')
        .where('isActive', isEqualTo: true)
        .where('date', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => RouteModel.fromFirestore(doc)).toList());
  }

  Future<bool> bookSeat(RouteModel route, int seats, String passengerName, String passengerEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      if (route.avaiableSeats < seats) {
        return false;
      }

      final costShare = route.totalCost > 0
          ? (route.totalCost / route.seats) * seats
          : 0.0;

      final booking = BookingModel(
        id: '',
        routeId: route.key.toString(),
        passengerId: user.uid,
        passengerName: passengerName,
        passengerEmail: passengerEmail,
        costShare: costShare,
        seatsBooked: seats,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('bookings').add(booking.toFirestore());
      await docRef.update({'id': docRef.id});

      await _updateRouteAfterBooking(route, seats, user.uid);

      return true;
    } catch (e) {
      print('Błąd rezerwacji: $e');
      return false;
    }
  }

  Future<void> _updateRouteAfterBooking(RouteModel route, int seats, String passengerId) async {
    // Hive
    route.bookedSeats += seats;
    route.passengerIds.add(passengerId);
    await route.save();

    // Firestore
    try {
      await _firestore.collection('routes').doc(route.key.toString()).update({
        'bookedSeats': FieldValue.increment(seats),
        'passengerIds': FieldValue.arrayUnion([passengerId]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Błąd aktualizacji trasy w Firestore: $e');
    }
  }

  Future<bool> cancelBooking(String bookingId, RouteModel route) async {
    try {
      final bookingDoc = _firestore.collection('bookings').doc(bookingId);
      final bookingSnapshot = await bookingDoc.get();

      if (!bookingSnapshot.exists) return false;

      final bookingData = bookingSnapshot.data()!;
      final seatsBooked = bookingData['seatsBooked'] ?? 1;

      await bookingDoc.update({
        'status': 'cancelled',
        'updatedAt': Timestamp.now(),
      });

      await _updateRouteAfterCancellation(route, seatsBooked, bookingData['passengerId']);

      return true;
    } catch (e) {
      print('Błąd anulowania: $e');
      return false;
    }
  }

  Future<void> _updateRouteAfterCancellation(RouteModel route, int seats, String passengerId) async {
    // Hive
    route.bookedSeats = (route.bookedSeats - seats).clamp(0, route.seats);
    route.passengerIds.remove(passengerId);
    await route.save();

    // Firestore
    try {
      await _firestore.collection('routes').doc(route.key.toString()).update({
        'bookedSeats': FieldValue.increment(-seats),
        'passengerIds': FieldValue.arrayRemove([passengerId]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Błąd aktualizacji trasy w Firestore: $e');
    }
  }

  Stream<List<BookingModel>> getDriverBookings(String driverId) {
    return _firestore
        .collection('bookings')
        .where('status', isNotEqualTo: 'cancelled')
        .snapshots()
        .asyncMap((snapshot) async {
      List<BookingModel> bookings = [];

      for (var doc in snapshot.docs) {
        final booking = BookingModel.fromFirestore(doc);
        final routeDoc = await _firestore.collection('routes').doc(booking.routeId).get();
        if (routeDoc.exists && routeDoc.data()!['driverId'] == driverId) {
          bookings.add(booking);
        }
      }

      return bookings;
    });
  }

  Stream<List<BookingModel>> getPassengerBookings(String passengerId) {
    return _firestore
        .collection('bookings')
        .where('passengerId', isEqualTo: passengerId)
        .where('status', isNotEqualTo: 'cancelled')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList());
  }

  Future<void> initializeFCM() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _messaging.requestPermission();
        final token = await _messaging.getToken();
        print('FCM Token: $token');

        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Błąd inicjalizacji FCM: $e');
    }
  }
}