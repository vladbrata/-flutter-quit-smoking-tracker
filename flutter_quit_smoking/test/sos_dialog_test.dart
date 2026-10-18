import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quit_smoking/widgets/sos_craving_dialog.dart';

void main() {
  testWidgets('SosCravingDialog renders properly and switches techniques and victory view',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SosCravingDialog(),
        ),
      ),
    );

    // Verifică elementele inițiale
    expect(find.text('SOS CRAVING'), findsOneWidget);
    expect(find.text('INSPIRĂ'), findsOneWidget);
    expect(find.text('Box (4-4-4-4)'), findsOneWidget);
    expect(find.text('Relaxare (4-7-8)'), findsOneWidget);
    expect(find.text('Am depășit pofta! 🎉'), findsOneWidget);
    expect(find.text('Pauză'), findsOneWidget);

    // Schimbă tehnica la Relaxare (4-7-8)
    await tester.tap(find.text('Relaxare (4-7-8)'));
    await tester.pump();
    expect(find.text('INSPIRĂ'), findsOneWidget);

    // Testează pauză / reluare
    await tester.tap(find.text('Pauză'));
    await tester.pump();
    expect(find.text('Reia'), findsOneWidget);

    await tester.tap(find.text('Reia'));
    await tester.pump();
    expect(find.text('Pauză'), findsOneWidget);

    // Apasă pe "Am depășit pofta! 🎉"
    await tester.tap(find.text('Am depășit pofta! 🎉'));
    await tester.pumpAndSettle();

    // Verifică vizualizarea de succes
    expect(find.text('Victorie Împotriva Poftei!'), findsOneWidget);
    expect(find.text('CONTINUĂ CU FORȚE PROASPETE'), findsOneWidget);
  });
}
