import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/widgets/add_goals_question_dialog.dart';
import 'package:flutter_quit_smoking/widgets/goal_container_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_quit_smoking/pages/models/goal_model.dart';
import "package:flutter_quit_smoking/pages/counter_page.dart";
import 'package:shared_preferences/shared_preferences.dart';

class GoalsPage extends StatefulWidget {
  GoalsPage({Key? key}) : super(key: key);

  @override
  _GoalsPageState createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  double _baniEconomisiti = 0.0;
  Timer? _timer;
  DateTime? _startTime;
  double _costPerSecond = 0;
  List<Goal> myGoals = [];
  int numOfGoals = 0;
  bool _isLoading = true;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Obiectivele tale"),
        centerTitle: true,
        backgroundColor: Colors.transparent, // Sau Color(0xFF8B0000)
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [],
                  ),
                ),
                switch (myGoals.length) {
                  0 => Text('No goals yet'),
                  1 => Text('You have ${myGoals.length} goal'),
                  _ => Text('You have ${myGoals.length} goals'),
                },
                Expanded(
                  child: ListView.builder(
                    itemCount: myGoals.length,
                    itemBuilder: (context, index) {
                      return GoalContainer(
                        goal: myGoals[index],
                        currentSavings: _baniEconomisiti,
                        onDelete: () => _confirmDelete(
                          index,
                        ), // Trimitem indexul pentru a ști ce să ștergem
                      );
                    },
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _openAddGoalDialog();
                  },
                  icon: const Icon(Icons.add, color: Colors.white, size: 24),
                  label: Text(
                    "Add Goal",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B0000),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),

                SizedBox(height: 20),
              ],
            ),
    );
  }

  // Încărcăm datele despre fumat (start time, daily cost)
  void _loadQuitData() async {
    final prefs = await SharedPreferences.getInstance();
    String? startTimeStr = prefs.getString('start_time');
    double? savedDailyCost = prefs.getDouble('daily_cost');

    if (startTimeStr != null && savedDailyCost != null) {
      setState(() {
        _startTime = DateTime.parse(startTimeStr);
        _costPerSecond = savedDailyCost / 86400; // 86400 secunde într-o zi
      });
      _startTimer(); // Pornim timer-ul local pentru această pagină
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

  // Funcția de salvare
  void _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    // Transformăm lista de obiecte într-o listă de Map-uri, apoi în String JSON
    String encodedData = jsonEncode(myGoals.map((g) => g.toMap()).toList());
    await prefs.setString('saved_goals_list', encodedData);
  }

  // Funcția de încărcare (apeleaz-o în initState)

  // Când apeși butonul "Add Goal"
  void _openAddGoalDialog() async {
    final Goal? result = await showDialog(
      context: context,
      builder: (context) => AddGoalsQuestionDialog(),
    );

    if (result != null) {
      setState(() {
        myGoals.add(result); // Adăugăm noul obiect în listă
      });
      _saveGoals(); // Salvăm lista actualizată pe telefon
    }
  }

  void _onDelete(int index) {
    setState(() {
      myGoals.removeAt(index);
    });
    _saveGoals(); // Funcția care salvează lista actualizată în SharedPreferences
  }

  void _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('saved_goals_list');

    if (savedData != null) {
      Iterable decodedData = jsonDecode(savedData);
      setState(() {
        myGoals = decodedData.map((item) => Goal.fromMap(item)).toList();
        _isLoading = false; // 2. Încărcare terminată
      });
    } else {
      setState(() {
        _isLoading = false; // 3. Nu sunt date, dar am terminat de căutat
      });
    }
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Șterge",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Ești sigur?",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text("Nu", style: TextStyle(fontSize: 16)),
          ),
          TextButton(
            onPressed: () {
              _onDelete(index); // Apeși "Da", se execută ștergerea
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              "Da",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
