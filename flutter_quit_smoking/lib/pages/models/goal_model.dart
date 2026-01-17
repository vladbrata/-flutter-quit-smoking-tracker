import 'dart:convert';

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
}
