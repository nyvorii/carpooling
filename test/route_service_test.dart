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

  test('should return only active routes', () async {
    await firestore.collection('routes').doc('1').set({
      'id': '1',
      'isActive': true,
    });

    await firestore.collection('routes').doc('2').set({
      'id': '2',
      'isActive': false,
    });

    final routes = await service.getRoutes().first;

    expect(routes.length, 1);
    expect(routes.first.id, '1');
  });

  test('should map routePoints correctly', () async {
    await firestore.collection('routes').doc('1').set({
      'id': '1',
      'isActive': true,
      'start': {'lat': 1.0, 'lng': 1.0},
      'end': {'lat': 2.0, 'lng': 2.0},
      'routePoints': [
        {'lat': 1.0, 'lng': 1.0},
        {'lat': 1.5, 'lng': 1.5},
      ],
    });

    final routes = await service.getRoutes().first;

    expect(routes.first.routePoints.length, 2);
  });

  test('should handle missing optional fields gracefully', () async {
    await firestore.collection('routes').doc('1').set({
      'id': '1',
      'isActive': true,
    });

    final routes = await service.getRoutes().first;

    expect(routes.first.id, '1');
    expect(routes.first.isActive, true);
  });

  test('should return only routes for specific driver', () async {
    await firestore.collection('routes').doc('1').set({
      'id': '1',
      'driverId': 'driver1',
      'isActive': true,
    });

    await firestore.collection('routes').doc('2').set({
      'id': '2',
      'driverId': 'driver2',
      'isActive': true,
    });

    final routes = await service.getDriverRoutes('driver1').first;

    expect(routes.length, 1);
    expect(routes.first.id, '1');
  });
}