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
        return const Color(0xFF2DD4BF); // Calm teal
      case BreathingPhase.holdIn:
        return const Color(0xFFE4E4E7); // Calm white/zinc
      case BreathingPhase.exhale:
        return const Color(0xFF38BDF8); // Gentle sky
      case BreathingPhase.holdOut:
        return const Color(0xFFA1A1AA); // Muted zinc
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF101013),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 36,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.air_rounded,
                      color: Color(0xFFFB7185),
                      size: 16,
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
                            color: Color(0xFFFAFAFA),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.9,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "Respiră conștient. Impulsul scade în câteva minute.",
                          style: TextStyle(color: Color(0xFF71717A), fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Color(0xFF71717A), size: 20),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: "Închide",
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Selector Tehnică Respirație
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFF16161A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
              height: 170,
              width: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ghid circular exterior discret
                  Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                        width: 1.0,
                      ),
                    ),
                  ),

                  // Cercul principal animat
                  Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 114,
                      height: 114,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF16161A),
                        border: Border.all(
                          color: _phaseColor.withValues(alpha: 0.7),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
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
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: _phaseColor,
                          height: 1.0,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _phaseTitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.6,
                          color: Color(0xFFFAFAFA),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        // Subtitlu fază de respirație
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: Text(
            _phaseSubtitle,
            key: ValueKey<String>(_phaseSubtitle),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFA1A1AA),
              fontSize: 13,
              fontStyle: FontStyle.normal,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Indicator cicluri (Ciclul X din 4)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF71717A)),
            const SizedBox(width: 5),
            Text(
              "Ciclul $_currentCycle din $_targetCycles",
              style: const TextStyle(
                color: Color(0xFF71717A),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

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
              color: const Color(0xFF16161A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.07),
                width: 1.0,
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
                          color: const Color(0xFFA1A1AA),
                          size: 13,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isAiGenerated
                              ? "SFAT PERSONALIZAT PROGRES (AI)"
                              : "SFAT ANTI-CRAVING",
                          style: const TextStyle(
                            color: Color(0xFFA1A1AA),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    if (_cravingTips.length > 1)
                      Text(
                        "${_currentTipIndex + 1}/${_cravingTips.length}",
                        style: const TextStyle(
                          color: Color(0xFF71717A),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: Text(
                    _cravingTips[_currentTipIndex],
                    key: ValueKey<String>(
                        "tip_${_currentTipIndex}_${_cravingTips[_currentTipIndex]}"),
                    style: const TextStyle(
                      color: Color(0xFFE4E4E7),
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

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
                  size: 16,
                  color: const Color(0xFFD4D4D8),
                ),
                label: Text(
                  _isPaused ? "Reia" : "Pauză",
                  style: const TextStyle(
                    color: Color(0xFFD4D4D8),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF16161A),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

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
                  backgroundColor: const Color(0xFFE11D48),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Am depășit pofta! 🎉",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.2,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
              width: 1.0,
            ),
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 38,
            color: Color(0xFF34D399),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          "Victorie Împotriva Poftei!",
          style: TextStyle(
            color: Color(0xFFFAFAFA),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          "Ai rezistat impulsului de moment. Fiecare craving depășit recalibrează circuitele neuronale spre autonomie completă.",
          style: TextStyle(
            color: Color(0xFFA1A1AA),
            fontSize: 13,
            height: 1.45,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "CONTINUĂ CU FORȚE PROASPETE",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                letterSpacing: 0.8,
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF27272A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.8)
              : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFAFAFA) : const Color(0xFF71717A),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
