import 'package:flutter_test/flutter_test.dart';
import 'package:carpooling/services/payment_validator.dart';

void main() {
  final validator = PaymentValidator();

  group('Walidacja płatności', () {

    test('Wystarczające środki', () {
      expect(
        validator.hasEnoughFunds(100, 50),
        true,
      );
    });

    test('Brak środków', () {
      expect(
        validator.hasEnoughFunds(20, 50),
        false,
      );
    });

    test('Saldo równe kosztowi', () {
      expect(
        validator.hasEnoughFunds(50, 50),
        true,
      );
    });

    test('Koszt 0 PLN', () {
      expect(
        validator.hasEnoughFunds(100, 0),
        true,
      );
    });
  });
}