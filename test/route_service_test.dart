import 'package:carpooling/models/route_model.dart';
import 'package:carpooling/services/route_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';


void main() {
  late FakeFirebaseFirestore firestore;
  late RouteService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = RouteService(firestore);
  });

  test('should save route to firestore', () async {
    final firestore = FakeFirebaseFirestore();
    final service = RouteService(firestore);

    final route = RouteModel(
      id: '1',
      isActive: true,
    );

    await service.saveRoute(route);

    final doc = await firestore.collection('routes').doc('1').get();

    expect(doc.exists, true);
  });

  test('should load routes from firestore', () async {
    final firestore = FakeFirebaseFirestore();
    final service = RouteService(firestore);

    await firestore.collection('routes').doc('1').set({
      'id': '1',
      'isActive': true,
    });

    final routes = await service.getRoutes().first;

    expect(routes.length, 1);
  });

  test('routes from firestore are returned correctly', () async {
    final firestore = FakeFirebaseFirestore();
    final service = RouteService(firestore);

    await firestore.collection('routes').doc('1').set({
      'id': '1',
      'isActive': true,
      'start': {'lat': 1.0, 'lng': 1.0},
      'end': {'lat': 2.0, 'lng': 2.0},
      'routePoints': [],
    });

    final routes = await service.getRoutes().first;

    expect(routes.first.id, '1');
  });
}