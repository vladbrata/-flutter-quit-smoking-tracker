import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quit_smoking/widgets/question_dialog.dart';

void main() {
  group('QuestionDialog Tests', () {
    testWidgets('renders price, cigarettes per day, and natural language routine input', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuestionDialog(
              initialPrice: 28.5,
              initialCigarettesPerDay: 15,
              initialSmokingRoutine: "Dimineața la cafea și după masă",
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("Obiceiuri de fumat"), findsOneWidget);
      expect(find.text("Preț pachet (RON)"), findsOneWidget);
      expect(find.text("Țigări fumate pe zi (bucăți)"), findsOneWidget);
      expect(find.text("Când fumezi de obicei? (obiceiuri / momente)"), findsOneWidget);

      expect(find.text("28.50"), findsOneWidget);
      expect(find.text("15"), findsOneWidget);
      expect(find.text("Dimineața la cafea și după masă"), findsOneWidget);
    });

    testWidgets('submits data including natural language routine', (tester) async {
      Map<String, dynamic>? resultData;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  resultData = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => const QuestionDialog(
                      initialPrice: 25.0,
                      initialCigarettesPerDay: 20,
                      initialSmokingRoutine: "La pauza de la serviciu și seara cu prietenii",
                    ),
                  );
                },
                child: const Text("Open Dialog"),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text("Open Dialog"));
      await tester.pumpAndSettle();

      expect(find.text("SALVEAZĂ"), findsOneWidget);
      await tester.tap(find.text("SALVEAZĂ"));
      await tester.pumpAndSettle();

      expect(resultData, isNotNull);
      expect(resultData!['packPrice'], 25.0);
      expect(resultData!['cigarettesPerDay'], 20);
      expect(resultData!['smokingRoutine'], "La pauza de la serviciu și seara cu prietenii");
    });
  });
}
