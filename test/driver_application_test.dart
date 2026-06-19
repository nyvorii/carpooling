import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });


  test('should create driver application with pending status', () async {
    await firestore.collection('driver_applications').add({
      'firstName': 'Jan',
      'lastName': 'Kowalski',
      'email': 'jan@test.pl',
      'status': 'pending',
    });

    final snapshot = await firestore.collection('driver_applications').get();

    final data = snapshot.docs.first.data();

    expect(data['status'], 'pending');
  });

  test('should update driver status to approved', () async {
    final docRef = await firestore.collection('driver_applications').add({
      'status': 'pending',
    });

    await docRef.update({
      'status': 'approved',
    });

    final updated = await docRef.get();

    expect(updated.data()?['status'], 'approved');
  });

  test('should return only approved drivers', () async {
    await firestore.collection('driver_applications').add({
      'status': 'approved',
    });

    await firestore.collection('driver_applications').add({
      'status': 'pending',
    });

    final snapshot = await firestore
        .collection('driver_applications')
        .where('status', isEqualTo: 'approved')
        .get();

    expect(snapshot.docs.length, 1);
  });

  test('should recognize approved driver', () {
    final data = {'status': 'approved'};

    final isApproved = data['status'] == 'approved';

    expect(isApproved, true);
  });

  test('should reject non-approved driver', () {
    final data = {'status': 'pending'};

    final isApproved = data['status'] == 'approved';

    expect(isApproved, false);
  });
}