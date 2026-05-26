import 'package:cloud_firestore/cloud_firestore.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Future<bool> payForRide({
    required String passengerId,
    required String driverId,
    required double amount,
    required String routeId,
  }) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final passengerRef =
            _firestore.collection('users').doc(passengerId);

        final driverRef =
            _firestore.collection('users').doc(driverId);

        final passengerDoc = await transaction.get(passengerRef);
        final driverDoc = await transaction.get(driverRef);

        final passengerBalance =
            _toDouble(passengerDoc.data()?['balance']);

        final driverBalance =
            _toDouble(driverDoc.data()?['balance']);

        //  brak środków
        if (passengerBalance < amount) {
          return false;
        }

        //  odejmij pasażerowi 
        transaction.update(passengerRef, {
          'balance': passengerBalance - amount,
        });

        //  dodaj kierowcy OD RAZU (model escrow uproszczony)
        transaction.update(driverRef, {
          'balance': driverBalance + amount,
        });

        final tx1 =
            _firestore.collection('transactions').doc();

        transaction.set(tx1, {
          'userId': passengerId,
          'type': 'payment',
          'amount': amount,
          'routeId': routeId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        final tx2 =
            _firestore.collection('transactions').doc();

        transaction.set(tx2, {
          'userId': driverId,
          'type': 'income',
          'amount': amount,
          'routeId': routeId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      print('payForRide error: $e');
      return false;
    }
  }

  ///  ZWROT (ANULOWANIE)
  Future<void> refundRide({
    required String passengerId,
    required String driverId,
    required double amount,
    required String routeId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final passengerRef =
          _firestore.collection('users').doc(passengerId);

      final driverRef =
          _firestore.collection('users').doc(driverId);

      final passengerDoc = await transaction.get(passengerRef);
      final driverDoc = await transaction.get(driverRef);

      final passengerBalance =
          _toDouble(passengerDoc.data()?['balance']);

      final driverBalance =
          _toDouble(driverDoc.data()?['balance']);

      transaction.update(passengerRef, {
        'balance': passengerBalance + amount,
      });

      transaction.update(driverRef, {
        'balance': driverBalance - amount,
      });

      final tx1 =
          _firestore.collection('transactions').doc();

      transaction.set(tx1, {
        'userId': passengerId,
        'type': 'refund',
        'amount': amount,
        'routeId': routeId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final tx2 =
          _firestore.collection('transactions').doc();

      transaction.set(tx2, {
        'userId': driverId,
        'type': 'refund_sent',
        'amount': amount,
        'routeId': routeId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}