import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/services/gemini_service.dart';

enum BreathingTechnique {
  boxBreathing, // 4-4-4-4
  relax478, // 4-7-8
}

enum BreathingPhase {
  inhale,
  holdIn,
  exhale,
  holdOut,
}

class SosCravingDialog extends StatefulWidget {
  final Duration? timeElapsed;
  final int? cigarettesAvoided;
  final double? moneySaved;
  final String? smokingRoutine;
  final String? nextMilestone;

  const SosCravingDialog({
    super.key,
    this.timeElapsed,
    this.cigarettesAvoided,
    this.moneySaved,
    this.smokingRoutine,
    this.nextMilestone,
  });

  @override
  State<SosCravingDialog> createState() => _SosCravingDialogState();
}

class _SosCravingDialogState extends State<SosCravingDialog>
    with SingleTickerProviderStateMixin {
  BreathingTechnique _technique = BreathingTechnique.boxBreathing;
  BreathingPhase _currentPhase = BreathingPhase.inhale;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  Timer? _phaseTimer;
  int _secondsLeftInPhase = 4;
  int _currentCycle = 1;
  final int _targetCycles = 4;

  bool _isCompleted = false;
  bool _isPaused = false;

  List<String> _cravingTips = [
    "Un craving fizic intens atinge vârful în circa 3 minute, după care scade treptat.",
    "Bea un pahar plin cu apă rece. Îți resetează atenția și hidratează corpul.",
    "Schimbă mediul fizic în care te afli pentru 5 minute (ieși la aer sau mergi într-o altă cameră).",
    "Fiecare poftă refuzată reconfigurează căile neuronale spre libertate completă.",
  ];
  int _currentTipIndex = 0;
  bool _isAiGenerated = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.18).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
    );

    _startPhase(BreathingPhase.inhale);
    _loadPersonalizedTips();
  }

  void _loadPersonalizedTips() async {
    try {
      final tips = await geminiService.getCravingTips(
        timeElapsed: widget.timeElapsed ?? Duration.zero,
        cigarettesAvoided: widget.cigarettesAvoided ?? 0,
        moneySaved: widget.moneySaved ?? 0.0,
        routine: widget.smokingRoutine ?? '',
        nextMilestone: widget.nextMilestone ?? '',
      );
      if (mounted && tips.isNotEmpty) {
        setState(() {
          _cravingTips = tips;
          _currentTipIndex = 0;
          _isAiGenerated = true;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  int _getPhaseDuration(BreathingPhase phase) {
    if (_technique == BreathingTechnique.boxBreathing) {
      return 4;
    } else {
      switch (phase) {
        case BreathingPhase.inhale:
          return 4;
        case BreathingPhase.holdIn:
          return 7;
        case BreathingPhase.exhale:
          return 8;
        case BreathingPhase.holdOut:
          return 0; // Nu are holdOut în tehnica 4-7-8
      }
    }
  }

  void _startPhase(BreathingPhase phase) {
    _phaseTimer?.cancel();
    final duration = _getPhaseDuration(phase);

    if (duration == 0) {
      _advanceToNextPhase();
      return;
    }

    setState(() {
      _currentPhase = phase;
      _secondsLeftInPhase = duration;
    });

    _animController.duration = Duration(seconds: duration);

    if (phase == BreathingPhase.inhale) {
      _animController.forward(from: 0.0);
    } else if (phase == BreathingPhase.exhale) {
      _animController.reverse(from: 1.0);
    } else {
      // Menține dimensiunea stabilă cu o respirație lentă
    }

    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;

      if (_secondsLeftInPhase > 1) {
        setState(() {
          _secondsLeftInPhase--;
        });
      } else {
        timer.cancel();
        _advanceToNextPhase();
      }
    });
  }

  void _advanceToNextPhase() {
    BreathingPhase nextPhase;
    int nextCycle = _currentCycle;

    if (_technique == BreathingTechnique.boxBreathing) {
      switch (_currentPhase) {
        case BreathingPhase.inhale:
          nextPhase = BreathingPhase.holdIn;
          break;
        case BreathingPhase.holdIn:
          nextPhase = BreathingPhase.exhale;
          break;
        case BreathingPhase.exhale:
          nextPhase = BreathingPhase.holdOut;
          break;
        case BreathingPhase.holdOut:
          nextPhase = BreathingPhase.inhale;
          nextCycle++;
          break;
      }
    } else {
      // Tehnica 4-7-8
      switch (_currentPhase) {
        case BreathingPhase.inhale:
          nextPhase = BreathingPhase.holdIn;
          break;
        case BreathingPhase.holdIn:
          nextPhase = BreathingPhase.exhale;
          break;
        case BreathingPhase.exhale:
        case BreathingPhase.holdOut:
          nextPhase = BreathingPhase.inhale;
          nextCycle++;
          break;
      }
    }

    if (nextCycle > _targetCycles) {
      _phaseTimer?.cancel();
      setState(() {
        _isCompleted = true;
      });
    } else {
      setState(() {
        _currentCycle = nextCycle;
        _currentTipIndex = (_currentTipIndex + 1) % _cravingTips.length;
      });
      _startPhase(nextPhase);
    }
  }

  void _switchTechnique(BreathingTechnique technique) {
    if (_technique == technique) return;
    setState(() {
      _technique = technique;
      _currentCycle = 1;
    });
    _startPhase(BreathingPhase.inhale);
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _animController.stop();
      } else {
        if (_currentPhase == BreathingPhase.inhale) {
          _animController.forward();
        } else if (_currentPhase == BreathingPhase.exhale) {
          _animController.reverse();
        }
      }
    });
  }

  String get _phaseTitle {
    switch (_currentPhase) {
      case BreathingPhase.inhale:
        return "INSPIRĂ";
      case BreathingPhase.holdIn:
        return "ȚINE";
      case BreathingPhase.exhale:
        return "EXPIRĂ";
      case BreathingPhase.holdOut:
        return "PAUZĂ";
    }
  }

  String get _phaseSubtitle {
    switch (_currentPhase) {
      case BreathingPhase.inhale:
        return "Lent și adânc pe nas...";
      case BreathingPhase.holdIn:
        return "Menține aerul în piept, relaxează umerii...";
      case BreathingPhase.exhale:
        return "Elimină tot aerul prelung pe gură...";
      case BreathingPhase.holdOut:
        return "Rămâi calm înainte de următorul inspir...";
    }
  }

  Color get _phaseColor {
    switch (_currentPhase) {
      case BreathingPhase.inhale:
        return const Color(0xFF00E676); // Verde vitalitate
      case BreathingPhase.holdIn:
        return const Color(0xFFFFB300); // Chihlimbar calm
      case BreathingPhase.exhale:
        return const Color(0xFF29B6F6); // Albastru destindere
      case BreathingPhase.holdOut:
        return const Color(0xFFBA68C8); // Violet pauză
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF141416),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFF8B0000).withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B0000).withValues(alpha: 0.35),
                  blurRadius: 36,
                  spreadRadius: 4,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                child: _isCompleted ? _buildCompletedView() : _buildActiveView(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header cu titlu SOS & Închidere
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B0000).withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.air_rounded,
                      color: Color(0xFFFF5252),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SOS CRAVING",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "Respiră și recapătă controlul",
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: "Închide",
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Selector Tehnică Respirație
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTabButton(
                  title: "Box (4-4-4-4)",
                  isSelected: _technique == BreathingTechnique.boxBreathing,
                  onTap: () => _switchTechnique(BreathingTechnique.boxBreathing),
                ),
              ),
              Expanded(
                child: _buildTabButton(
                  title: "Relaxare (4-7-8)",
                  isSelected: _technique == BreathingTechnique.relax478,
                  onTap: () => _switchTechnique(BreathingTechnique.relax478),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Cercul Animat de Respirație
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            final scale = _scaleAnimation.value;
            return SizedBox(
              height: 180,
              width: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Cercul exterior radiant (glow)
                  Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _phaseColor.withValues(alpha: 0.35),
                            _phaseColor.withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                          stops: const [0.4, 0.75, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Cercul principal
                  Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _phaseColor.withValues(alpha: 0.28),
                            const Color(0xFF1E1E24),
                          ],
                        ),
                        border: Border.all(
                          color: _phaseColor.withValues(alpha: 0.8),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _phaseColor.withValues(alpha: 0.4),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Conținut text în cerc (Secunde & Titlu Fază)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$_secondsLeftInPhase",
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: _phaseColor,
                          height: 1.0,
                          shadows: [
                            Shadow(
                              color: _phaseColor.withValues(alpha: 0.6),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _phaseTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 14),

        // Subtitlu fază de respirație
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _phaseSubtitle,
            key: ValueKey<String>(_phaseSubtitle),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Indicator cicluri (Ciclul X din 4)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.refresh_rounded, size: 16, color: Colors.white38),
            const SizedBox(width: 6),
            Text(
              "Ciclul $_currentCycle din $_targetCycles",
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Card cu sfat anti-craving / personalizat AI
        GestureDetector(
          onTap: () {
            if (_cravingTips.length > 1) {
              setState(() {
                _currentTipIndex = (_currentTipIndex + 1) % _cravingTips.length;
              });
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isAiGenerated
                    ? const Color(0xFFBA68C8).withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.08),
                width: 1.1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isAiGenerated
                              ? Icons.auto_awesome_rounded
                              : Icons.lightbulb_outline_rounded,
                          color: _isAiGenerated
                              ? const Color(0xFFCE93D8)
                              : const Color(0xFFFFB74D),
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isAiGenerated
                              ? "SFAT PERSONALIZAT PROGRES (AI)"
                              : "SFAT ANTI-CRAVING",
                          style: TextStyle(
                            color: _isAiGenerated
                                ? const Color(0xFFCE93D8)
                                : const Color(0xFFFFB74D),
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    if (_cravingTips.length > 1)
                      Text(
                        "${_currentTipIndex + 1}/${_cravingTips.length}",
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: Text(
                    _cravingTips[_currentTipIndex],
                    key: ValueKey<String>(
                        "tip_${_currentTipIndex}_${_cravingTips[_currentTipIndex]}"),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Butoane de acțiune
        Row(
          children: [
            // Buton Pauză / Reia
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                onPressed: _togglePause,
                icon: Icon(
                  _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  size: 20,
                  color: Colors.white70,
                ),
                label: Text(
                  _isPaused ? "Reia" : "Pauză",
                  style: const TextStyle(color: Colors.white70),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Buton "Mă simt mai bine" (Ieșire victorie)
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isCompleted = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B0000),
                  foregroundColor: Colors.white,
                  elevation: 6,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Am depășit pofta! 🎉",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletedView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.greenAccent.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.verified_rounded,
            size: 64,
            color: Colors.greenAccent,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Victorie Împotriva Poftei!",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          "Ai rezistat impulsului de moment. Fiecare victorie te face mai puternic și mai sănătos. Continuă să-ți păstrezi controlul!",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.45,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 26),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              foregroundColor: Colors.white,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              "CONTINUĂ CU FORȚE PROASPETE",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B0000) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}
