import 'dart:math';

class PasswordGenerator {
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _numbers = '0123456789';
  static const String _specialChars = '!@#\$%^&*()-_=+[]{}|;:,.<>?';

  /// Generează o parolă securizată de o lungime specificată (implicit 14 caractere).
  static String generatePassword({int length = 14}) {
    if (length < 8) length = 8;

    final Random secureRandom = Random.secure();
    final List<String> passwordChars = [];

    // Ne asigurăm că parola conține cel puțin câte un caracter din fiecare categorie
    passwordChars.add(_lowercase[secureRandom.nextInt(_lowercase.length)]);
    passwordChars.add(_uppercase[secureRandom.nextInt(_uppercase.length)]);
    passwordChars.add(_numbers[secureRandom.nextInt(_numbers.length)]);
    passwordChars.add(_specialChars[secureRandom.nextInt(_specialChars.length)]);

    // Completăm restul caracterelor dintr-un set combinat
    final String allChars = _lowercase + _uppercase + _numbers + _specialChars;
    for (int i = passwordChars.length; i < length; i++) {
      passwordChars.add(allChars[secureRandom.nextInt(allChars.length)]);
    }

    // Amestecăm caracterele
    passwordChars.shuffle(secureRandom);

    return passwordChars.join('');
  }
}
