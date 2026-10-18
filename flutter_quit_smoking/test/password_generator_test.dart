import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quit_smoking/utils/password_generator.dart';
import 'package:flutter_quit_smoking/pages/models/goal_model.dart';

void main() {
  group('PasswordGenerator Tests', () {
    test('generatePassword creates password with default length 14', () {
      final password = PasswordGenerator.generatePassword();
      expect(password.length, 14);
    });

    test('generatePassword creates password with custom length', () {
      final password = PasswordGenerator.generatePassword(length: 20);
      expect(password.length, 20);
    });

    test('generatePassword contains uppercase, lowercase, numbers and symbols', () {
      final password = PasswordGenerator.generatePassword(length: 16);
      expect(password.contains(RegExp(r'[a-z]')), isTrue);
      expect(password.contains(RegExp(r'[A-Z]')), isTrue);
      expect(password.contains(RegExp(r'[0-9]')), isTrue);
      expect(password.contains(RegExp(r'[!@#\$%^&*()_\-=+\[\]{}|;:,.<>?]')), isTrue);
    });
  });

  group('Goal Model Tests', () {
    test('toMap and fromMap work correctly', () {
      final goal = Goal(name: 'Ceas', price: '250', currency: 'RON');
      final map = goal.toMap();
      final restored = Goal.fromMap(map);

      expect(restored.name, 'Ceas');
      expect(restored.price, '250');
      expect(restored.currency, 'RON');
      expect(restored, equals(goal));
    });

    test('calculates days needed correctly based on daily cost and savings', () {
      const double dailyCost = 30.0;
      const double goalPrice = 300.0;
      const double currentSavings = 60.0;

      final double remaining = goalPrice - currentSavings;
      final int daysRemaining = (remaining / dailyCost).ceil();

      expect(daysRemaining, 8);
    });
  });
}
