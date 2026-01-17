import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/pages/counter_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuestionDialog extends StatefulWidget {
  const QuestionDialog({Key? key}) : super(key: key);

  @override
  _QuestionDialogState createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<QuestionDialog> {
  void _finishSetup() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('startedQuitting', true);
    await prefs.setString('start_date', DateTime.now().toIso8601String());

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CounterPage()),
      );
    }
  }

  // Variabilele se declară aici
  String inputPrice = "";
  String inputPacks = "";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Setări inițiale", textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            keyboardType: TextInputType.number,
            onChanged: (val) => inputPrice = val,
            decoration: const InputDecoration(hintText: "Pack Price"),
          ),
          const SizedBox(height: 10),
          TextField(
            keyboardType: TextInputType.number,
            onChanged: (val) => inputPacks = val,
            decoration: const InputDecoration(hintText: "Packs per day"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _finishSetup();
            // Trimitem datele înapoi ca o Listă sau un Map
            Navigator.pop(context, {
              'price': double.tryParse(inputPrice) ?? 0.0,
              'packs': double.tryParse(inputPacks) ?? 0.0,
            });
          },
          child: const Center(child: Text("DONE")),
        ),
      ],
    );
  }
}
