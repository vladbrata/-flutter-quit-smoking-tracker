import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/pages/start_quit.dart';

void main() {
  runApp(const MyApp());
}

final darkMode = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.black,
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: darkMode,
      home: const StartQuit(),
    );
  }
}
