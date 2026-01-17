import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/pages/models/goal_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddGoalsQuestionDialog extends StatefulWidget {
  const AddGoalsQuestionDialog({Key? key}) : super(key: key);

  @override
  _AddGoalsQuestionDialogState createState() => _AddGoalsQuestionDialogState();
}

class _AddGoalsQuestionDialogState extends State<AddGoalsQuestionDialog> {
  // Variabilele se declară aici
  String inputGoalName = "";
  String inputGoalPrice = "";
  String inputCurrency = "";
  int numOfGoals = 0;
  List<String> goals = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Your Goal", textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            keyboardType: TextInputType.number,
            onChanged: (val) => inputGoalName = val,
            decoration: const InputDecoration(
              hintText: "What do you want to buy",
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            keyboardType: TextInputType.number,
            onChanged: (val) => inputGoalPrice = val,
            decoration: const InputDecoration(hintText: "Price"),
          ),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(hintText: "Currency"),
            items: const [
              DropdownMenuItem(value: "RON", child: Text("RON")),
              DropdownMenuItem(value: "EUR", child: Text("EUR")),
              DropdownMenuItem(value: "USD", child: Text("USD")),
            ],
            onChanged: (val) => inputCurrency = val!,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            Goal newGoal = Goal(
              name: inputGoalName,
              price: inputGoalPrice,
              currency: inputCurrency,
            );
            Navigator.pop(context, newGoal);
          },
          child: const Center(child: Text("DONE")),
        ),
      ],
    );
  }
}
