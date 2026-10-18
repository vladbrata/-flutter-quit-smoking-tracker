import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quit_smoking/widgets/skeleton_loader.dart';

void main() {
  group('Skeleton Loader Widgets Tests', () {
    testWidgets('renders SkeletonGoalCard with shimmer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonGoalCard(),
          ),
        ),
      );

      expect(find.byType(SkeletonGoalCard), findsOneWidget);
      expect(find.byType(SkeletonShimmer), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('renders SkeletonTimerCard with shimmer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonTimerCard(),
          ),
        ),
      );

      expect(find.byType(SkeletonTimerCard), findsOneWidget);
      expect(find.byType(SkeletonShimmer), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('renders SkeletonStatsGrid with 2 column placeholders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonStatsGrid(),
          ),
        ),
      );

      expect(find.byType(SkeletonStatsGrid), findsOneWidget);
      expect(find.byType(SkeletonShimmer), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('renders SkeletonHealthCard with shimmer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonHealthCard(),
          ),
        ),
      );

      expect(find.byType(SkeletonHealthCard), findsOneWidget);
      expect(find.byType(SkeletonShimmer), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}
