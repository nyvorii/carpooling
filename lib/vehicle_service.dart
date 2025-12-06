import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VehicleService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get userId => _auth.currentUser!.uid;

  static Stream<QuerySnapshot<Map<String, dynamic>>> getVehiclesStream() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('vehicles')
        .snapshots();
  }

  static Future<void> addVehicle({
    required String brand,
    required String model,
    required String color,
    required String plate,
    File? imageFile,
  }) async {
    String? imageBase64;

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      imageBase64 = base64Encode(bytes);
    }

    await _firestore.collection('users').doc(userId).collection('vehicles').add({
      'brand': brand,
      'model': model,
      'color': color,
      'plate': plate,
      'imageBase64': imageBase64,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateVehicle(
    String vehicleId, {
    required String brand,
    required String model,
    required String color,
    required String plate,
    File? imageFile,
  }) async {
    String? imageBase64;

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      imageBase64 = base64Encode(bytes);
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('vehicles')
        .doc(vehicleId)
        .update({
      'brand': brand,
      'model': model,
      'color': color,
      'plate': plate,
      if (imageBase64 != null) 'imageBase64': imageBase64,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteVehicle(String vehicleId) async {
    await _firestore.collection('users').doc(userId).collection('vehicles').doc(vehicleId).delete();
  }
}
