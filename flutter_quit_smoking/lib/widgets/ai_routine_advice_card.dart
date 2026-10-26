import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/pages/models/breathing_session_model.dart';
import 'package:flutter_quit_smoking/pages/models/craving_model.dart';
import 'package:flutter_quit_smoking/pages/models/goal_model.dart';
import 'package:flutter_quit_smoking/pages/models/relapse_model.dart';
import 'package:flutter_quit_smoking/services/auth_services.dart';
import 'package:flutter_quit_smoking/services/database_service.dart';
import 'package:flutter_quit_smoking/services/gemini_service.dart';
import 'package:flutter_quit_smoking/widgets/craving_relapse_history_dialog.dart';

class AiRoutineAdviceCard extends StatefulWidget {
  final String routine;
  final Duration timeElapsed;
  final int cigarettesAvoided;
  final double moneySaved;
  final double dailyCost;
  final Goal? selectedGoal;
  final int refreshTrigger;
  final VoidCallback? onConfigureRoutine;
  final VoidCallback? onOpenSos;

  const AiRoutineAdviceCard({
    super.key,
    required this.routine,
    required this.timeElapsed,
    required this.cigarettesAvoided,
    required this.moneySaved,
    this.dailyCost = 0.0,
    this.selectedGoal,
    this.refreshTrigger = 0,
    this.onConfigureRoutine,
    this.onOpenSos,
  });

  @override
  State<AiRoutineAdviceCard> createState() => _AiRoutineAdviceCardState();
}

class _AiRoutineAdviceCardState extends State<AiRoutineAdviceCard> {
  String? _adviceText;
  bool _isLoading = true;
  BreathingSummary? _breathingSummary;
  RelapseSummary? _relapseSummary;
  CravingSummary? _cravingSummary;
  CombinedRiskPrediction? _prediction;
  Timer? _periodicTimer;

  @override
  void initState() {
    super.initState();
    _loadAdvice(forceRefresh: false);

    // Actualizare automată periodică la fiecare 10 minute pentru sfaturi dinamice pe parcursul zilei
    _periodicTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      if (mounted) {
        _loadAdvice(forceRefresh: true);
      }
    });
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AiRoutineAdviceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routine != widget.routine ||
        oldWidget.selectedGoal != widget.selectedGoal ||
        oldWidget.refreshTrigger != widget.refreshTrigger) {
      _loadAdvice(forceRefresh: true);
    }
  }

  Future<void> _loadAdvice({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final user = authServices.value.currentUser;
    final breathingSummary = await databaseService.getBreathingSummary(uid: user?.uid);
    final relapseSummary = await databaseService.getRelapseSummary(uid: user?.uid);
    final cravingSummary = await databaseService.getCravingSummary(uid: user?.uid);
    final prediction = await databaseService.getCombinedRiskPrediction(
      uid: user?.uid,
      routine: widget.routine,
    );

    if (!mounted) return;
    setState(() {
      _breathingSummary = breathingSummary;
      _relapseSummary = relapseSummary;
      _cravingSummary = cravingSummary;
      _prediction = prediction;
    });

    final advice = await geminiService.getRoutineTip(
      routine: widget.routine,
      timeElapsed: widget.timeElapsed,
      cigarettesAvoided: widget.cigarettesAvoided,
      moneySaved: widget.moneySaved,
      dailyCost: widget.dailyCost,
      selectedGoal: widget.selectedGoal,
      breathingSummary: breathingSummary,
      relapseSummary: relapseSummary,
      cravingSummary: cravingSummary,
      riskPrediction: prediction,
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
    final now = DateTime.now();
    final pred = _prediction ??
        CombinedRiskPrediction.predict(
          now: now,
          routine: widget.routine,
          relapseSummary: _relapseSummary,
          cravingSummary: _cravingSummary,
        );

    // Detectăm dacă utilizatorul este considerat în situație de risc sau poftă anticipată
    final bool isRelapseRisk = pred.isAtRisk ||
        (_adviceText != null &&
            (_adviceText!.contains('🛡️') ||
                _adviceText!.toLowerCase().contains('recidiv') ||
                _adviceText!.toLowerCase().contains('relapse') ||
                _adviceText!.toLowerCase().contains('vulnerab') ||
                _adviceText!.toLowerCase().contains('anticip') ||
                _adviceText!.toLowerCase().contains('critic') ||
                _adviceText!.toLowerCase().contains('pericol')));

    final String timeSlotLabel = geminiService.getTimeOfDayLabel(now);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRelapseRisk ? const Color(0xFF191114) : const Color(0xFF141417),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRelapseRisk
              ? const Color(0xFFFB7185).withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Status Badge (stânga) + Butoane compacte (dreapta)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isRelapseRisk
                      ? const Color(0xFFE11D48).withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isRelapseRisk
                        ? const Color(0xFFFB7185).withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.08),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isRelapseRisk ? Icons.shield_rounded : Icons.auto_awesome_rounded,
                      size: 13,
                      color: isRelapseRisk ? const Color(0xFFFB7185) : const Color(0xFFA1A1AA),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isRelapseRisk ? pred.alertTitle : "${pred.alertTitle} • $timeSlotLabel",
                      style: TextStyle(
                        color: isRelapseRisk ? const Color(0xFFFDA4AF) : const Color(0xFFD4D4D8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.history_edu_rounded, size: 17),
                    color: const Color(0xFFA1A1AA),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const CravingRelapseHistoryDialog(),
                      );
                    },
                    tooltip: "Jurnal pofte & recidive",
                    padding: const EdgeInsets.all(5),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              color: Color(0xFFA1A1AA),
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, size: 17),
                    color: const Color(0xFFA1A1AA),
                    onPressed: _isLoading ? null : () => _loadAdvice(forceRefresh: true),
                    tooltip: "Generează alt sfat",
                    padding: const EdgeInsets.all(5),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),

          // Context de risc (dacă este detectat): linie simplă și clară, fără cutii înghesuite
          if (isRelapseRisk && pred.riskReason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              pred.riskReason,
              style: const TextStyle(
                color: Color(0xFFFB7185),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Sfatul propriu-zis: spațiere aerisită, tipografie curată, fără chenare duble
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isLoading && _adviceText == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        height: 12,
                        width: 180,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  )
                : Text(
                    _adviceText ?? "Rămâi concentrat pe progresul tău de astăzi.",
                    key: ValueKey<String>(_adviceText ?? ''),
                    style: TextStyle(
                      color: isRelapseRisk ? const Color(0xFFFFF1F2) : const Color(0xFFFAFAFA),
                      fontSize: 13.5,
                      height: 1.55,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
          ),

          // Buton de acțiune rapidă în caz de risc (simplu, proporționat)
          if (isRelapseRisk && widget.onOpenSos != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onOpenSos,
                icon: const Icon(Icons.air_rounded, size: 15, color: Color(0xFFFDA4AF)),
                label: const Text(
                  "Exercițiu de respirație (2 min)",
                  style: TextStyle(
                    color: Color(0xFFFDA4AF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48).withValues(alpha: 0.12),
                  side: BorderSide(
                    color: const Color(0xFFFB7185).withValues(alpha: 0.35),
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],

          // Metadata discretă în footer
          if (_breathingSummary != null && _breathingSummary!.lastSession != null) ...[
            const SizedBox(height: 10),
            Text(
              "Respirație: ${_breathingSummary!.totalSessionsToday > 0 ? '${_breathingSummary!.totalSessionsToday} sesiuni azi' : '${_breathingSummary!.totalSessions} sesiuni'} • ultima la ${_breathingSummary!.lastSession!.formattedStartTime}",
              style: const TextStyle(
                color: Color(0xFF71717A),
                fontSize: 11,
              ),
            ),
          ],

          if (widget.routine.trim().isEmpty && widget.onConfigureRoutine != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: widget.onConfigureRoutine,
              child: const Text(
                "Configurează când fumezi de obicei",
                style: TextStyle(
                  color: Color(0xFF71717A),
                  fontSize: 11,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
