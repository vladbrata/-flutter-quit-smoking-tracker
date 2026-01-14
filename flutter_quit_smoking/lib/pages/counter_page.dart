import 'dart:async';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/pages/start_quit.dart';
import 'package:flutter_quit_smoking/pages/widgets/question_dialog.dart';
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
      body: SafeArea(
        child: Center(
          child: _isStarted
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    const Text(
                      "TIMP FĂRĂ FUMAT",
                      style: TextStyle(color: Colors.white70, letterSpacing: 2),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _formatTime(_secundeScurse),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace', // Arată ca un ceas digital
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

    if (startTimeStr != null && savedDailyCost != null) {
      setState(() {
        DateTime startTime = DateTime.parse(startTimeStr);
        _dailyCost = savedDailyCost;
        _costPerSecunda = _dailyCost / 86400;

        // Calculăm secundele scurse de atunci până ACUM
        _secundeScurse = DateTime.now().difference(startTime).inSeconds;
        // Recalculăm banii economisiți pe baza timpului scurs
        _baniEconomisiti = _secundeScurse * _costPerSecunda;

        _isStarted = true;
      });
      _startTimer();
    } else {
      // Dacă nu avem date, arătăm dialogul de întrebări
      _showSetupDialog();
    }
  }

  void _resetProgression() async {
    // Obținem instanța SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // Ștergem datele
    await prefs.remove('start_time');
    await prefs.remove('daily_cost');

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
}
