import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

double _calculateDistance(LatLng point1, LatLng point2) {
  const double earthRadius = 6371; // km
  final dLat = _toRadians(point2.latitude - point1.latitude);
  final dLon = _toRadians(point2.longitude - point1.longitude);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(point1.latitude)) *
          cos(_toRadians(point2.latitude)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}

double _toRadians(double degrees) => degrees * pi / 180;

bool _isTimeBefore(TimeOfDay t1, TimeOfDay t2) {
  return t1.hour < t2.hour || (t1.hour == t2.hour && t1.minute < t2.minute);
}

bool _isTimeAfter(TimeOfDay t1, TimeOfDay t2) {
  return t1.hour > t2.hour || (t1.hour == t2.hour && t1.minute > t2.minute);
}

List<Map<String, dynamic>> _applyFilters(
    List<Map<String, dynamic>> routes,
    RouteFilters filters,
    ) {
  return routes.where((route) {
    if (filters.dateFrom != null &&
        (route['date'] as DateTime).isBefore(filters.dateFrom!)) {
      return false;
    }
    if (filters.dateTo != null &&
        (route['date'] as DateTime).isAfter(filters.dateTo!)) {
      return false;
    }

    final routeTime = TimeOfDay.fromDateTime(route['date'] as DateTime);
    if (filters.timeFrom != null &&
        _isTimeBefore(routeTime, filters.timeFrom!)) {
      return false;
    }
    if (filters.timeTo != null && _isTimeAfter(routeTime, filters.timeTo!)) {
      return false;
    }

    if (filters.maxPrice != null &&
        (route['totalCost'] as double) > filters.maxPrice!) {
      return false;
    }

    if (filters.minSeats != null &&
        (route['availableSeats'] as int) < filters.minSeats!) {
      return false;
    }

    if (filters.minRating != null &&
        (route['driverRating'] as double) < filters.minRating!) {
      return false;
    }

    if (filters.userLocation != null && filters.searchRadiusKm != null) {
      final distance = _calculateDistance(
          filters.userLocation!, route['start'] as LatLng);
      if (distance > filters.searchRadiusKm!) return false;
    }

    return true;
  }).toList();
}

class RouteFilters {
  DateTime? dateFrom;
  DateTime? dateTo;
  double? maxPrice;
  int? minSeats;
  double? minRating;
  LatLng? userLocation;
  double? searchRadiusKm;
  TimeOfDay? timeFrom;
  TimeOfDay? timeTo;

  RouteFilters({
    this.dateFrom,
    this.dateTo,
    this.maxPrice,
    this.minSeats,
    this.minRating,
    this.userLocation,
    this.searchRadiusKm,
    this.timeFrom,
    this.timeTo,
  });
}

void main() {
  group('Testy wyszukiwania tras (filtrowanie)', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 12, 0);
    final tomorrow = today.add(const Duration(days: 1));

    final warsaw = const LatLng(52.2297, 21.0122);
    final poznan = const LatLng(52.4064, 16.9252);
    final krakow = const LatLng(50.0647, 19.9450);

    final route1 = {
      'id': '1',
      'start': warsaw,
      'end': poznan,
      'date': today,
      'availableSeats': 3,
      'totalCost': 50.0,
      'driverRating': 4.2,
    };
    final route2 = {
      'id': '2',
      'start': warsaw,
      'end': krakow,
      'date': tomorrow,
      'availableSeats': 2,
      'totalCost': 80.0,
      'driverRating': 3.8,
    };
    final route3 = {
      'id': '3',
      'start': warsaw,
      'end': const LatLng(54.3520, 18.6466),
      'date': today,
      'availableSeats': 2,
      'totalCost': 120.0,
      'driverRating': 4.9,
    };
    final routes = [route1, route2, route3];

    test('Filtrowanie po dacie – od (dateFrom)', () {
      final filters = RouteFilters(dateFrom: today);
      final result = _applyFilters(routes, filters);
      expect(result.length, 3);
    });

    test('Filtrowanie po dacie – do (dateTo)', () {
      final filters = RouteFilters(dateTo: today);
      final result = _applyFilters(routes, filters);
      expect(result.length, 2);
    });

    test('Filtrowanie po zakresie dat', () {
      final filters = RouteFilters(dateFrom: today, dateTo: today);
      final result = _applyFilters(routes, filters);
      expect(result.length, 2);
    });

    test('Filtrowanie po cenie maksymalnej (maxPrice)', () {
      final filters = RouteFilters(maxPrice: 70.0);
      final result = _applyFilters(routes, filters);
      expect(result.length, 1);
      expect(result.first['id'], '1');
    });

    test('Filtrowanie po minimalnej liczbie miejsc (minSeats)', () {
      final filters = RouteFilters(minSeats: 3);
      final result = _applyFilters(routes, filters);
      expect(result.length, 1);
      expect(result.first['id'], '1');
    });

    test('Filtrowanie po minimalnej ocenie kierowcy (minRating)', () {
      final filters = RouteFilters(minRating: 4.0);
      final result = _applyFilters(routes, filters);
      expect(result.length, 2);
      expect(result.map((r) => r['id']), contains('1'));
      expect(result.map((r) => r['id']), contains('3'));
    });

    test('Filtrowanie po odległości od lokalizacji użytkownika (promień 10 km)', () {
      final filters = RouteFilters(
        userLocation: warsaw,
        searchRadiusKm: 10,
      );
      final result = _applyFilters(routes, filters);
      expect(result.length, 3);
    });

    test('Filtrowanie po odległości – brak tras w promieniu', () {
      final filters = RouteFilters(
        userLocation: krakow,
        searchRadiusKm: 1,
      );
      final result = _applyFilters(routes, filters);
      expect(result.length, 0);
    });

    test('Filtrowanie po czasie – od (timeFrom)', () {
      final morningRoute = {
        'id': 'morning',
        'start': warsaw,
        'end': poznan,
        'date': DateTime(now.year, now.month, now.day, 8, 0),
        'availableSeats': 4,
        'totalCost': 30,
        'driverRating': 4.0,
      };
      final eveningRoute = {
        'id': 'evening',
        'start': warsaw,
        'end': poznan,
        'date': DateTime(now.year, now.month, now.day, 18, 0),
        'availableSeats': 4,
        'totalCost': 30,
        'driverRating': 4.0,
      };
      final filters = RouteFilters(timeFrom: const TimeOfDay(hour: 10, minute: 0));
      final result = _applyFilters([morningRoute, eveningRoute], filters);
      expect(result.length, 1);
      expect(result.first['id'], 'evening');
    });

    test('Filtrowanie po czasie – do (timeTo)', () {
      final morningRoute = {
        'id': 'morning',
        'start': warsaw,
        'end': poznan,
        'date': DateTime(now.year, now.month, now.day, 8, 0),
        'availableSeats': 4,
        'totalCost': 30,
        'driverRating': 4.0,
      };
      final eveningRoute = {
        'id': 'evening',
        'start': warsaw,
        'end': poznan,
        'date': DateTime(now.year, now.month, now.day, 18, 0),
        'availableSeats': 4,
        'totalCost': 30,
        'driverRating': 4.0,
      };
      final filters = RouteFilters(timeTo: const TimeOfDay(hour: 12, minute: 0));
      final result = _applyFilters([morningRoute, eveningRoute], filters);
      expect(result.length, 1);
      expect(result.first['id'], 'morning');
    });

    test('Łączenie wielu filtrów (cena, miejsca, ocena)', () {
      final filters = RouteFilters(
        maxPrice: 100.0,
        minSeats: 2,
        minRating: 4.0,
      );
      final result = _applyFilters(routes, filters);
      expect(result.length, 1);
      expect(result.first['id'], '1');
    });

    test('Brak filtrów – zwraca wszystkie trasy', () {
      final filters = RouteFilters();
      final result = _applyFilters(routes, filters);
      expect(result.length, 3);
    });
  });

  group('Testy pomocniczych funkcji geograficznych', () {
    test('Odległość między Warszawą a Poznaniem (około 280 km)', () {
      const warsaw = LatLng(52.2297, 21.0122);
      const poznan = LatLng(52.4064, 16.9252);
      final distance = _calculateDistance(warsaw, poznan);
      expect(distance, closeTo(280, 10));
    });

    test('Odległość między tymi samymi punktami wynosi 0', () {
      const point = LatLng(50.0, 20.0);
      expect(_calculateDistance(point, point), 0.0);
    });
  });

  group('Testy porównywania czasu (TimeOfDay)', () {
    const t1 = TimeOfDay(hour: 10, minute: 30);
    const t2 = TimeOfDay(hour: 12, minute: 15);
    const t3 = TimeOfDay(hour: 10, minute: 45);
    const t4 = TimeOfDay(hour: 10, minute: 30);

    test('t1 przed t2', () {
      expect(_isTimeBefore(t1, t2), true);
      expect(_isTimeAfter(t1, t2), false);
    });

    test('t2 po t1', () {
      expect(_isTimeAfter(t2, t1), true);
      expect(_isTimeBefore(t2, t1), false);
    });

    test('t1 przed t3 (ta sama godzina, różne minuty)', () {
      expect(_isTimeBefore(t1, t3), true);
      expect(_isTimeAfter(t1, t3), false);
    });

    test('Czasy równe', () {
      expect(_isTimeBefore(t1, t4), false);
      expect(_isTimeAfter(t1, t4), false);
    });
  });
}