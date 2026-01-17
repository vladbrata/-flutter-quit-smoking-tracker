import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/pages/models/goal_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_quit_smoking/widgets/goal_container_widget.dart';

class AddGoalWidgetDialog extends StatefulWidget {
  final Goal? selectedGoal;
  const AddGoalWidgetDialog({Key? key, this.selectedGoal}) : super(key: key);

  @override
  _AddGoalWidgetDialogState createState() => _AddGoalWidgetDialogState();
}

class _AddGoalWidgetDialogState extends State<AddGoalWidgetDialog> {
  // Variabile
  List<Goal> myGoals = [];
  double _baniEconomisiti = 0.0;
  Timer? _timer;
  DateTime? _startTime;
  double _costPerSecond = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
    _loadQuitData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Helper to check equality
  bool _isGoalSelected(Goal goal) {
    if (widget.selectedGoal == null) return false;
    return goal.name == widget.selectedGoal!.name &&
        goal.price == widget.selectedGoal!.price &&
        goal.currency == widget.selectedGoal!.currency;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        "Select Which Goal You Want To Add",
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.selectedGoal != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context, 'CLEAR');
                  },
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Stop Displaying Goal",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : myGoals.isEmpty
                  ? const Center(child: Text("No goals found."))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: myGoals.length,
                      itemBuilder: (context, index) {
                        final goal = myGoals[index];
                        final isSelected = _isGoalSelected(goal);
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context, goal);
                          },
                          child: AbsorbPointer(
                            child: Container(
                              decoration: isSelected
                                  ? BoxDecoration(
                                      border: Border.all(
                                        color: Colors.greenAccent,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                    )
                                  : null,
                              child: GoalContainer(
                                goal: goal,
                                currentSavings: _baniEconomisiti,
                                onDelete: () {},
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Anulare
          },
          child: const Text("CANCEL"),
        ),
      ],
    );
  }

  void _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('saved_goals_list');

    if (savedData != null) {
      Iterable decodedData = jsonDecode(savedData);
      setState(() {
        myGoals = decodedData.map((item) => Goal.fromMap(item)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Logică de calcul economii pentru afișarea corectă a progresului
  void _loadQuitData() async {
    final prefs = await SharedPreferences.getInstance();
    String? startTimeStr = prefs.getString('start_time');
    double? savedDailyCost = prefs.getDouble('daily_cost');

    if (startTimeStr != null && savedDailyCost != null) {
      setState(() {
        _startTime = DateTime.parse(startTimeStr);
        _costPerSecond = savedDailyCost / 86400;
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startTime != null) {
        setState(() {
          int secondsElapsed = DateTime.now().difference(_startTime!).inSeconds;
          _baniEconomisiti = secondsElapsed * _costPerSecond;
        });
      }
    });
  }
}
