import 'package:flutter/material.dart';

class QuestionDialog extends StatefulWidget {
  const QuestionDialog({Key? key}) : super(key: key);

  @override
  _QuestionDialogState createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<QuestionDialog> {
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
