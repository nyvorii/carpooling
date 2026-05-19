import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive/hive.dart';
import '../models/booking_model.dart';
import '../models/route_model.dart';
import 'wallet_service.dart';
import '../models/review_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final WalletService _walletService = WalletService();

  Stream<List<RouteModel>> getAvailableRoutes() {
    return _firestore
        .collection('routes')
        .where('isActive', isEqualTo: true)
        .where('date', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => RouteModel.fromFirestore(doc)).toList());
  }

  Future<bool> bookSeat(
    RouteModel route,
    int seats,
    String passengerName,
    String passengerEmail,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      if (user.uid == route.driverId) {
         throw Exception('OWN_ROUTE_BOOKING');
      }

      if (route.availableSeats < seats) return false;

      final costShare =
          route.totalCost > 0
              ? (route.totalCost / route.seats) * seats
              : 0.0;

      final paymentSuccess = await _walletService.payForRide(
        passengerId: user.uid,
        driverId: route.driverId,
        amount: costShare,
        routeId: route.id,
      );

      if (!paymentSuccess) {
        throw Exception('INSUFFICIENT_FUNDS');
      }

      final bookingId =
          '${user.uid}_${DateTime.now().millisecondsSinceEpoch}';

      final booking = BookingModel(
        id: bookingId,
        routeId: route.id,
        passengerId: user.uid,
        passengerName: passengerName,
        passengerEmail: passengerEmail,
        costShare: costShare,
        seatsBooked: seats,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('bookings').doc(bookingId).set(
            booking.toFirestore(),
          );

      await _updateRouteAfterBooking(route, seats, user.uid);

      return true;
    } catch (e) {
      print('Błąd rezerwacji: $e');

      if (e.toString().contains('INSUFFICIENT_FUNDS')) {
        return false;
      }

      return false;
    }
  }

  Future<void> _updateRouteAfterBooking(RouteModel route, int seats, String passengerId) async {
    final updatedRoute = RouteModel(
      id: route.id,
      start: route.start,
      end: route.end,
      date: route.date,
      seats: route.seats,
      routePoints: route.routePoints,
      bookedSeats: route.bookedSeats + seats,
      driverId: route.driverId,
      driverName: route.driverName,
      totalCost: route.totalCost,
      passengerIds: [...route.passengerIds, passengerId],
      isActive: route.isActive,
    );

    // Hive trasy
    try {
      final box = Hive.box<RouteModel>('routes');
      await box.put(route.id, updatedRoute);
    } catch (e) {
      print('Błąd aktualizacji trasy w Hive: $e');
    }

    // Firestore
    try {
      await _firestore.collection('routes').doc(route.id).update({
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
      final passengerId = bookingData['passengerId'] as String? ?? '';
      final costShare =
    (bookingData['costShare'] ?? 0).toDouble();

      await bookingDoc.update({
        'status': 'cancelled',
        'updatedAt': Timestamp.now(),
      });

      await _updateRouteAfterCancellation(route, seatsBooked, passengerId);

      await _walletService.refundRide(
        passengerId: passengerId,
        driverId: route.driverId,
        amount: costShare,
        routeId: route.id,
      );

      return true;
    } catch (e) {
      print('Błąd anulowania: $e');
      return false;
    }
  }

  Future<void> _updateRouteAfterCancellation(RouteModel route, int seats, String passengerId) async {
    // aktualizacja tras hive
    final updatedRoute = RouteModel(
      id: route.id,
      start: route.start,
      end: route.end,
      date: route.date,
      seats: route.seats,
      routePoints: route.routePoints,
      bookedSeats: (route.bookedSeats - seats).clamp(0, route.seats),
      driverId: route.driverId,
      driverName: route.driverName,
      totalCost: route.totalCost,
      passengerIds: route.passengerIds.where((id) => id != passengerId).toList(),
      isActive: route.isActive,
    );

    // Hive
    try {
      final box = Hive.box<RouteModel>('routes');
      await box.put(route.id, updatedRoute);
    } catch (e) {
      print('Błąd aktualizacji trasy w Hive: $e');
    }

    // Firestore
    try {
      await _firestore.collection('routes').doc(route.id).update({
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
        if (routeDoc.exists) {
          final routeData = routeDoc.data();
          if (routeData != null && routeData['driverId'] == driverId) {
            bookings.add(booking);
          }
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
  
  Future<bool> addReview(ReviewModel review) async {
    try {
      final existing = await FirebaseFirestore.instance
          .collection('reviews')
          .where('routeId', isEqualTo: review.routeId)
          .where('reviewerId', isEqualTo: review.reviewerId)
          .get();

      if (existing.docs.isNotEmpty) {
        return false;
      }

      await FirebaseFirestore.instance
          .collection('reviews')
          .add(review.toFirestore());

      await _updateUserRating(review.reviewedUserId);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _updateUserRating(String userId) async {
    final reviews = await FirebaseFirestore.instance
        .collection('reviews')
        .where('reviewedUserId', isEqualTo: userId)
        .get();

    if (reviews.docs.isEmpty) return;

    double avg = reviews.docs
            .map((e) => (e['rating'] as int).toDouble())
            .reduce((a, b) => a + b) /
        reviews.docs.length;

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'rating': avg,
      'reviewsCount': reviews.docs.length,
    });
  }
}
