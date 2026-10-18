import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quit_smoking/services/gemini_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GeminiService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('getTimeOfDayLabel returns correct Romanian time slots', () {
      final morning = DateTime(2026, 10, 18, 8, 30);
      expect(geminiService.getTimeOfDayLabel(morning), contains("Dimineață"));

      final noon = DateTime(2026, 10, 18, 12, 15);
      expect(geminiService.getTimeOfDayLabel(noon), contains("Prânz"));

      final afternoon = DateTime(2026, 10, 18, 16, 45);
      expect(geminiService.getTimeOfDayLabel(afternoon), contains("După-amiază"));

      final evening = DateTime(2026, 10, 18, 20, 0);
      expect(geminiService.getTimeOfDayLabel(evening), contains("Seară"));

      final night = DateTime(2026, 10, 18, 2, 0);
      expect(geminiService.getTimeOfDayLabel(night), contains("Noapte"));
    });

    test('API key management (save, retrieve, clear)', () async {
      expect(await geminiService.getApiKey(), isNull);

      await geminiService.setApiKey("test_api_key_123");
      expect(await geminiService.getApiKey(), equals("test_api_key_123"));

      await geminiService.clearApiKey();
      expect(await geminiService.getApiKey(), isNull);
    });

    test('getRoutineTip fallback generates advice matching coffee routine in morning', () async {
      final tip = await geminiService.getRoutineTip(
        routine: "Dimineața la cafea cu colegii",
        timeElapsed: const Duration(days: 2, hours: 4),
        cigarettesAvoided: 40,
        moneySaved: 50.0,
        forceRefresh: true,
      );

      expect(tip, isNotEmpty);
      expect(tip.length, greaterThan(15));
    });

    test('getCravingTips fallback incorporates exact progress and milestone', () async {
      final tips = await geminiService.getCravingTips(
        timeElapsed: const Duration(days: 3, hours: 6),
        cigarettesAvoided: 60,
        moneySaved: 75.0,
        routine: "La cafea și când sunt stresat la birou",
        nextMilestone: "Capacitatea pulmonară crește cu 30%",
      );

      expect(tips.length, greaterThanOrEqualTo(2));
      // Primul sfat menționează timpul sau țigările evitate
      expect(tips[0], contains("60"));
      // Unul din sfaturi face referire la etapa de sănătate
      final hasMilestone = tips.any((t) => t.contains("Capacitatea pulmonară"));
      expect(hasMilestone, isTrue);
    });
  });
}
