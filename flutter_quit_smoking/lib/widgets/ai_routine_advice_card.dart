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
  String _currentTimeLabel = '';
  BreathingSummary? _breathingSummary;
  RelapseSummary? _relapseSummary;
  CravingSummary? _cravingSummary;
  CombinedRiskPrediction? _prediction;
  Timer? _periodicTimer;

  @override
  void initState() {
    super.initState();
    _currentTimeLabel = geminiService.getTimeOfDayLabel(DateTime.now());
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
      _currentTimeLabel = geminiService.getTimeOfDayLabel(DateTime.now());
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

    String badgeText = _currentTimeLabel;
    IconData? badgeIcon;
    if (pred.isAtRisk) {
      switch (pred.riskType) {
        case RiskType.cravingPrediction:
          badgeText = "POFTĂ ANTICIPATĂ";
          badgeIcon = Icons.psychology_rounded;
          break;
        case RiskType.relapseProximity:
        case RiskType.recentRelapse48h:
          badgeText = "RISC RECIDIVĂ";
          badgeIcon = Icons.warning_amber_rounded;
          break;
        case RiskType.routineMatch:
          badgeText = "RUTINĂ ACTIVĂ";
          badgeIcon = Icons.schedule_rounded;
          break;
        case RiskType.none:
          badgeText = _currentTimeLabel;
          break;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isRelapseRisk ? const Color(0xFF1E0E14) : const Color(0xFF121215),
        gradient: isRelapseRisk
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2E1019),
                  Color(0xFF190910),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRelapseRisk
              ? const Color(0xFFFB7185).withValues(alpha: 0.65)
              : Colors.white.withValues(alpha: 0.07),
          width: isRelapseRisk ? 1.6 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isRelapseRisk
                ? const Color(0xFFE11D48).withValues(alpha: 0.30)
                : Colors.black.withValues(alpha: 0.35),
            blurRadius: isRelapseRisk ? 22 : 12,
            spreadRadius: isRelapseRisk ? 1.2 : 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Iconiță + Titlu + Badge Momentul Zilei / Risc + Refresh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: isRelapseRisk
                            ? const Color(0xFFE11D48).withValues(alpha: 0.22)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                        border: isRelapseRisk
                            ? Border.all(
                                color: const Color(0xFFFB7185).withValues(alpha: 0.40),
                                width: 0.8,
                              )
                            : null,
                      ),
                      child: Icon(
                        isRelapseRisk ? Icons.shield_rounded : Icons.auto_awesome_rounded,
                        color: isRelapseRisk ? const Color(0xFFFB7185) : const Color(0xFFD4D4D8),
                        size: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        isRelapseRisk
                            ? pred.alertTitle
                            : "ANALIZĂ ȘI GHID AI PERSONALIZAT",
                        style: TextStyle(
                          color: isRelapseRisk ? const Color(0xFFFDA4AF) : const Color(0xFFA1A1AA),
                          fontSize: 10.5,
                          fontWeight: isRelapseRisk ? FontWeight.w700 : FontWeight.w600,
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
                    padding: EdgeInsets.symmetric(
                      horizontal: isRelapseRisk ? 9 : 8,
                      vertical: isRelapseRisk ? 3.5 : 3,
                    ),
                    decoration: BoxDecoration(
                      color: isRelapseRisk
                          ? const Color(0xFFE11D48).withValues(alpha: 0.28)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isRelapseRisk
                            ? const Color(0xFFFB7185).withValues(alpha: 0.50)
                            : Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                    child: isRelapseRisk
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                badgeIcon ?? Icons.warning_amber_rounded,
                                size: 11,
                                color: const Color(0xFFFECDD3),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                badgeText,
                                style: const TextStyle(
                                  color: Color(0xFFFECDD3),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          )
                        : Text(
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
                        ? SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              color: isRelapseRisk
                                  ? const Color(0xFFFB7185)
                                  : const Color(0xFFA1A1AA),
                            ),
                          )
                        : Icon(
                            Icons.refresh_rounded,
                            size: 16,
                            color: isRelapseRisk
                                ? const Color(0xFFFDA4AF)
                                : const Color(0xFF71717A),
                          ),
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

          // Banner de alertă de risc dacă AI-ul a detectat o situație similară cu un relapse trecut sau o poftă anticipată
          if (pred.isAtRisk && pred.riskReason.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF000000).withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFB7185).withValues(alpha: 0.40),
                  width: 1.0,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    pred.riskType == RiskType.cravingPrediction
                        ? Icons.psychology_rounded
                        : Icons.shield_outlined,
                    size: 16,
                    color: const Color(0xFFFB7185),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pred.alertTitle,
                          style: const TextStyle(
                            color: Color(0xFFFB7185),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${pred.riskReason} AI-ul te sfătuiește să aplici măsuri preventive acum.",
                          style: const TextStyle(
                            color: Color(0xFFFEE2E2),
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

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
                          color: isRelapseRisk
                              ? const Color(0xFF381520)
                              : const Color(0xFF1C1C22),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Container(
                        height: 11,
                        width: 220,
                        decoration: BoxDecoration(
                          color: isRelapseRisk
                              ? const Color(0xFF381520)
                              : const Color(0xFF1C1C22),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  )
                : isRelapseRisk
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE11D48).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: const Border(
                            left: BorderSide(
                              color: Color(0xFFFB7185),
                              width: 3.5,
                            ),
                          ),
                        ),
                        child: Text(
                          _adviceText ?? "Respiră adânc și rămâi concentrat pe progresul tău.",
                          key: ValueKey<String>(_adviceText ?? ''),
                          style: const TextStyle(
                            color: Color(0xFFFFF1F2),
                            fontSize: 13.5,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
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

          // Buton de acțiune rapidă în caz de risc de recidivă (deschide respirația ghidată)
          if (isRelapseRisk && widget.onOpenSos != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onOpenSos,
                icon: const Icon(Icons.air_rounded, size: 15, color: Colors.white),
                label: const Text(
                  "Dezamorsează impulsul acum (Respirație SOS)",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],

          // Indicator sesiune respirație integrată în AI
          if (_breathingSummary != null && _breathingSummary!.lastSession != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isRelapseRisk
                    ? const Color(0xFF240E16)
                    : const Color(0xFF16161A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isRelapseRisk
                      ? const Color(0xFFFB7185).withValues(alpha: 0.20)
                      : Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.air_rounded,
                    size: 13,
                    color: isRelapseRisk ? const Color(0xFFFB7185) : const Color(0xFF2DD4BF),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      "Respirație analizată de AI: ${_breathingSummary!.totalSessionsToday > 0 ? '${_breathingSummary!.totalSessionsToday} sesiuni azi' : '${_breathingSummary!.totalSessions} sesiuni'} (ultima la ${_breathingSummary!.lastSession!.formattedStartTime} - ${_breathingSummary!.lastSession!.techniqueDisplayName})",
                      style: TextStyle(
                        color: isRelapseRisk ? const Color(0xFFFDA4AF) : const Color(0xFFA1A1AA),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Link direct către Jurnalul de Pofte & Recidive
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const CravingRelapseHistoryDialog(),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.history_edu_rounded,
                    size: 14,
                    color: isRelapseRisk
                        ? const Color(0xFFFDA4AF)
                        : const Color(0xFFA1A1AA),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Vezi Jurnalul de pofte & ore de risc (${_cravingSummary?.totalCravings ?? 0} pofte / ${_relapseSummary?.totalRelapses ?? 0} recidive)",
                      style: TextStyle(
                        color: isRelapseRisk
                            ? const Color(0xFFFDA4AF)
                            : const Color(0xFFA1A1AA),
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: isRelapseRisk
                        ? const Color(0xFFFDA4AF)
                        : const Color(0xFF71717A),
                  ),
                ],
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
