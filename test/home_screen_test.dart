import 'dart:async';

import 'package:carpooling/home_screen.dart';
import 'package:carpooling/models/auth_user.dart';
import 'package:carpooling/services/auth_service.dart';
import 'package:carpooling/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthService implements AuthService {
  bool signInCalled = false;
  bool signOutCalled = false;
  final Future<AuthUser?> Function()? signInHandler;

  FakeAuthService({this.signInHandler});

  @override
  Future<AuthUser?> signInWithGoogle() async {
    signInCalled = true;
    return signInHandler?.call();
  }

  @override
  Future<void> signOutGoogle() async {
    signOutCalled = true;
  }
}

class FakeUserService implements UserService {
  AuthUser? savedUser;
  final Map<String, dynamic>? storedData;

  FakeUserService({this.storedData});

  @override
  Future<Map<String, dynamic>?> getUserDoc(String uid) async {
    return storedData;
  }

  @override
  Future<void> saveUserToFirestore(AuthUser user) async {
    savedUser = user;
  }
}

void main() {
  testWidgets('HomeScreen shows loading while Google sign-in is pending',
      (WidgetTester tester) async {
    final completer = Completer<AuthUser?>();
    final fakeAuthService = FakeAuthService(signInHandler: () => completer.future);
    final fakeUserService = FakeUserService();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(authService: fakeAuthService, userService: fakeUserService),
      ),
    );

    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(fakeAuthService.signInCalled, isTrue);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(null);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
