import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/widgets/add_goals_question_dialog.dart';
import 'package:flutter_quit_smoking/widgets/goal_container_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_quit_smoking/pages/models/goal_model.dart';

class GoalsPage extends StatefulWidget {
  GoalsPage({Key? key}) : super(key: key);

  @override
  _GoalsPageState createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  List<Goal> myGoals = [];
  int numOfGoals = 0;
  bool _isLoading = true;

  void initState() {
    super.initState();
    _loadGoals(); // Citim valoarea imediat ce se deschide pagina
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 70.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Goals',
                          style: TextStyle(
                            fontSize: 30.0,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                switch (myGoals.length) {
                  0 => Text('No goals yet'),
                  1 => Text('You have ${myGoals.length} goal'),
                  _ => Text('You have ${myGoals.length} goals'),
                },
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
                GoalContainer(
                  goal: myGoals[4],
                  onDelete: () {
                    myGoals.removeAt(3);
                  },
                ),
                // ListView.builder(
                //   itemCount: myGoals.length,
                //   itemBuilder: (context, index) {
                //     return GoalContainer(
                //       goal: myGoals[index],
                //       onDelete: () => _confirmDelete(
                //         index,
                //       ), // Trimitem indexul pentru a ști ce să ștergem
                //     );
                //   },
                // ),
              ],
            ),
    );
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
        title: const Text("Șterge"),
        content: const Text("Ești sigur?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Nu"),
          ),
          TextButton(
            onPressed: () {
              _onDelete(index); // Apeși "Da", se execută ștergerea
              Navigator.pop(context);
            },
            child: const Text("Da"),
          ),
        ],
      ),
    );
  }
}
