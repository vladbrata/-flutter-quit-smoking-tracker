import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quit_smoking/pages/login_page.dart';

void main() {
  testWidgets('LoginPage renders email, password and action buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginPage(),
      ),
    );

    expect(find.text('Bine ai revenit'), findsOneWidget);
    expect(find.text('AUTENTIFICARE'), findsOneWidget);
    expect(find.text('Generează parolă'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
