import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quit_smoking/pages/models/health_milestone_model.dart';
import 'package:flutter_quit_smoking/widgets/health_progress_card.dart';
import 'package:flutter_quit_smoking/widgets/lungs_progress_widget.dart';

void main() {
  group('HealthMilestoneService Tests', () {
    test('calculateOverallProgress returns 0.0 when elapsed is zero or negative', () {
      expect(HealthMilestoneService.calculateOverallProgress(Duration.zero), 0.0);
      expect(HealthMilestoneService.calculateOverallProgress(const Duration(seconds: -10)), 0.0);
    });

    test('calculateOverallProgress returns continuous gradual progress before first milestone', () {
      final p10Min = HealthMilestoneService.calculateOverallProgress(const Duration(minutes: 10));
      final p20Min = HealthMilestoneService.calculateOverallProgress(const Duration(minutes: 20));

      expect(p10Min, greaterThan(0.0));
      expect(p10Min, lessThan(p20Min));
      // La 20 de minute (prima bornă din 12), progresul este 1 / 12 ~ 0.0833
      expect(p20Min, closeTo(1.0 / 12.0, 0.001));
    });

    test('calculateOverallProgress increases smoothly across all milestones', () {
      final p8Hours = HealthMilestoneService.calculateOverallProgress(const Duration(hours: 8));
      final p24Hours = HealthMilestoneService.calculateOverallProgress(const Duration(hours: 24));
      final p72Hours = HealthMilestoneService.calculateOverallProgress(const Duration(hours: 72));
      final p20Years = HealthMilestoneService.calculateOverallProgress(const Duration(days: 365 * 20));

      expect(p8Hours, closeTo(2.0 / 12.0, 0.001));
      expect(p24Hours, closeTo(3.0 / 12.0, 0.001));
      expect(p72Hours, closeTo(5.0 / 12.0, 0.001));
      expect(p20Years, 1.0);
    });

    test('getCompletedCount and next milestone tracking works accurately', () {
      expect(HealthMilestoneService.getCompletedCount(Duration.zero), 0);
      expect(HealthMilestoneService.getCompletedCount(const Duration(minutes: 25)), 1);
      expect(HealthMilestoneService.getCompletedCount(const Duration(hours: 25)), 3);

      final nextAtStart = HealthMilestoneService.getNextMilestone(Duration.zero);
      expect(nextAtStart?.title, "20 Minute");

      final nextAt25Min = HealthMilestoneService.getNextMilestone(const Duration(minutes: 25));
      expect(nextAt25Min?.title, "8 Ore");
    });

    test('formatTimeRemaining formats friendly strings', () {
      expect(HealthMilestoneService.formatTimeRemaining(Duration.zero), "atingi acum!");
      expect(HealthMilestoneService.formatTimeRemaining(const Duration(minutes: 15)), "în 15 min");
      expect(HealthMilestoneService.formatTimeRemaining(const Duration(hours: 3, minutes: 20)), "în 3h 20m");
      expect(HealthMilestoneService.formatTimeRemaining(const Duration(days: 4, hours: 2)), "în 4z 2h");
    });
  });

  group('Health UI Widgets Tests', () {
    testWidgets('LungsProgressWidget renders and animates properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LungsProgressWidget(
                progress: 0.45,
                size: 80,
                showPercentage: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LungsProgressWidget), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text("45%"), findsOneWidget);
    });

    testWidgets('HealthProgressCard renders with correct information and milestone progress', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HealthProgressCard(
              timeElapsed: const Duration(hours: 2),
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("RECUPERARE SĂNĂTATE"), findsOneWidget);
      expect(find.textContaining("Următoarea: 8 Ore"), findsOneWidget);
      expect(find.byType(LungsProgressWidget), findsOneWidget);

      await tester.tap(find.byType(HealthProgressCard));
      expect(tapped, isTrue);
    });
  });
}
