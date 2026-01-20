import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Importă paginile tale
import 'pages/counter_page.dart';
import 'pages/start_quit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/auth_layout.dart';

void main() async {
  // Obligatoriu când avem cod async înainte de runApp
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  // Citim starea. Dacă nu există, implicit este false.

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quit Smoking App',
      theme: ThemeData.dark(),
      // Aici se întâmplă magia:
      home: AuthLayout(),
    );
  }
}
