import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/pages/models/goal_model.dart';

class MiniGoalWidget extends StatelessWidget {
  final Goal goal;
  final double currentSavings;

  const MiniGoalWidget({
    Key? key,
    required this.goal,
    required this.currentSavings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Currency Conversion Logic (Same as GoalContainer)
    double exchangeRate = 1.0;
    if (goal.currency == 'EUR') {
      exchangeRate = 4.97;
    } else if (goal.currency == 'USD') {
      exchangeRate = 4.60;
    }

    double savingsInGoalCurrency = currentSavings / exchangeRate;
    double goalPrice = double.tryParse(goal.price) ?? 1.0;
    double progressValue = (savingsInGoalCurrency / goalPrice).clamp(0.0, 1.0);
    int percentage = (progressValue * 100).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name and Percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "$percentage%",
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                progressValue >= 1.0 ? Colors.greenAccent : Colors.orangeAccent,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Footer: Value
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "${savingsInGoalCurrency.toStringAsFixed(1)} / ${goal.price} ${goal.currency}",
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
