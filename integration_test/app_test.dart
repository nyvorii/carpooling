import 'package:carpooling/main.dart';
import 'package:carpooling/map_screen.dart';
import 'package:carpooling/services/booking_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp();
  });
  testWidgets('user sees add route button', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<User?>(
            create: (_) => null,
          ),
        ],
        child: MaterialApp(
          home: MapScreen(isDriverMode: true),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(Key('addRouteBtn')), findsOneWidget);
  });

  testWidgets('driver can interact with map screen', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<User?>(
            create: (_) => null,
          ),
        ],
        child: MaterialApp(
          home: MapScreen(isDriverMode: true),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(Key('addRouteBtn')), findsOneWidget);

    await tester.tap(find.byKey(Key('addRouteBtn')));
  });

  testWidgets('passenger cannot see add button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MapScreen(isDriverMode: false),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(Key('addRouteBtn')), findsNothing);
  });
}
