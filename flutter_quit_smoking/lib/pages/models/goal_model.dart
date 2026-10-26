class Goal {
  final String name;
  final String price;
  final String currency;

  Goal({required this.name, required this.price, required this.currency});

  // Transformă obiectul Goal într-un Map (pentru JSON)
  Map<String, dynamic> toMap() {
    return {'name': name, 'price': price, 'currency': currency};
  }

  // Creează un obiect Goal dintr-un Map
  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      name: map['name'],
      price: map['price'],
      currency: map['currency'],
    );
  }

  double get exchangeRate {
    if (currency == 'EUR') return 4.97;
    if (currency == 'USD') return 4.60;
    return 1.0;
  }

  double get priceInRon {
    final double original = double.tryParse(price) ?? 0.0;
    return original * exchangeRate;
  }

  double calculateProgress(double currentSavingsInRon) {
    if (priceInRon <= 0) return 1.0;
    return (currentSavingsInRon / priceInRon).clamp(0.0, 1.0);
  }

  int calculatePercentage(double currentSavingsInRon) {
    return (calculateProgress(currentSavingsInRon) * 100).toInt();
  }

  double remainingRon(double currentSavingsInRon) {
    return (priceInRon - currentSavingsInRon).clamp(0.0, double.infinity);
  }

  int daysRemaining(double currentSavingsInRon, double dailyCost) {
    if (dailyCost <= 0) return 0;
    return (remainingRon(currentSavingsInRon) / dailyCost).ceil();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Goal &&
        other.name == name &&
        other.price == price &&
        other.currency == currency;
  }

  @override
  int get hashCode => name.hashCode ^ price.hashCode ^ currency.hashCode;
}
