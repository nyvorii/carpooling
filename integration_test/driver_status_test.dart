import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:carpooling/map_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp();
  });
  testWidgets('approved driver can see add route button', (tester) async {
    final userData = {'status': 'approved'};

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final isDriver = userData['status'] == 'approved';

            return MapScreen(isDriverMode: isDriver);
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('addRouteBtn')), findsOneWidget);
  });

  testWidgets('pending driver cannot see add route button', (tester) async {
    final userData = {'status': 'pending'};

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final isDriver = userData['status'] == 'approved';

            return MapScreen(isDriverMode: isDriver);
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('addRouteBtn')), findsNothing);
  });

  testWidgets('approved driver can click add route button', (tester) async {
    final userData = {'status': 'approved'};

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final isDriver = userData['status'] == 'approved';

            return MapScreen(isDriverMode: isDriver);
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('addRouteBtn')));
    await tester.pump();

    expect(true, true);
  });

  testWidgets('pending driver cannot click button', (tester) async {
    final userData = {'status': 'pending'};

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final isDriver = userData['status'] == 'approved';

            return MapScreen(isDriverMode: isDriver);
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('addRouteBtn')), findsNothing);
  });
}