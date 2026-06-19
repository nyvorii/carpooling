class PaymentValidator {
  bool hasEnoughFunds(
    double balance,
    double amount,
  ) {
    return balance >= amount;
  }
}