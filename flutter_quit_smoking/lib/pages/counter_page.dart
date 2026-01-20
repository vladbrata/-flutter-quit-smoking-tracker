import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/pages/auth_layout.dart';
import 'package:flutter_quit_smoking/pages/goals_page.dart';

import 'package:flutter_quit_smoking/pages/roadmap_page.dart';
import 'package:flutter_quit_smoking/pages/start_quit.dart';
import 'package:flutter_quit_smoking/services/auth_services.dart';
import 'package:flutter_quit_smoking/widgets/add_goal_widget_dialog.dart';
import 'package:flutter_quit_smoking/pages/models/goal_model.dart';
import 'package:flutter_quit_smoking/widgets/mini_goal_widget.dart';
import 'package:flutter_quit_smoking/widgets/question_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  // Variabile pentru timp și bani
  Timer? _timer;
  int _secundeScurse = 0;
  double _dailyCost = 0.0;
  double _baniEconomisiti = 0.0;
  double _costPerSecunda = 0.0;
  Goal? _selectedGoal;

  // Flag pentru a știi când să afișăm cronometrul
  bool _isStarted = false;

  @override
  void initState() {
    super.initState();
    // Deschide dialogul imediat ce se încarcă pagina
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _showSetupDialog();
    // });
    _loadSavedData();
  }

  void logout() {
    try {
      authServices.value.signOut();
    } catch (e) {
      print(e);
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuthLayout()),
    );
  }

  // Funcția care gestionează Dialogul și primirea datelor
  void _showSetupDialog() async {
    final Map<String, double>? result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const QuestionDialog(),
    );

    if (result != null) {
      DateTime now = DateTime.now();
      setState(() {
        // Calculăm costul zilnic (Preț pachet * Pachete pe zi)
        _dailyCost = result['price']! * result['packs']!;
        // Calculăm cât economisești la fiecare secundă
        _costPerSecunda = _dailyCost / 86400;
        _isStarted = true;
        // Resetăm timpul
        _secundeScurse = 0;
        _baniEconomisiti = 0.0;
      });

      // Salvăm configurația și timpul de start
      _saveQuitData(now, _dailyCost);
      // După ce avem datele, pornim cronometrul
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secundeScurse++;
        _baniEconomisiti = _secundeScurse * _costPerSecunda;
      });
    });
  }

  // Formatează secundele în Zile, Ore, Minute, Secunde
  String _formatTime(int totalSeconds) {
    Duration duration = Duration(seconds: totalSeconds);
    int days = duration.inDays;
    int hours = duration.inHours.remainder(24);
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);

    return "${days}d ${hours}h ${minutes}m ${seconds}s";
  }

  @override
  void dispose() {
    _timer?.cancel(); // Oprim timer-ul ca să nu consume baterie în fundal
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fundalul negru cerut
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF121212), // Fundal închis pentru meniu
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Header-ul Drawer-ului (poți pune numele lui Lety aici)
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xFF8B0000), // Roșu închis
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    Icon(Icons.smoke_free, color: Colors.white, size: 40),
                    SizedBox(height: 10),
                    Text(
                      "Meniu Setări",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              ListTile(
                leading: const Icon(
                  Icons.attach_money_sharp,
                  color: Colors.grey,
                ),
                title: const Text(
                  "My Financial Goals",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GoalsPage()),
                  );
                  _verifySelectedGoal();
                },
              ),

              // Opțiunea: Roadmap
              ListTile(
                leading: const Icon(Icons.timeline, color: Colors.grey),
                title: const Text(
                  "Journey Roadmap",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RoadmapPage(),
                    ),
                  );
                },
              ),

              const Divider(color: Colors.white10), // Linie despărțitoare
              // Opțiunea 3: Ieșire
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white38),
                title: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.white38),
                ),
                onTap: () => logout(),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Flutter va adăuga automat iconița de meniu (hamburger icon)
        // în stânga dacă ai un drawer definit.
      ),
      body: SafeArea(
        child: Center(
          child: _isStarted
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _selectedGoal == null
                        ? ElevatedButton(
                            onPressed: () async {
                              final result = await showDialog(
                                context: context,
                                builder: (context) =>
                                    const AddGoalWidgetDialog(),
                              );
                              if (result != null && result is Goal) {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setString(
                                  'selected_goal',
                                  jsonEncode(result.toMap()),
                                );
                                setState(() {
                                  _selectedGoal = result;
                                });
                              }
                            },
                            child: const Text(
                              'Add goal widget',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : InkWell(
                            onTap: () async {
                              final result = await showDialog(
                                context: context,
                                builder: (context) => AddGoalWidgetDialog(
                                  selectedGoal: _selectedGoal,
                                ),
                              );
                              if (result == 'CLEAR') {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.remove('selected_goal');
                                setState(() {
                                  _selectedGoal = null;
                                });
                              } else if (result != null && result is Goal) {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setString(
                                  'selected_goal',
                                  jsonEncode(result.toMap()),
                                );
                                setState(() {
                                  _selectedGoal = result;
                                });
                              }
                            },
                            child: MiniGoalWidget(
                              goal: _selectedGoal!,
                              currentSavings: _baniEconomisiti,
                            ),
                          ),
                    const SizedBox(height: 190),
                    const Text(
                      "TIMP FĂRĂ FUMAT",
                      style: TextStyle(color: Colors.white70, letterSpacing: 2),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onLongPress: _showEditStartTimeDialog,
                      child: Text(
                        _formatTime(_secundeScurse),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace', // Arată ca un ceas digital
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    const Text(
                      "BANI ECONOMISIȚI",
                      style: TextStyle(color: Colors.white70, letterSpacing: 2),
                    ),
                    const SizedBox(height: 10),
                    // Afișăm banii cu 4 zecimale ca să se vadă progresul rapid
                    Text(
                      "${_baniEconomisiti.toStringAsFixed(4)} RON",
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 45,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(color: Colors.greenAccent, blurRadius: 20),
                        ],
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        _resetProgression();
                      },
                      child: const Text(
                        'I have smoked :(',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                )
              : const CircularProgressIndicator(color: Colors.red),
        ),
      ),
    );
  }

  void _saveQuitData(DateTime startTime, double dailyCost) async {
    final prefs = await SharedPreferences.getInstance();
    // Salvăm data actuală ca string (format ISO 8601)
    await prefs.setString('start_time', startTime.toIso8601String());
    await prefs.setDouble('daily_cost', dailyCost);
  }

  void _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    String? startTimeStr = prefs.getString('start_time');
    double? savedDailyCost = prefs.getDouble('daily_cost');
    String? savedGoalStr = prefs.getString('selected_goal');

    if (savedGoalStr != null) {
      _selectedGoal = Goal.fromMap(jsonDecode(savedGoalStr));
    }

    if (startTimeStr != null && savedDailyCost != null) {
      setState(() {
        DateTime startTime = DateTime.parse(startTimeStr);
        _dailyCost = savedDailyCost;
        _costPerSecunda = _dailyCost / 86400;

        // Calculăm secundele scurse de atunci până ACUM
        _secundeScurse = DateTime.now().difference(startTime).inSeconds;
        // Recalculăm banii economisiți pe baza timpului scurs
        setState(() {
          _baniEconomisiti = _secundeScurse * _costPerSecunda;
        });

        _isStarted = true;
      });
      _startTimer();
    } else {
      // Dacă nu avem date, arătăm dialogul de întrebări
      _showSetupDialog();
    }
  }

  void _verifySelectedGoal() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('saved_goals_list');

    if (_selectedGoal != null) {
      if (savedData != null) {
        Iterable decodedData = jsonDecode(savedData);
        List<Goal> allGoals = decodedData
            .map((item) => Goal.fromMap(item))
            .toList();

        // Verificăm dacă goal-ul selectat mai există în listă
        // (Aici ne folosim de override-ul operatorului == din Goal)
        if (!allGoals.contains(_selectedGoal)) {
          setState(() {
            _selectedGoal = null;
          });
          await prefs.remove('selected_goal');
        }
      } else {
        // Dacă lista e goală complet, sigur nu mai există goal-ul
        setState(() {
          _selectedGoal = null;
        });
        await prefs.remove('selected_goal');
      }
    }
  }

  void _resetProgression() async {
    // Obținem instanța SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // Ștergem datele
    await prefs.remove('start_time');
    await prefs.remove('daily_cost');
    await prefs.remove('selected_goal');

    setState(() {
      _timer?.cancel(); // Oprim cronometrul actual
      _secundeScurse = 0; // Resetăm timpul vizual
      _isStarted = false; // Ne întoarcem la starea de dinainte de configurare
      _baniEconomisiti = 0;
    });

    // Redeschidem dialogul pentru ca utilizatorul să poată reîncepe procesul
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const StartQuit()),
    );
  }

  void _showEditStartTimeDialog() async {
    // Current start time estimation: now minus elapsed seconds
    final DateTime currentStartTime = DateTime.now().subtract(
      Duration(seconds: _secundeScurse),
    );

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: currentStartTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.red,
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1E1E1E),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentStartTime),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Colors.red,
                onPrimary: Colors.black,
                surface: Color(0xFF1E1E1E),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        if (!mounted) return;
        final DateTime newStartTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // Ensure we don't pick a time in the future
        if (newStartTime.isAfter(DateTime.now())) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You cannot select a time in the future!"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        _updateStartTime(newStartTime);
      }
    }
  }

  void _updateStartTime(DateTime newStartTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('start_time', newStartTime.toIso8601String());

    setState(() {
      _secundeScurse = DateTime.now().difference(newStartTime).inSeconds;
      _baniEconomisiti = _secundeScurse * _costPerSecunda;
    });
  }
}
