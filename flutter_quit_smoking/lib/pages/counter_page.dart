import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/pages/auth_layout.dart';
import 'package:flutter_quit_smoking/pages/goals_page.dart';
import 'package:flutter_quit_smoking/pages/roadmap_page.dart';
import 'package:flutter_quit_smoking/pages/start_quit.dart';
import 'package:flutter_quit_smoking/services/auth_services.dart';
import 'package:flutter_quit_smoking/services/database_service.dart';
import 'package:flutter_quit_smoking/widgets/add_goal_widget_dialog.dart';
import 'package:flutter_quit_smoking/pages/models/goal_model.dart';
import 'package:flutter_quit_smoking/widgets/health_progress_card.dart';
import 'package:flutter_quit_smoking/widgets/mini_goal_widget.dart';
import 'package:flutter_quit_smoking/widgets/question_dialog.dart';
import 'package:flutter_quit_smoking/widgets/sos_craving_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  Timer? _timer;
  int _secundeScurse = 0;

  // Date utilizator și obiceiuri salvate în Firebase
  String _userName = '';
  String _userEmail = '';
  double _packPrice = 0.0;
  int _cigarettesPerDay = 20;
  double _packsPerDay = 1.0;
  double _dailyCost = 0.0;
  double _costPerSecunda = 0.0;
  double _baniEconomisiti = 0.0;
  int _tigariEvitate = 0;

  Goal? _selectedGoal;
  bool _isStarted = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  void logout() async {
    try {
      await authServices.value.signOut();
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthLayout()),
      (route) => false,
    );
  }

  void _loadSavedData() async {
    final user = authServices.value.currentUser;
    if (user != null) {
      await databaseService.syncFromFirestoreToLocal(user.uid);
      _userName = user.displayName ?? '';
      _userEmail = user.email ?? '';
    }

    final prefs = await SharedPreferences.getInstance();
    String? startTimeStr = prefs.getString('start_time');
    double? savedDailyCost = prefs.getDouble('daily_cost');
    double? savedPackPrice = prefs.getDouble('pack_price');
    int? savedCigs = prefs.getInt('cigarettes_per_day');
    double? savedPacks = prefs.getDouble('packs_per_day');
    String? savedGoalStr = prefs.getString('selected_goal');
    String? savedName = prefs.getString('user_name');
    String? savedEmail = prefs.getString('user_email');

    if (savedName != null && savedName.isNotEmpty) _userName = savedName;
    if (savedEmail != null && savedEmail.isNotEmpty) _userEmail = savedEmail;
    if (savedPackPrice != null) _packPrice = savedPackPrice;
    if (savedCigs != null) _cigarettesPerDay = savedCigs;
    if (savedPacks != null) _packsPerDay = savedPacks;

    if (savedGoalStr != null) {
      try {
        _selectedGoal = Goal.fromMap(jsonDecode(savedGoalStr));
      } catch (_) {}
    }

    if (startTimeStr != null && savedDailyCost != null && savedDailyCost > 0) {
      if (!mounted) return;
      setState(() {
        DateTime startTime = DateTime.parse(startTimeStr);
        _dailyCost = savedDailyCost;
        _costPerSecunda = _dailyCost / 86400;

        _secundeScurse = DateTime.now().difference(startTime).inSeconds;
        _baniEconomisiti = _secundeScurse * _costPerSecunda;
        _tigariEvitate = ((_secundeScurse / 86400.0) * _cigarettesPerDay).floor();
        _isStarted = true;
      });
      _startTimer();
    } else {
      if (!mounted) return;
      _showSetupDialog();
    }
  }

  void _showSetupDialog() async {
    final Map<String, dynamic>? result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuestionDialog(
        initialPrice: _packPrice > 0 ? _packPrice : null,
        initialCigarettesPerDay: _cigarettesPerDay > 0 ? _cigarettesPerDay : null,
      ),
    );

    if (result != null) {
      DateTime now = DateTime.now();
      final double price = (result['packPrice'] as num).toDouble();
      final int cigs = (result['cigarettesPerDay'] as num).toInt();
      final double packs = (result['packsPerDay'] as num).toDouble();
      final double dailyCost = (result['dailyCost'] as num).toDouble();

      setState(() {
        _packPrice = price;
        _cigarettesPerDay = cigs;
        _packsPerDay = packs;
        _dailyCost = dailyCost;
        _costPerSecunda = _dailyCost / 86400;
        _isStarted = true;
        _secundeScurse = 0;
        _baniEconomisiti = 0.0;
        _tigariEvitate = 0;
      });

      _saveQuitData(
        startTime: now,
        packPrice: price,
        cigarettesPerDay: cigs,
        packsPerDay: packs,
        dailyCost: dailyCost,
      );
      _startTimer();
    }
  }

  void _editSmokingHabits() async {
    final Map<String, dynamic>? result = await showDialog(
      context: context,
      builder: (context) => QuestionDialog(
        initialPrice: _packPrice > 0 ? _packPrice : null,
        initialCigarettesPerDay: _cigarettesPerDay > 0 ? _cigarettesPerDay : null,
      ),
    );

    if (result != null) {
      final double price = (result['packPrice'] as num).toDouble();
      final int cigs = (result['cigarettesPerDay'] as num).toInt();
      final double packs = (result['packsPerDay'] as num).toDouble();
      final double dailyCost = (result['dailyCost'] as num).toDouble();

      setState(() {
        _packPrice = price;
        _cigarettesPerDay = cigs;
        _packsPerDay = packs;
        _dailyCost = dailyCost;
        _costPerSecunda = _dailyCost / 86400;
        _baniEconomisiti = _secundeScurse * _costPerSecunda;
        _tigariEvitate = ((_secundeScurse / 86400.0) * _cigarettesPerDay).floor();
      });

      final user = authServices.value.currentUser;
      if (user != null) {
        await databaseService.updateSmokingHabits(
          uid: user.uid,
          packPrice: price,
          cigarettesPerDay: cigs,
          packsPerDay: packs,
          dailyCost: dailyCost,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Obiceiurile de fumat au fost actualizate și salvate în cloud!"),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    }
  }

  void _saveQuitData({
    required DateTime startTime,
    required double packPrice,
    required int cigarettesPerDay,
    required double packsPerDay,
    required double dailyCost,
  }) async {
    final user = authServices.value.currentUser;
    if (user != null) {
      await databaseService.saveQuitData(
        uid: user.uid,
        startTime: startTime,
        packPrice: packPrice,
        cigarettesPerDay: cigarettesPerDay,
        packsPerDay: packsPerDay,
        dailyCost: dailyCost,
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('start_time', startTime.toIso8601String());
      await prefs.setDouble('pack_price', packPrice);
      await prefs.setInt('cigarettes_per_day', cigarettesPerDay);
      await prefs.setDouble('packs_per_day', packsPerDay);
      await prefs.setDouble('daily_cost', dailyCost);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secundeScurse++;
        _baniEconomisiti = _secundeScurse * _costPerSecunda;
        _tigariEvitate = ((_secundeScurse / 86400.0) * _cigarettesPerDay).floor();
      });
    });
  }

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
    _timer?.cancel();
    super.dispose();
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

        if (!allGoals.contains(_selectedGoal)) {
          setState(() {
            _selectedGoal = null;
          });
          await prefs.remove('selected_goal');
          final user = authServices.value.currentUser;
          if (user != null) {
            await databaseService.setSelectedGoal(uid: user.uid, goal: null);
          }
        }
      } else {
        setState(() {
          _selectedGoal = null;
        });
        await prefs.remove('selected_goal');
        final user = authServices.value.currentUser;
        if (user != null) {
          await databaseService.setSelectedGoal(uid: user.uid, goal: null);
        }
      }
    }
  }

  void _confirmResetProgression() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Ai fumat o țigară?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          "Nu te descuraja! Relapsul face parte uneori din proces. Cronometrul va fi resetat pentru a începe din nou cu forțe proaspete.",
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ANULEAZĂ", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetProgression();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              foregroundColor: Colors.white,
            ),
            child: const Text("RESETEAZĂ"),
          ),
        ],
      ),
    );
  }

  void _resetProgression() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('start_time');
    await prefs.remove('selected_goal');

    final user = authServices.value.currentUser;
    if (user != null) {
      await databaseService.resetProgression(user.uid);
    }

    setState(() {
      _timer?.cancel();
      _secundeScurse = 0;
      _isStarted = false;
      _baniEconomisiti = 0;
      _tigariEvitate = 0;
    });

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const StartQuit()),
    );
  }

  void _showEditStartTimeDialog() async {
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

        if (newStartTime.isAfter(DateTime.now())) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Nu poți alege o dată din viitor!"),
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

    final user = authServices.value.currentUser;
    if (user != null) {
      await databaseService.updateStartTime(
        uid: user.uid,
        newStartTime: newStartTime,
      );
    }

    if (!mounted) return;
    setState(() {
      _secundeScurse = DateTime.now().difference(newStartTime).inSeconds;
      _baniEconomisiti = _secundeScurse * _costPerSecunda;
      _tigariEvitate = ((_secundeScurse / 86400.0) * _cigarettesPerDay).floor();
    });
  }

  void _openSosCravingDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const SosCravingDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF121212),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Drawer Header cu datele utilizatorului conectat
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xFF8B0000),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.smoke_free, color: Colors.white, size: 36),
                        SizedBox(width: 10),
                        Text(
                          "Quit Smoking",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _userName.isNotEmpty ? _userName : "Cont Utilizator",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _userEmail.isNotEmpty ? _userEmail : "Sincronizat cu Firebase",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_packPrice > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        "${_packPrice.toStringAsFixed(1)} RON/pachet | $_cigarettesPerDay țigări/zi (${_packsPerDay.toStringAsFixed(1)} pach)",
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),

              ListTile(
                leading: const Icon(Icons.air_rounded, color: Color(0xFFFF5252)),
                title: const Text(
                  "SOS Craving",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  "Exerciții de respirație pentru pofte",
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _openSosCravingDialog();
                },
              ),

              const Divider(color: Colors.white10),

              ListTile(
                leading: const Icon(Icons.attach_money_sharp, color: Colors.grey),
                title: const Text("Obiective Financiare", style: TextStyle(color: Colors.white)),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GoalsPage()),
                  );
                  _verifySelectedGoal();
                },
              ),

              ListTile(
                leading: const Icon(Icons.timeline, color: Colors.grey),
                title: const Text("Traseu Sănătate (Roadmap)", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RoadmapPage()),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.tune, color: Colors.grey),
                title: const Text("Editează Obiceiuri Fumat", style: TextStyle(color: Colors.white)),
                subtitle: const Text("Schimbă preț pachet și țigări/zi", style: TextStyle(color: Colors.white38, fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  _editSmokingHabits();
                },
              ),

              const Divider(color: Colors.white10),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white38),
                title: const Text("Deconectare", style: TextStyle(color: Colors.white38)),
                onTap: () => logout(),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Quit Smoking",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "SOS Craving - Exerciții de Respirație",
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF8B0000).withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFF5252), width: 1.2),
              ),
              child: const Icon(Icons.air_rounded, color: Color(0xFFFF5252), size: 18),
            ),
            onPressed: _openSosCravingDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: _isStarted
                ? SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Cardul Obiectiv Activ
                        _buildGoalSection(),
                        const SizedBox(height: 16),

                        // Hero Stat Card: Timp Fără Fumat
                        _buildTimerCard(),
                        const SizedBox(height: 16),

                        // Grid 2 Coloane: Economii și Țigări Evitate
                        _buildStatsGrid(),
                        const SizedBox(height: 16),

                        // Container Progres Sănătate (Plămâni interactivi din Roadmap)
                        HealthProgressCard(
                          timeElapsed: Duration(seconds: _secundeScurse),
                        ),
                        const SizedBox(height: 16),

                        // Buton SOS Craving Card
                        _buildSosLifelineCard(),
                        const SizedBox(height: 16),

                        // Butoane Navigare Rapidă
                        _buildQuickNavigationRow(),
                        const SizedBox(height: 24),

                        // Buton Reset Progresie
                        Center(
                          child: TextButton.icon(
                            onPressed: _confirmResetProgression,
                            icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white38),
                            label: const Text(
                              "Am fumat o țigară (resetează progresul)",
                              style: TextStyle(color: Colors.white38, fontSize: 12.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(color: Color(0xFF8B0000)),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalSection() {
    if (_selectedGoal != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () async {
          final result = await showDialog(
            context: context,
            builder: (context) => AddGoalWidgetDialog(
              selectedGoal: _selectedGoal,
            ),
          );
          if (result == 'CLEAR') {
            final user = authServices.value.currentUser;
            if (user != null) {
              await databaseService.setSelectedGoal(uid: user.uid, goal: null);
            }
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('selected_goal');
            setState(() {
              _selectedGoal = null;
            });
          } else if (result != null && result is Goal) {
            final user = authServices.value.currentUser;
            if (user != null) {
              await databaseService.setSelectedGoal(uid: user.uid, goal: result);
            }
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('selected_goal', jsonEncode(result.toMap()));
            setState(() {
              _selectedGoal = result;
            });
          }
        },
        child: MiniGoalWidget(
          goal: _selectedGoal!,
          currentSavings: _baniEconomisiti,
          dailyCost: _dailyCost,
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF221114),
            Color(0xFF131316),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF8B0000).withValues(alpha: 0.5),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B0000).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            final result = await showDialog(
              context: context,
              builder: (context) => const AddGoalWidgetDialog(),
            );
            if (result != null && result is Goal) {
              final user = authServices.value.currentUser;
              if (user != null) {
                await databaseService.setSelectedGoal(uid: user.uid, goal: result);
              }
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('selected_goal', jsonEncode(result.toMap()));
              setState(() {
                _selectedGoal = result;
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B0000).withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    color: Color(0xFFFFB300),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Setează un Obiectiv Financiar",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Atinge pentru a alege ce cumperi din economii",
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.add_circle_outline_rounded,
                  color: Color(0xFFFFB300),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF221114),
            Color(0xFF131316),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF8B0000).withValues(alpha: 0.5),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B0000).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Tooltip(
          message: "Apasă lung pentru a ajusta data/ora de start",
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onLongPress: _showEditStartTimeDialog,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B0000).withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.timer_outlined,
                          color: Color(0xFFFF5252),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "TIMP FĂRĂ FUMAT",
                        style: TextStyle(
                          color: Colors.white70,
                          letterSpacing: 2.0,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _formatTime(_secundeScurse),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(color: Color(0xFF8B0000), blurRadius: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.touch_app_outlined, size: 13, color: Colors.white38),
                      SizedBox(width: 4),
                      Text(
                        "Apasă lung pentru a edita data de start",
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        // Card Bani Economisiți
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF151518),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.greenAccent.withValues(alpha: 0.25),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.savings_rounded,
                        color: Colors.greenAccent,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "ECONOMII",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "${_baniEconomisiti.toStringAsFixed(2)} RON",
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: Colors.greenAccent, blurRadius: 10),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dailyCost > 0 ? "${_dailyCost.toStringAsFixed(1)} RON / zi" : "Configurat",
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Card Țigări Evitate
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF151518),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF5252).withValues(alpha: 0.25),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.smoke_free_rounded,
                        color: Color(0xFFFF5252),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "EVITATE",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "$_tigariEvitate",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "țigări nefumate",
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSosLifelineCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E0C10),
            Color(0xFF1A090B),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFF5252).withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B0000).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: _openSosCravingDialog,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B0000),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5252).withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.air_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AI O POFTĂ? RESPIRĂ (SOS)",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Exerciții de respirație ghidate pentru depășirea poftei",
                        style: TextStyle(color: Colors.white70, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white54,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickNavigationRow() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GoalsPage()),
              );
              _verifySelectedGoal();
            },
            icon: const Icon(Icons.savings_outlined, color: Colors.white70, size: 18),
            label: const Text(
              "Obiective",
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Colors.white12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: const Color(0xFF16161A),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RoadmapPage()),
              );
            },
            icon: const Icon(Icons.timeline, color: Colors.white70, size: 18),
            label: const Text(
              "Sănătate",
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Colors.white12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: const Color(0xFF16161A),
            ),
          ),
        ),
      ],
    );
  }
}
