import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/services/gemini_service.dart';

class AiRoutineAdviceCard extends StatefulWidget {
  final String routine;
  final Duration timeElapsed;
  final int cigarettesAvoided;
  final double moneySaved;
  final VoidCallback? onConfigureRoutine;

  const AiRoutineAdviceCard({
    super.key,
    required this.routine,
    required this.timeElapsed,
    required this.cigarettesAvoided,
    required this.moneySaved,
    this.onConfigureRoutine,
  });

  @override
  State<AiRoutineAdviceCard> createState() => _AiRoutineAdviceCardState();
}

class _AiRoutineAdviceCardState extends State<AiRoutineAdviceCard> {
  String? _adviceText;
  bool _isLoading = true;
  String _currentTimeLabel = '';

  @override
  void initState() {
    super.initState();
    _currentTimeLabel = geminiService.getTimeOfDayLabel(DateTime.now());
    _loadAdvice(forceRefresh: false);
  }

  @override
  void didUpdateWidget(covariant AiRoutineAdviceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routine != widget.routine) {
      _loadAdvice(forceRefresh: true);
    }
  }

  Future<void> _loadAdvice({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _currentTimeLabel = geminiService.getTimeOfDayLabel(DateTime.now());
    });

    final advice = await geminiService.getRoutineTip(
      routine: widget.routine,
      timeElapsed: widget.timeElapsed,
      cigarettesAvoided: widget.cigarettesAvoided,
      moneySaved: widget.moneySaved,
      forceRefresh: forceRefresh,
    );

    if (!mounted) return;
    setState(() {
      _adviceText = advice;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1528), // Tentă subtilă purpuriu-violet Gemini
            Color(0xFF141418),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFBA68C8).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Iconiță Gemini + Titlu + Badge Momentul Zilei + Refresh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFAB47BC), Color(0xFFFFB74D)],
                        ),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Flexible(
                      child: Text(
                        "GHIDUL TĂU ZILNIC (AI)",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      _currentTimeLabel,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFBA68C8),
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18, color: Colors.white60),
                    onPressed: _isLoading ? null : () => _loadAdvice(forceRefresh: true),
                    tooltip: "Generează alt sfat",
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Conținut sfat sau skeleton loader inline
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isLoading && _adviceText == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        height: 12,
                        width: 240,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  )
                : Text(
                    _adviceText ?? "Respiră adânc și rămâi concentrat pe progresul tău.",
                    key: ValueKey<String>(_adviceText ?? ''),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
          ),

          // Opțiune configurare obiceiuri dacă nu a setat încă
          if (widget.routine.trim().isEmpty && widget.onConfigureRoutine != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: widget.onConfigureRoutine,
              child: Row(
                children: const [
                  Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFFFFB74D)),
                  SizedBox(width: 6),
                  Text(
                    "Configurează când fumezi pentru sfaturi mai precise",
                    style: TextStyle(
                      color: Color(0xFFFFB74D),
                      fontSize: 11.5,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
