import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/pages/models/goal_model.dart';

class GoalContainer extends StatelessWidget {
  final Goal goal;
  final double currentSavings; // Suma totală economisită în RON
  final double dailyCost; // Costul zilnic în RON
  final VoidCallback onDelete;

  const GoalContainer({
    super.key,
    required this.goal,
    required this.currentSavings,
    this.dailyCost = 0.0,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Rata de schimb valutar
    double exchangeRate = 1.0;
    if (goal.currency == 'EUR') {
      exchangeRate = 4.97;
    } else if (goal.currency == 'USD') {
      exchangeRate = 4.60;
    }

    // 2. Prețul obiectivului și economiile în moneda obiectivului
    final double goalPriceOriginal = double.tryParse(goal.price) ?? 1.0;
    final double savingsInGoalCurrency = currentSavings / exchangeRate;

    // 3. Prețul și restul în RON pentru calculul precis al zilelor
    final double goalPriceInRon = goalPriceOriginal * exchangeRate;
    final double remainingRon = (goalPriceInRon - currentSavings).clamp(0.0, double.infinity);

    // 4. Calculul zilelor necesare
    int daysRemaining = 0;
    if (dailyCost > 0) {
      daysRemaining = (remainingRon / dailyCost).ceil();
    }

    // 5. Procentaj și valoare progres
    final double progressValue = (savingsInGoalCurrency / goalPriceOriginal).clamp(0.0, 1.0);
    final int percentage = (progressValue * 100).toInt();
    final bool isCompleted = progressValue >= 1.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isCompleted
              ? Colors.greenAccent.withValues(alpha: 0.4)
              : const Color(0xFF8B0000).withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
          if (isCompleted)
            BoxShadow(
              color: Colors.greenAccent.withValues(alpha: 0.1),
              blurRadius: 16,
              spreadRadius: 1,
            )
          else
            BoxShadow(
              color: const Color(0xFF8B0000).withValues(alpha: 0.12),
              blurRadius: 16,
              spreadRadius: 0,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1C1C1E),
                isCompleted ? const Color(0xFF111E16) : const Color(0xFF140D0F),
              ],
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Preț, Nume, Buton Ștergere
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Preț și Monedă
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF261214),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF8B0000).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          goal.price,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          goal.currency.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFFF6B6B),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Nume Obiectiv
                  Expanded(
                    child: Text(
                      goal.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Buton Ștergere (X)
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white60,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Badge Zile Rămase fără fumat
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF142E1F)
                      : const Color(0xFF2A1417),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCompleted
                        ? Colors.greenAccent.withValues(alpha: 0.3)
                        : const Color(0xFF8B0000).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle_rounded : Icons.timer_outlined,
                      size: 16,
                      color: isCompleted ? Colors.greenAccent : const Color(0xFFFF8A80),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        isCompleted
                            ? "Obiectiv atins cu succes! 🎉"
                            : dailyCost > 0
                                ? "Nu fuma încă $daysRemaining ${daysRemaining == 1 ? 'zi' : 'zile'} pentru a atinge obiectivul"
                                : "Configurează obiceiurile pentru estimarea zilelor",
                        style: TextStyle(
                          color: isCompleted ? Colors.greenAccent : Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Progress Bar și Detalii Financiare
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$percentage%",
                    style: TextStyle(
                      color: isCompleted ? Colors.greenAccent : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${savingsInGoalCurrency.toStringAsFixed(1)} / ${goal.price} ${goal.currency}",
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progressValue,
                  minHeight: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.07),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? Colors.greenAccent : const Color(0xFFE53935),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
