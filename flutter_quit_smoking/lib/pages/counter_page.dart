import 'dart:async';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/pages/widgets/question_dialog.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSetupDialog();
    });
  }

  // Funcția care gestionează Dialogul și primirea datelor
  void _showSetupDialog() async {
    final Map<String, double>? result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const QuestionDialog(),
    );

    if (result != null) {
      setState(() {
        // Calculăm costul zilnic (Preț pachet * Pachete pe zi)
        _dailyCost = result['price']! * result['packs']!;

        // Calculăm cât economisești la fiecare secundă
        // (Cost zilnic împărțit la 86400 secunde dintr-o zi)
        _costPerSecunda = _dailyCost / 86400;

        _isStarted = true;
      });

      // După ce avem datele, pornim cronometrul
      _startTimer();
    }
  }

  void _startTimer() {
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
                  ],
                )
              : const CircularProgressIndicator(color: Colors.red),
        ),
      ),
    );
  }
}
