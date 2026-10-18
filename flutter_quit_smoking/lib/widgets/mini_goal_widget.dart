import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/pages/models/goal_model.dart';

class MiniGoalWidget extends StatelessWidget {
  final Goal goal;
  final double currentSavings;
  final double dailyCost;

  const MiniGoalWidget({
    super.key,
    required this.goal,
    required this.currentSavings,
    this.dailyCost = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Rata de schimb
    double exchangeRate = 1.0;
    if (goal.currency == 'EUR') {
      exchangeRate = 4.97;
    } else if (goal.currency == 'USD') {
      exchangeRate = 4.60;
    }

    final double goalPriceOriginal = double.tryParse(goal.price) ?? 1.0;
    final double savingsInGoalCurrency = currentSavings / exchangeRate;
    final double goalPriceInRon = goalPriceOriginal * exchangeRate;
    final double remainingRon = (goalPriceInRon - currentSavings).clamp(0.0, double.infinity);

    int daysRemaining = 0;
    if (dailyCost > 0) {
      daysRemaining = (remainingRon / dailyCost).ceil();
    }

    final double progressValue = (savingsInGoalCurrency / goalPriceOriginal).clamp(0.0, 1.0);
    final int percentage = (progressValue * 100).toInt();
    final bool isCompleted = progressValue >= 1.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCompleted
              ? const [
                  Color(0xFF14241A),
                  Color(0xFF121413),
                ]
              : const [
                  Color(0xFF221114),
                  Color(0xFF131316),
                ],
        ),
        border: Border.all(
          color: isCompleted
              ? Colors.greenAccent.withValues(alpha: 0.5)
              : const Color(0xFF8B0000).withValues(alpha: 0.5),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCompleted ? Colors.greenAccent : const Color(0xFF8B0000))
                .withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icon, Nume și Procentaj
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: (isCompleted
                                    ? Colors.greenAccent
                                    : const Color(0xFF8B0000))
                                .withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCompleted ? Icons.emoji_events_rounded : Icons.flag_rounded,
                            size: 16,
                            color: isCompleted ? Colors.greenAccent : const Color(0xFFFF5252),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            goal.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isCompleted ? Colors.greenAccent : const Color(0xFF8B0000))
                          .withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isCompleted ? Colors.greenAccent : const Color(0xFFFF5252))
                            .withValues(alpha: 0.5),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      "$percentage%",
                      style: TextStyle(
                        color: isCompleted ? Colors.greenAccent : Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progressValue,
                  minHeight: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? Colors.greenAccent : const Color(0xFFE53935),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Footer: Zile rămase și Suma
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle_outline_rounded : Icons.hourglass_bottom_rounded,
                        size: 14,
                        color: isCompleted ? Colors.greenAccent : const Color(0xFFFF8A80),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isCompleted
                            ? "Obiectiv atins cu succes!"
                            : dailyCost > 0
                                ? "$daysRemaining ${daysRemaining == 1 ? 'zi' : 'zile'} fără fumat"
                                : "Calculează zile",
                        style: TextStyle(
                          color: isCompleted ? Colors.greenAccent : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "${savingsInGoalCurrency.toStringAsFixed(1)} / ${goal.price} ${goal.currency}",
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
