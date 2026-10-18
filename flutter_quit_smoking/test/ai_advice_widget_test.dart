import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quit_smoking/widgets/ai_routine_advice_card.dart';
import 'package:flutter_quit_smoking/widgets/skeleton_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI Advice Widgets Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders AiRoutineAdviceCard and displays routine tip', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiRoutineAdviceCard(
              routine: "Dimineața la cafea",
              timeElapsed: Duration(days: 1),
              cigarettesAvoided: 20,
              moneySaved: 25.0,
            ),
          ),
        ),
      );

      // Inițial sau imediat după primul frame
      await tester.pumpAndSettle();

      expect(find.byType(AiRoutineAdviceCard), findsOneWidget);
      expect(find.text("GHIDUL TĂU ZILNIC (AI)"), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    });

    testWidgets('renders SkeletonAiAdviceCard with shimmer placeholder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonAiAdviceCard(),
          ),
        ),
      );

      expect(find.byType(SkeletonAiAdviceCard), findsOneWidget);
      expect(find.byType(SkeletonShimmer), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}
