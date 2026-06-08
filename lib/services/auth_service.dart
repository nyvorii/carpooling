import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/auth_user.dart';

abstract class AuthService {
  Future<AuthUser?> signInWithGoogle();
  Future<void> signOutGoogle();
}

class GoogleAuthService implements AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  GoogleAuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
      : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(scopes: ['email', 'profile']);

  @override
  Future<AuthUser?> signInWithGoogle() async {
    if (kIsWeb) {
      await _auth.signInWithPopup(GoogleAuthProvider());
      final user = _auth.currentUser;
      return user == null ? null : _toAuthUser(user);
    }

    GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
    googleUser ??= await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    return user == null ? null : _toAuthUser(user);
  }

  @override
  Future<void> signOutGoogle() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
  }

  AuthUser _toAuthUser(User user) {
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
    );
  }
}
