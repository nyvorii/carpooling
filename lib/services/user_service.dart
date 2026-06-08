import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/auth_user.dart';

abstract class UserService {
  Future<Map<String, dynamic>?> getUserDoc(String uid);
  Future<void> saveUserToFirestore(AuthUser user);
}

class FirebaseUserService implements UserService {
  final FirebaseFirestore _firestore;

  FirebaseUserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Map<String, dynamic>?> getUserDoc(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    return snapshot.data();
  }

  @override
  Future<void> saveUserToFirestore(AuthUser user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'contactEmail': user.email,
        'contactPhone': '',
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'isBlocked': false,
        'role': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'balance': 0.0,
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } else {
      final data = snapshot.data()!;

      if (!data.containsKey('role')) {
        await userDoc.update({'role': 1});
      }
      if (!data.containsKey('contactEmail')) {
        await userDoc.update({'contactEmail': data['email']});
      }
      if (!data.containsKey('isBlocked')) {
        await userDoc.update({'isBlocked': false});
      }
      if (!data.containsKey('contactPhone')) {
        await userDoc.update({'contactPhone': ''});
      }
      if (!data.containsKey('balance')) {
        await userDoc.update({'balance': 0.0});
      }

      await userDoc.update({'lastLogin': FieldValue.serverTimestamp()});
    }
  }
}
