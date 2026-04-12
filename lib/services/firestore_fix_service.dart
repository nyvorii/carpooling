import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/route_model.dart';
import 'cached_geocoding_service.dart';

class FirestoreFixService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CachedGeocodingService _geocodingService = CachedGeocodingService();

  static Future<void> fixAllRoutesAddresses() async {
    try {
      print('[FirestoreFix] Rozpoczynam geokodowanie tras...');

      final routesSnapshot = await _firestore.collection('routes').get();
      int fixedCount = 0;

      for (final doc in routesSnapshot.docs) {
        final route = RouteModel.fromFirestore(doc);

        if (route.startAddress.isEmpty || route.endAddress.isEmpty) {
          print('[FirestoreFix] Geokoduję trasę: ${doc.id}');

          final startAddress = await _geocodingService.coordinatesToAddress(route.start);
          final endAddress = await _geocodingService.coordinatesToAddress(route.end);

          await _firestore.collection('routes').doc(doc.id).update({
            'startAddress': startAddress,
            'endAddress': endAddress,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          fixedCount++;

          await Future.delayed(Duration(seconds: 2));
        }
      }

      print('[FirestoreFix] Zakończono! Naprawiono $fixedCount tras.');
    } catch (e) {
      print('[FirestoreFix] Błąd: $e');
    }
  }

  static Future<void> printRoutesStats() async {
    try {
      final routesSnapshot = await _firestore.collection('routes').get();
      int totalRoutes = routesSnapshot.docs.length;
      int routesWithAddresses = 0;

      for (final doc in routesSnapshot.docs) {
        final data = doc.data();
        final startAddress = data['startAddress'] as String? ?? '';
        final endAddress = data['endAddress'] as String? ?? '';

        if (startAddress.isNotEmpty && endAddress.isNotEmpty) {
          routesWithAddresses++;
        }
      }

      print('[FirestoreStats] Statystyki tras:');
      print('  Łącznie tras: $totalRoutes');
      print('  Z adresami: $routesWithAddresses');
      print('  Bez adresów: ${totalRoutes - routesWithAddresses}');
    } catch (e) {
      print('[FirestoreStats] Błąd: $e');
    }
  }
}