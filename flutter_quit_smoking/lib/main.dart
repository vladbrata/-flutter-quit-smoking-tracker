import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Importă paginile tale
import 'pages/counter_page.dart';
import 'pages/start_quit.dart';

void main() async {
  // Obligatoriu când avem cod async înainte de runApp
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  // Citim starea. Dacă nu există, implicit este false.
  bool startedQuitting = prefs.getBool('startedQuitting') ?? false;

  runApp(MyApp(startedQuitting: startedQuitting));
}

class MyApp extends StatelessWidget {
  final bool startedQuitting;

  const MyApp({super.key, required this.startedQuitting});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      // Aici se întâmplă magia:
      home: startedQuitting ? const CounterPage() : const StartQuit(),
    );
  }
}
