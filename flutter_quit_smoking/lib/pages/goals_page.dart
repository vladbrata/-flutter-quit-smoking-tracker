import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/pages/models/goal_model.dart';
import 'package:flutter_quit_smoking/services/auth_services.dart';
import 'package:flutter_quit_smoking/services/database_service.dart';
import 'package:flutter_quit_smoking/widgets/add_goals_question_dialog.dart';
import 'package:flutter_quit_smoking/widgets/goal_container_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  double _baniEconomisiti = 0.0;
  double _dailyCost = 0.0;
  Timer? _timer;
  DateTime? _startTime;
  double _costPerSecond = 0;
  List<Goal> myGoals = [];
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

  // Calculul sumei totale a tuturor obiectivelor convertite în RON
  double get _totalGoalsPriceInRon {
    return myGoals.fold(0.0, (sum, g) {
      double rate = 1.0;
      if (g.currency == 'EUR') rate = 4.97;
      if (g.currency == 'USD') rate = 4.60;
      return sum + ((double.tryParse(g.price) ?? 0.0) * rate);
    });
  }

  // Suma rămasă de economisit pentru toate obiectivele combinate
  double get _totalRemainingRon =>
      (_totalGoalsPriceInRon - _baniEconomisiti).clamp(0.0, double.infinity);

  // Numărul de zile fără fumat necesare pentru a atinge TOATE obiectivele
  int get _totalDaysForAllGoals =>
      _dailyCost > 0 ? (_totalRemainingRon / _dailyCost).ceil() : 0;

  double get _globalProgressValue => _totalGoalsPriceInRon > 0
      ? (_baniEconomisiti / _totalGoalsPriceInRon).clamp(0.0, 1.0)
      : 0.0;

  @override
  Widget build(BuildContext context) {
    final bool allAchieved = myGoals.isNotEmpty && _totalRemainingRon <= 0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Obiective Financiare",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B0000)))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                // Hero Summary Card: Zile fără fumat pentru a atinge toate obiectivele
                if (myGoals.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF261215),
                          Color(0xFF141416),
                        ],
                      ),
                      border: Border.all(
                        color: allAchieved
                            ? Colors.greenAccent.withValues(alpha: 0.4)
                            : const Color(0xFF8B0000).withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B0000).withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: allAchieved
                                    ? Colors.greenAccent.withValues(alpha: 0.15)
                                    : const Color(0xFF8B0000).withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                allAchieved
                                    ? Icons.emoji_events_rounded
                                    : Icons.stars_rounded,
                                color: allAchieved ? Colors.greenAccent : const Color(0xFFFF6B6B),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "TOTAL TOATE OBIECTIVELE",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          allAchieved
                              ? "Felicitări! Ai economisit destul pentru toate obiectivele tale! 🎉"
                              : _dailyCost > 0
                                  ? "Trebuie să nu fumezi încă $_totalDaysForAllGoals ${_totalDaysForAllGoals == 1 ? 'zi' : 'zile'} pentru a atinge toate cele ${myGoals.length} obiective"
                                  : "Configurează costul zilnic pentru a calcula zilele necesare",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${(_globalProgressValue * 100).toInt()}% Progres Total",
                              style: TextStyle(
                                color: allAchieved ? Colors.greenAccent : Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "${_baniEconomisiti.toStringAsFixed(1)} / ${_totalGoalsPriceInRon.toStringAsFixed(1)} RON",
                              style: const TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _globalProgressValue,
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              allAchieved ? Colors.greenAccent : const Color(0xFFE53935),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Lista de obiective sau Empty State
                Expanded(
                  child: myGoals.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1A),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF8B0000).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.savings_outlined,
                                    size: 60,
                                    color: Color(0xFF8B0000),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "Niciun obiectiv adăugat încă",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Adaugă lucrurile pe care vrei să le cumperi cu banii pe care îi economisești din renunțarea la fumat!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white54, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: myGoals.length,
                          itemBuilder: (context, index) {
                            return GoalContainer(
                              goal: myGoals[index],
                              currentSavings: _baniEconomisiti,
                              dailyCost: _dailyCost,
                              onDelete: () => _confirmDelete(index),
                            );
                          },
                        ),
                ),

                // Buton Adaugă Obiectiv
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _openAddGoalDialog,
                      icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 22),
                      label: const Text(
                        "ADAUGĂ OBIECTIV NOU",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B0000),
                        elevation: 8,
                        shadowColor: const Color(0xFF8B0000).withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  // Încărcăm datele despre fumat (start time, daily cost)
  void _loadQuitData() async {
    final prefs = await SharedPreferences.getInstance();
    String? startTimeStr = prefs.getString('start_time');
    double? savedDailyCost = prefs.getDouble('daily_cost');

    if (savedDailyCost != null && savedDailyCost > 0) {
      _dailyCost = savedDailyCost;
      _costPerSecond = _dailyCost / 86400;
    }

    if (startTimeStr != null) {
      if (!mounted) return;
      setState(() {
        _startTime = DateTime.parse(startTimeStr);
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startTime != null && _costPerSecond > 0) {
        setState(() {
          int secondsElapsed = DateTime.now().difference(_startTime!).inSeconds;
          _baniEconomisiti = secondsElapsed * _costPerSecond;
        });
      }
    });
  }

  // Salvează obiectivele atât în SharedPreferences cât și în Firestore
  void _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    String encodedData = jsonEncode(myGoals.map((g) => g.toMap()).toList());
    await prefs.setString('saved_goals_list', encodedData);

    final user = authServices.value.currentUser;
    if (user != null) {
      await databaseService.saveGoals(uid: user.uid, goals: myGoals);
    }
  }

  void _openAddGoalDialog() async {
    final Goal? result = await showDialog(
      context: context,
      builder: (context) => const AddGoalsQuestionDialog(),
    );

    if (result != null) {
      setState(() {
        myGoals.add(result);
      });
      _saveGoals();
    }
  }

  void _onDelete(int index) {
    setState(() {
      myGoals.removeAt(index);
    });
    _saveGoals();
  }

  void _loadGoals() async {
    final user = authServices.value.currentUser;
    if (user != null) {
      await databaseService.syncFromFirestoreToLocal(user.uid);
    }

    final prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('saved_goals_list');

    if (!mounted) return;
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

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Șterge Obiectivul",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: const Text(
          "Ești sigur că vrei să elimini acest obiectiv?",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.white70),
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
          ElevatedButton(
            onPressed: () {
              _onDelete(index);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              "Da, șterge",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
