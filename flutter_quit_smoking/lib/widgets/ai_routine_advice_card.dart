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
          // Header: Iconiță + Titlu + Badge Momentul Zilei + Refresh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFFD4D4D8),
                        size: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        "GHIDUL TĂU ZILNIC (AI)",
                        style: TextStyle(
                          color: Color(0xFFA1A1AA),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.9,
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                    ),
                    child: Text(
                      _currentTimeLabel,
                      style: const TextStyle(
                        color: Color(0xFFD4D4D8),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              color: Color(0xFFA1A1AA),
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF71717A)),
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
            duration: const Duration(milliseconds: 240),
            child: _isLoading && _adviceText == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 11,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C22),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Container(
                        height: 11,
                        width: 220,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C22),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  )
                : Text(
                    _adviceText ?? "Respiră adânc și rămâi concentrat pe progresul tău.",
                    key: ValueKey<String>(_adviceText ?? ''),
                    style: const TextStyle(
                      color: Color(0xFFFAFAFA),
                      fontSize: 13.5,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.1,
                    ),
                  ),
          ),

          // Opțiune configurare obiceiuri dacă nu a setat încă
          if (widget.routine.trim().isEmpty && widget.onConfigureRoutine != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: widget.onConfigureRoutine,
              child: Row(
                children: const [
                  Icon(Icons.edit_note_rounded, size: 15, color: Color(0xFFA1A1AA)),
                  SizedBox(width: 6),
                  Text(
                    "Configurează când fumezi pentru sfaturi precise",
                    style: TextStyle(
                      color: Color(0xFFA1A1AA),
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
