import 'package:carpooling/home_screen.dart';
import 'package:carpooling/models/auth_user.dart';
import 'package:carpooling/services/auth_service.dart';
import 'package:carpooling/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

class FakeAuthService implements AuthService {
  bool signInCalled = false;
  bool signOutCalled = false;
  final AuthUser? user;

  FakeAuthService({this.user});

  @override
  Future<AuthUser?> signInWithGoogle() async {
    signInCalled = true;
    return user;
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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login integration registers user and blocks a blocked account',
      (WidgetTester tester) async {
    final fakeAuthService = FakeAuthService(
      user: AuthUser(
        uid: 'test-uid',
        email: 'test@example.com',
        displayName: 'Test User',
        photoURL: 'https://example.com/avatar.png',
      ),
    );
    final fakeUserService = FakeUserService(storedData: {
      'isBlocked': true,
      'role': 1,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          authService: fakeAuthService,
          userService: fakeUserService,
        ),
      ),
    );

    expect(find.text('Zaloguj przez Google'), findsOneWidget);

    await tester.tap(find.text('Zaloguj przez Google'));
    await tester.pumpAndSettle();

    expect(fakeAuthService.signInCalled, isTrue);
    expect(fakeUserService.savedUser, isNotNull);
    expect(fakeUserService.savedUser?.uid, 'test-uid');
    expect(fakeAuthService.signOutCalled, isTrue);
  });
}
