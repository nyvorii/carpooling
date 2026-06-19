import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:carpooling/services/wallet_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late WalletService wallet;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    wallet = WalletService(firestore: firestore);
  });

  test('PAYMENT FLOW - passenger pays driver correctly', () async {
    // ARRANGE
    await firestore.collection('users').doc('passenger1').set({
      'balance': 100.0,
    });

    await firestore.collection('users').doc('driver1').set({
      'balance': 0.0,
    });

    // ACT
    final result = await wallet.payForRide(
      passengerId: 'passenger1',
      driverId: 'driver1',
      amount: 30.0,
      routeId: 'route1',
    );

    // ASSERT result
    expect(result, true);

    final passenger = await firestore.collection('users').doc('passenger1').get();
    final driver = await firestore.collection('users').doc('driver1').get();

    expect(passenger['balance'], 70.0);
    expect(driver['balance'], 30.0);

    final tx = await firestore.collection('transactions').get();

    expect(tx.docs.length, 2);
  });
}