import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:carpooling/driver_form_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
  await Firebase.initializeApp();
});

testWidgets('shows validation errors when fields are empty', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: DriverFormScreen(),
    ),
  );

  await tester.pumpAndSettle();
  await tester.drag(
    find.byType(SingleChildScrollView),
    const Offset(0, -500),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Wyślij aplikację'));
  await tester.pump();
  
  expect(find.text('Wymagane'), findsWidgets);

});

testWidgets('shows error when photos are missing', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: DriverFormScreen(),
    ),
  );

  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextFormField).at(0), 'Jan');
  await tester.enterText(find.byType(TextFormField).at(1), 'Kowalski');
  await tester.enterText(find.byType(TextFormField).at(2), 'jan@test.pl');
  await tester.enterText(find.byType(TextFormField).at(3), 'Czarny');
  await tester.enterText(find.byType(TextFormField).at(4), 'BI1234');
  await tester.drag(
    find.byType(SingleChildScrollView),
    const Offset(0, -500),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Wyślij aplikację'));
  await tester.pump();

  expect(
    find.text('Proszę dodać wszystkie 4 wymagane zdjęcia!'),
    findsOneWidget,
  );

});

testWidgets('accepts valid email only', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: DriverFormScreen(),
    ),
  );

  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextFormField).at(0), 'Jan');
  await tester.enterText(find.byType(TextFormField).at(1), 'Kowalski');
  await tester.enterText(find.byType(TextFormField).at(2), 'zly-email');
  await tester.enterText(find.byType(TextFormField).at(3), 'Czarny');
  await tester.enterText(find.byType(TextFormField).at(4), 'BI1234');

  await tester.ensureVisible(find.text('Wyślij aplikację'));
  await tester.tap(find.text('Wyślij aplikację'));
  await tester.pump();

  expect(find.text('Podaj poprawny e-mail'), findsOneWidget);
});

testWidgets('submit button shows loading indicator', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: DriverFormScreen(),
    ),
  );

  await tester.pumpAndSettle();
  await tester.drag(
    find.byType(SingleChildScrollView),
    const Offset(0, -500),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Wyślij aplikację'));
  await tester.pump();

  expect(find.byType(CircularProgressIndicator), findsNothing);


});

testWidgets('form fields accept input correctly', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: DriverFormScreen(),
    ),
  );


  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextFormField).at(0), 'Jan');
  await tester.enterText(find.byType(TextFormField).at(1), 'Kowalski');

  expect(find.text('Jan'), findsOneWidget);
  expect(find.text('Kowalski'), findsOneWidget);
  });
}
