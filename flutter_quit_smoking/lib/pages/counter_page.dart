import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/pages/auth_layout.dart';
import 'package:flutter_quit_smoking/pages/goals_page.dart';
import 'package:flutter_quit_smoking/pages/models/health_milestone_model.dart';
import 'package:flutter_quit_smoking/pages/roadmap_page.dart';
import 'package:flutter_quit_smoking/pages/start_quit.dart';
import 'package:flutter_quit_smoking/services/auth_services.dart';
import 'package:flutter_quit_smoking/services/database_service.dart';
import 'package:flutter_quit_smoking/services/gemini_service.dart';
import 'package:flutter_quit_smoking/widgets/add_goal_widget_dialog.dart';
import 'package:flutter_quit_smoking/pages/models/goal_model.dart';
import 'package:flutter_quit_smoking/widgets/ai_routine_advice_card.dart';
import 'package:flutter_quit_smoking/widgets/health_progress_card.dart';
import 'package:flutter_quit_smoking/widgets/mini_goal_widget.dart';
import 'package:flutter_quit_smoking/widgets/question_dialog.dart';
import 'package:flutter_quit_smoking/widgets/skeleton_loader.dart';
import 'package:flutter_quit_smoking/widgets/relapse_capture_dialog.dart';
import 'package:flutter_quit_smoking/widgets/craving_capture_dialog.dart';
import 'package:flutter_quit_smoking/widgets/craving_relapse_history_dialog.dart';
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
  String _smokingRoutine = '';

  Goal? _selectedGoal;
  bool _isStarted = false;
  int _aiAdviceRefreshCount = 0;

  // Stări de încărcare pentru fiecare container (Skeleton Loading progresiv)
  bool _isGoalLoading = true;
  bool _isTimerLoading = true;
  bool _isStatsLoading = true;
  bool _isHealthLoading = true;
  bool _isAiAdviceLoading = true;

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
    // 1. Inițiem sincronizarea din Firestore în fundal (non-blocantă)
    final user = authServices.value.currentUser;
    if (user != null) {
      _userName = user.displayName ?? '';
      _userEmail = user.email ?? '';
      databaseService.syncFromFirestoreToLocal(user.uid).then((_) async {
        if (!mounted) return;
        final p = await SharedPreferences.getInstance();
        final n = p.getString('user_name');
        final e = p.getString('user_email');
        if (mounted && (n != null || e != null)) {
          setState(() {
            if (n != null && n.isNotEmpty) _userName = n;
            if (e != null && e.isNotEmpty) _userEmail = e;
          });
        }
      });
    }

    // 2. Citim din stocarea locală SharedPreferences rapid
    final prefs = await SharedPreferences.getInstance();
    final String? startTimeStr = prefs.getString('start_time');
    final double? savedDailyCost = prefs.getDouble('daily_cost');
    final double? savedPackPrice = prefs.getDouble('pack_price');
    final int? savedCigs = prefs.getInt('cigarettes_per_day');
    final double? savedPacks = prefs.getDouble('packs_per_day');
    final String? savedGoalStr = prefs.getString('selected_goal');
    final String? savedName = prefs.getString('user_name');
    final String? savedEmail = prefs.getString('user_email');
    final String? savedRoutine = prefs.getString('smoking_routine');

    if (savedName != null && savedName.isNotEmpty) _userName = savedName;
    if (savedEmail != null && savedEmail.isNotEmpty) _userEmail = savedEmail;
    if (savedPackPrice != null) _packPrice = savedPackPrice;
    if (savedCigs != null) _cigarettesPerDay = savedCigs;
    if (savedPacks != null) _packsPerDay = savedPacks;
    if (savedRoutine != null && savedRoutine.isNotEmpty) _smokingRoutine = savedRoutine;

    // Dacă utilizatorul nu are încă setată o dată de start sau costuri, deschidem dialogul
    if (startTimeStr == null || savedDailyCost == null || savedDailyCost <= 0) {
      if (!mounted) return;
      setState(() {
        _isGoalLoading = false;
        _isTimerLoading = false;
        _isStatsLoading = false;
        _isHealthLoading = false;
        _isAiAdviceLoading = false;
      });
      _showSetupDialog();
      return;
    }

    final DateTime startTime = DateTime.parse(startTimeStr);
    final double dailyCost = savedDailyCost;
    final double costPerSec = dailyCost / 86400;

    // --- ETAPA 1: CRONOMETRUL TIMP FĂRĂ FUMAT ---
    // Se deblochează primul pentru a oferi confirmare vizuală instantanee
    await Future.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;
    setState(() {
      _dailyCost = dailyCost;
      _costPerSecunda = costPerSec;
      _secundeScurse = DateTime.now().difference(startTime).inSeconds;
      _isStarted = true;
      _isTimerLoading = false;
    });
    _startTimer();

    // --- ETAPA 2: STATISTICI (Economii & Țigări Evitate) ---
    // Se populează al doilea container
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    setState(() {
      _baniEconomisiti = _secundeScurse * _costPerSecunda;
      _tigariEvitate = ((_secundeScurse / 86400.0) * _cigarettesPerDay).floor();
      _isStatsLoading = false;
    });

    // --- ETAPA 3: CONTAINER SĂNĂTATE (Plămânii din Roadmap) ---
    // Se populează al treilea container
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    setState(() {
      _isHealthLoading = false;
    });

    // --- ETAPA 4: SFATURI INTELIGENTE RUTINĂ (Gemini AI) ---
    // Se populează al patrulea container
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    setState(() {
      _isAiAdviceLoading = false;
    });

    // --- ETAPA 5: CARD OBIECTIV ACTIV ---
    // Se populează ultimul container
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    if (savedGoalStr != null) {
      try {
        _selectedGoal = Goal.fromMap(jsonDecode(savedGoalStr));
      } catch (_) {}
    }
    setState(() {
      _isGoalLoading = false;
    });
  }

  void _showSetupDialog() async {
    final Map<String, dynamic>? result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuestionDialog(
        initialPrice: _packPrice > 0 ? _packPrice : null,
        initialCigarettesPerDay: _cigarettesPerDay > 0 ? _cigarettesPerDay : null,
        initialSmokingRoutine: _smokingRoutine.isNotEmpty ? _smokingRoutine : null,
      ),
    );

    if (result != null) {
      DateTime now = DateTime.now();
      final double price = (result['packPrice'] as num).toDouble();
      final int cigs = (result['cigarettesPerDay'] as num).toInt();
      final double packs = (result['packsPerDay'] as num).toDouble();
      final double dailyCost = (result['dailyCost'] as num).toDouble();
      final String routine = (result['smokingRoutine'] as String?) ?? '';

      setState(() {
        _packPrice = price;
        _cigarettesPerDay = cigs;
        _packsPerDay = packs;
        _dailyCost = dailyCost;
        _smokingRoutine = routine;
        _costPerSecunda = _dailyCost / 86400;
        _isStarted = true;
        _secundeScurse = 0;
        _baniEconomisiti = 0.0;
        _tigariEvitate = 0;
        _isGoalLoading = false;
        _isTimerLoading = false;
        _isStatsLoading = false;
        _isHealthLoading = false;
      });

      _saveQuitData(
        startTime: now,
        packPrice: price,
        cigarettesPerDay: cigs,
        packsPerDay: packs,
        dailyCost: dailyCost,
        smokingRoutine: routine,
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
        initialSmokingRoutine: _smokingRoutine.isNotEmpty ? _smokingRoutine : null,
      ),
    );

    if (result != null) {
      final double price = (result['packPrice'] as num).toDouble();
      final int cigs = (result['cigarettesPerDay'] as num).toInt();
      final double packs = (result['packsPerDay'] as num).toDouble();
      final double dailyCost = (result['dailyCost'] as num).toDouble();
      final String routine = (result['smokingRoutine'] as String?) ?? '';

      setState(() {
        _packPrice = price;
        _cigarettesPerDay = cigs;
        _packsPerDay = packs;
        _dailyCost = dailyCost;
        _smokingRoutine = routine;
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
          smokingRoutine: routine,
        );
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('smoking_routine', routine);
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
    String? smokingRoutine,
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
        smokingRoutine: smokingRoutine,
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('start_time', startTime.toIso8601String());
      await prefs.setDouble('pack_price', packPrice);
      await prefs.setInt('cigarettes_per_day', cigarettesPerDay);
      await prefs.setDouble('packs_per_day', packsPerDay);
      await prefs.setDouble('daily_cost', dailyCost);
      if (smokingRoutine != null) {
        await prefs.setString('smoking_routine', smokingRoutine);
      }
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
            _aiAdviceRefreshCount++;
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
          _aiAdviceRefreshCount++;
        });
        await prefs.remove('selected_goal');
        final user = authServices.value.currentUser;
        if (user != null) {
          await databaseService.setSelectedGoal(uid: user.uid, goal: null);
        }
      }
    }
  }

  void _confirmResetProgression() async {
    final RelapseResult? result = await showDialog<RelapseResult>(
      context: context,
      barrierDismissible: true,
      builder: (context) => RelapseCaptureDialog(
        smokeFreeDurationSeconds: _secundeScurse,
      ),
    );

    if (result != null) {
      final user = authServices.value.currentUser;

      // 1. Salvează evenimentul de relapse în baza de date (local + cloud)
      await databaseService.saveRelapseEvent(
        uid: user?.uid,
        relapse: result.relapseEvent,
      );

      // 2. În funcție de opțiunea utilizatorului:
      if (result.restartImmediately) {
        // Repornește imediat de la data/ora selectată
        await _onRestartFromRelapse(result.newStartTime);
      } else {
        // Resetează complet progresul și navighează la ecranul de reluare
        _resetProgression();
      }
    }
  }

  Future<void> _onRestartFromRelapse(DateTime newStart) async {
    final user = authServices.value.currentUser;
    if (user != null) {
      await databaseService.updateStartTime(
        uid: user.uid,
        newStartTime: newStart,
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('start_time', newStart.toIso8601String());
    }

    final int newSeconds = DateTime.now().difference(newStart).inSeconds.clamp(0, 999999999);
    setState(() {
      _secundeScurse = newSeconds;
      _baniEconomisiti = _secundeScurse * _costPerSecunda;
      _tigariEvitate = ((_secundeScurse / 86400.0) * _cigarettesPerDay).floor();
      _aiAdviceRefreshCount++;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Informațiile despre relapse au fost salvate. AI-ul a învățat din acest moment!",
        ),
        backgroundColor: Color(0xFFE11D48),
        duration: Duration(seconds: 4),
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
      _isGoalLoading = true;
      _isTimerLoading = true;
      _isStatsLoading = true;
      _isHealthLoading = true;
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

  void _openSosCravingDialog({bool captureReasonFirst = true}) async {
    String? cravingId;

    if (captureReasonFirst) {
      final captureResult = await showDialog<CravingCaptureResult>(
        context: context,
        barrierDismissible: true,
        builder: (context) => const CravingCaptureDialog(),
      );

      if (captureResult == null) return;
      cravingId = captureResult.craving.id;

      if (!captureResult.startBreathing) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Pofta de la ora ${captureResult.craving.formattedTime} a fost salvată în baza de date! AI-ul o va analiza.",
            ),
            backgroundColor: const Color(0xFFE11D48),
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _aiAdviceRefreshCount++;
        });
        return;
      }
    }

    final nextMs = HealthMilestoneService.getNextMilestone(Duration(seconds: _secundeScurse));
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => SosCravingDialog(
        timeElapsed: Duration(seconds: _secundeScurse),
        cigarettesAvoided: _tigariEvitate,
        moneySaved: _baniEconomisiti,
        smokingRoutine: _smokingRoutine,
        nextMilestone: nextMs?.title ?? '',
        selectedGoal: _selectedGoal,
        dailyCost: _dailyCost,
        cravingId: cravingId,
        onSessionFinished: () {
          if (mounted) {
            setState(() {
              _aiAdviceRefreshCount++;
            });
          }
        },
      ),
    );
    if (mounted) {
      setState(() {
        _aiAdviceRefreshCount++;
      });
    }
  }

  void _showApiKeyDialog() async {
    final currentKey = await geminiService.getApiKey() ?? '';
    final controller = TextEditingController(text: currentKey);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.auto_awesome_rounded, color: Color(0xFFBA68C8), size: 22),
              SizedBox(width: 8),
              Text(
                "Cheie Gemini API",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Introdu cheia ta API Google Gemini pentru generarea dinamică a sfaturilor personalizate. Este salvată doar pe dispozitivul tău.",
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "AIzaSy...",
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFBA68C8)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Notă: Aplicația funcționează perfect și fără cheie, folosind motorul inteligent de fallback local.",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            if (currentKey.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await geminiService.clearApiKey();
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  setState(() {});
                },
                child: const Text("Șterge", style: TextStyle(color: Colors.redAccent)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("Anulează", style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () async {
                await geminiService.setApiKey(controller.text);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "Salvează",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF101013),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Drawer Header cu datele utilizatorului conectat
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xFF16161A),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.smoke_free, color: Colors.white, size: 28),
                        SizedBox(width: 10),
                        Text(
                          "Quit Smoking",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _userEmail.isNotEmpty ? _userEmail : "Sincronizat cu Firebase",
                      style: const TextStyle(
                        color: Color(0xFFA1A1AA),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_packPrice > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        "${_packPrice.toStringAsFixed(1)} RON/pachet | $_cigarettesPerDay țigări/zi (${_packsPerDay.toStringAsFixed(1)} pach)",
                        style: const TextStyle(color: Color(0xFF71717A), fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),

              ListTile(
                leading: const Icon(Icons.air_rounded, color: Color(0xFFFB7185), size: 20),
                title: const Text(
                  "SOS Craving",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  "Exerciții de respirație pentru pofte",
                  style: TextStyle(color: Color(0xFF71717A), fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _openSosCravingDialog();
                },
              ),

              ListTile(
                leading: const Icon(Icons.history_edu_rounded, color: Color(0xFFFB7185), size: 20),
                title: const Text(
                  "Jurnal Pofte & Recidive",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  "Orele salvate în baza de date & tipare AI",
                  style: TextStyle(color: Color(0xFF71717A), fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => const CravingRelapseHistoryDialog(),
                  );
                },
              ),

              const Divider(color: Colors.white10),

              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Color(0xFFA1A1AA), size: 20),
                title: const Text("Obiective Financiare", style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GoalsPage()),
                  );
                  _verifySelectedGoal();
                },
              ),

              ListTile(
                leading: const Icon(Icons.timeline, color: Color(0xFFA1A1AA), size: 20),
                title: const Text("Traseu Sănătate (Roadmap)", style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RoadmapPage()),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.tune, color: Color(0xFFA1A1AA), size: 20),
                title: const Text("Editează Obiceiuri Fumat", style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text("Schimbă preț pachet, țigări/zi și rutină", style: TextStyle(color: Color(0xFF71717A), fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  _editSmokingHabits();
                },
              ),

              ListTile(
                leading: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFA1A1AA), size: 20),
                title: const Text("Cheie Gemini API (Opțional)", style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text("Pentru sfaturi generate dinamic cu AI", style: TextStyle(color: Color(0xFF71717A), fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  _showApiKeyDialog();
                },
              ),

              const Divider(color: Colors.white10),

              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFF71717A), size: 20),
                title: const Text("Deconectare", style: TextStyle(color: Color(0xFF71717A), fontSize: 14)),
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: Color(0xFFFAFAFA),
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _openSosCravingDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE11D48).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE11D48).withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.air_rounded, color: Color(0xFFFB7185), size: 14),
                    SizedBox(width: 4),
                    Text(
                      "SOS",
                      style: TextStyle(
                        color: Color(0xFFFB7185),
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cardul Obiectiv Activ (Skeleton sau Conținut)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: _isGoalLoading
                        ? const SkeletonGoalCard(key: ValueKey('sk_goal'))
                        : KeyedSubtree(
                            key: const ValueKey('loaded_goal'),
                            child: _buildGoalSection(),
                          ),
                  ),
                  const SizedBox(height: 14),

                  // Hero Stat Card: Timp Fără Fumat (Skeleton sau Conținut)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: _isTimerLoading
                        ? const SkeletonTimerCard(key: ValueKey('sk_timer'))
                        : KeyedSubtree(
                            key: const ValueKey('loaded_timer'),
                            child: _buildTimerCard(),
                          ),
                  ),
                  const SizedBox(height: 14),

                  // Grid 2 Coloane: Economii și Țigări Evitate (Skeleton sau Conținut)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: _isStatsLoading
                        ? const SkeletonStatsGrid(key: ValueKey('sk_stats'))
                        : KeyedSubtree(
                            key: const ValueKey('loaded_stats'),
                            child: _buildStatsGrid(),
                          ),
                  ),
                  const SizedBox(height: 14),

                  // Container Progres Sănătate (Plămâni interactivi din Roadmap)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: _isHealthLoading
                        ? const SkeletonHealthCard(key: ValueKey('sk_health'))
                        : KeyedSubtree(
                            key: const ValueKey('loaded_health'),
                            child: HealthProgressCard(
                              timeElapsed: Duration(seconds: _secundeScurse),
                            ),
                          ),
                  ),
                  const SizedBox(height: 14),

                  // Sfat Inteligent Personalizat Rutină (Gemini AI)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: _isAiAdviceLoading
                        ? const SkeletonAiAdviceCard(key: ValueKey('sk_ai_advice'))
                        : KeyedSubtree(
                            key: const ValueKey('loaded_ai_advice'),
                            child: AiRoutineAdviceCard(
                              routine: _smokingRoutine,
                              timeElapsed: Duration(seconds: _secundeScurse),
                              cigarettesAvoided: _tigariEvitate,
                              moneySaved: _baniEconomisiti,
                              dailyCost: _dailyCost,
                              selectedGoal: _selectedGoal,
                              refreshTrigger: _aiAdviceRefreshCount,
                              onConfigureRoutine: _editSmokingHabits,
                              onOpenSos: _openSosCravingDialog,
                            ),
                          ),
                  ),
                  const SizedBox(height: 14),

                  // Buton SOS Craving Card
                  _buildSosLifelineCard(),
                  const SizedBox(height: 14),

                  // Butoane Navigare Rapidă
                  _buildQuickNavigationRow(),
                  const SizedBox(height: 20),

                  // Buton Reset Progresie
                  if (_isStarted) ...[
                    Center(
                      child: TextButton.icon(
                        onPressed: _confirmResetProgression,
                        icon: const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF71717A)),
                        label: const Text(
                          "Resetează progresul",
                          style: TextStyle(color: Color(0xFF71717A), fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalSection() {
    if (_selectedGoal != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
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
              _aiAdviceRefreshCount++;
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
              _aiAdviceRefreshCount++;
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
        color: const Color(0xFF121215),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
                _aiAdviceRefreshCount++;
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.flag_outlined,
                    color: Color(0xFFD4D4D8),
                    size: 14,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Setează un Obiectiv Financiar",
                        style: TextStyle(
                          color: Color(0xFFFAFAFA),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Asociază economiile cu o recompensă concretă",
                        style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.add_rounded,
                  color: Color(0xFFA1A1AA),
                  size: 18,
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
        color: const Color(0xFF121215),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Tooltip(
          message: "Apasă lung pentru a ajusta data/ora de start",
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onLongPress: _showEditStartTimeDialog,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.timer_outlined,
                          color: Color(0xFFD4D4D8),
                          size: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "TIMP FĂRĂ FUMAT",
                        style: TextStyle(
                          color: Color(0xFFA1A1AA),
                          letterSpacing: 1.2,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatTime(_secundeScurse),
                    style: const TextStyle(
                      color: Color(0xFFFAFAFA),
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Apasă lung pentru a edita data de start",
                    style: TextStyle(color: Color(0xFF71717A), fontSize: 11),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF121215),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.07),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
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
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.savings_outlined,
                        color: Color(0xFF34D399),
                        size: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "ECONOMII",
                      style: TextStyle(
                        color: Color(0xFFA1A1AA),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "${_baniEconomisiti.toStringAsFixed(2)} RON",
                  style: const TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dailyCost > 0 ? "${_dailyCost.toStringAsFixed(1)} RON / zi" : "Configurat",
                  style: const TextStyle(color: Color(0xFF71717A), fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Card Țigări Evitate
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF121215),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.07),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
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
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.smoke_free_outlined,
                        color: Color(0xFFD4D4D8),
                        size: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "EVITATE",
                      style: TextStyle(
                        color: Color(0xFFA1A1AA),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "$_tigariEvitate",
                  style: const TextStyle(
                    color: Color(0xFFFAFAFA),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "țigări nefumate",
                  style: TextStyle(color: Color(0xFF71717A), fontSize: 11),
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
        color: const Color(0xFF161215),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE11D48).withValues(alpha: 0.25),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _openSosCravingDialog,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.air_rounded,
                    color: Color(0xFFFB7185),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ai o poftă? Înregistrează și Respiră (SOS)",
                        style: TextStyle(
                          color: Color(0xFFFAFAFA),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Scrie de ce ai poftă și calmează impulsul în 3 minute",
                        style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF71717A),
                  size: 12,
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
            icon: const Icon(Icons.flag_outlined, color: Color(0xFFD4D4D8), size: 15),
            label: const Text(
              "Obiective",
              style: TextStyle(color: Color(0xFFD4D4D8), fontSize: 12.5, fontWeight: FontWeight.w500),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 11),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: const Color(0xFF121215),
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
            icon: const Icon(Icons.timeline, color: Color(0xFFD4D4D8), size: 15),
            label: const Text(
              "Sănătate",
              style: TextStyle(color: Color(0xFFD4D4D8), fontSize: 12.5, fontWeight: FontWeight.w500),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 11),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: const Color(0xFF121215),
            ),
          ),
        ),
      ],
    );
  }
}
