import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quit_smoking/pages/models/craving_model.dart';
import 'package:flutter_quit_smoking/pages/models/relapse_model.dart';
import 'package:flutter_quit_smoking/widgets/craving_capture_dialog.dart';
import 'package:flutter_quit_smoking/widgets/craving_relapse_history_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Craving & AI Prediction Models Tests', () {
    test('CravingEvent serializes and deserializes properly', () {
      final now = DateTime(2026, 10, 26, 14, 30);
      final craving = CravingEvent(
        id: 'c123',
        timestamp: now,
        triggerCategory: 'coffee',
        triggerDisplayName: 'Cafea / Dimineață',
        reason: 'Beau cafea la terasă cu colegii fumători',
        intensity: 7,
        overcame: false,
        createdAt: now,
      );

      expect(craving.hourOfDay, 14);
      expect(craving.formattedTime, '14:30');
      expect(craving.timeOfDayLabel, 'Prânz');

      final map = craving.toMap();
      final fromMap = CravingEvent.fromMap(map);

      expect(fromMap.id, 'c123');
      expect(fromMap.hourOfDay, 14);
      expect(fromMap.triggerCategory, 'coffee');
      expect(fromMap.reason, 'Beau cafea la terasă cu colegii fumători');
      expect(fromMap.intensity, 7);
      expect(fromMap.overcame, false);
    });

    test('CombinedRiskPrediction predicts risk when near craving peak hour', () {
      final now = DateTime(2026, 10, 26, 14, 15); // Ora 14:15

      final cravingHistory = [
        CravingEvent(
          id: '1',
          timestamp: DateTime(2026, 10, 25, 14, 0),
          triggerCategory: 'meal',
          triggerDisplayName: 'După masă',
          reason: 'Am terminat prânzul și simt poftă puternică',
          intensity: 8,
          createdAt: DateTime.now(),
        ),
      ];

      final cravingSummary = CravingSummary(
        totalCravings: 1,
        cravingsToday: 1,
        peakHours: [14],
        mostCommonTrigger: 'După masă',
        topReasons: ['Am terminat prânzul și simt poftă puternică'],
        lastCraving: cravingHistory.first,
        history: cravingHistory,
      );

      final prediction = CombinedRiskPrediction.predict(
        now: now,
        routine: '',
        relapseSummary: null,
        cravingSummary: cravingSummary,
      );

      expect(prediction.isAtRisk, true);
      expect(prediction.riskType, RiskType.cravingPrediction);
      expect(prediction.alertTitle, 'AI PREVENTIV: MOMENT CRITIC ANTICIPAT');
      expect(prediction.riskReason.contains('14:00'), true);
      expect(prediction.relevantPastReasons.contains('Am terminat prânzul și simt poftă puternică'), true);
    });

    test('CombinedRiskPrediction detects proximity to past relapse hour', () {
      final now = DateTime(2026, 10, 26, 22, 10); // Ora 22:10

      final relapseHistory = [
        RelapseEvent(
          id: 'r1',
          relapsedAt: DateTime(2026, 10, 20, 22, 30),
          smokeFreeDurationSeconds: 86400,
          triggerCategory: 'social_alcohol',
          triggerDisplayName: 'Alcool / Social',
          notes: 'Am ieșit la bere cu băieții',
          createdAt: DateTime.now(),
        ),
      ];

      final relapseSummary = RelapseSummary(
        totalRelapses: 1,
        lastRelapse: relapseHistory.first,
        mostCommonTrigger: 'Alcool / Social',
        history: relapseHistory,
      );

      final prediction = CombinedRiskPrediction.predict(
        now: now,
        routine: '',
        relapseSummary: relapseSummary,
        cravingSummary: null,
      );

      expect(prediction.isAtRisk, true);
      expect(prediction.riskType, RiskType.relapseProximity);
      expect(prediction.alertTitle, 'ALERTA AI: PERICOL DE RECIDIVĂ');
      expect(prediction.riskReason.contains('22:00'), true);
    });
  });

  group('Craving Dialogs Tests', () {
    testWidgets('CravingCaptureDialog renders properly and allows input', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CravingCaptureDialog(),
          ),
        ),
      );

      expect(find.text("Înregistrează Pofta"), findsOneWidget);
      expect(find.text("Ce a declanșat pofta?"), findsOneWidget);
      expect(find.text("Stres / Presiune"), findsOneWidget);
      expect(find.text("Cafea / Dimineață"), findsOneWidget);
      expect(find.text("După masă"), findsOneWidget);
      expect(find.text("Înregistrează și Respiră SOS"), findsOneWidget);
      expect(find.text("Doar Salvează Pofta"), findsOneWidget);

      // Tastează motivul în câmpul text
      await tester.enterText(find.byType(TextField), 'Mă cert cu colegii la birou');
      await tester.pump();

      expect(find.text('Mă cert cu colegii la birou'), findsOneWidget);
    });

    testWidgets('CravingRelapseHistoryDialog renders tabs and empty state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CravingRelapseHistoryDialog(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("Jurnal Pofte & Recidive"), findsOneWidget);
      expect(find.text("Nu ai înregistrat nicio poftă încă."), findsOneWidget);
    });
  });
}
