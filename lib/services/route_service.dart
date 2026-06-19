import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/route_model.dart';

class RouteService {
  final FirebaseFirestore firestore;

  RouteService(this.firestore);

  Future<void> saveRoute(RouteModel route) async {
    await firestore
        .collection('routes')
        .doc(route.id)
        .set(route.toFirestore());
  }

  Stream<List<RouteModel>> getRoutes() {
    return firestore.collection('routes').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => RouteModel.fromMap(doc.data(), doc.id))
          .where((r) => r.isActive)
          .toList();
    });
  }

  Stream<List<RouteModel>> getDriverRoutes(String driverId) {
  return firestore
      .collection('routes')
      .where('driverId', isEqualTo: driverId)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => RouteModel.fromMap(doc.data(), doc.id))
        .where((route) => route.isActive)
        .toList();
  });
}
}