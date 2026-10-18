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
        color: const Color(0xFF121215),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF10B981).withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.07),
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
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: (isCompleted
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFE11D48))
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            isCompleted ? Icons.check_circle_outline_rounded : Icons.flag_outlined,
                            size: 13,
                            color: isCompleted ? const Color(0xFF34D399) : const Color(0xFFFB7185),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            goal.name,
                            style: const TextStyle(
                              color: Color(0xFFFAFAFA),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      "$percentage%",
                      style: TextStyle(
                        color: isCompleted ? const Color(0xFF34D399) : const Color(0xFFFAFAFA),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progressValue,
                  minHeight: 3.5,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? const Color(0xFF34D399) : const Color(0xFFE11D48),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Footer: Zile rămase și Suma
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle_outline_rounded : Icons.schedule_rounded,
                        size: 13,
                        color: isCompleted ? const Color(0xFF34D399) : const Color(0xFF71717A),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isCompleted
                            ? "Obiectiv realizat"
                            : dailyCost > 0
                                ? "$daysRemaining ${daysRemaining == 1 ? 'zi' : 'zile'} rămase"
                                : "Calculează zile",
                        style: TextStyle(
                          color: isCompleted ? const Color(0xFF34D399) : const Color(0xFFA1A1AA),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "${savingsInGoalCurrency.toStringAsFixed(1)} / ${goal.price} ${goal.currency}",
                    style: const TextStyle(
                      color: Color(0xFF71717A),
                      fontSize: 11.5,
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
