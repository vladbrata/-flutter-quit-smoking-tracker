import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/pages/models/goal_model.dart';

class GoalContainer extends StatefulWidget {
  final Goal goal;
  final double currentSavings; // Suma totală economisită (ex: 40.0)
  final VoidCallback onDelete;

  const GoalContainer({
    super.key,
    required this.goal,
    required this.currentSavings, // Îl cerem obligatoriu
    required this.onDelete,
  });

  @override
  State<GoalContainer> createState() => _GoalContainerState();
}

class _GoalContainerState extends State<GoalContainer> {
  @override
  Widget build(BuildContext context) {
    // 1. Determinăm rata de schimb (Hardcoded pentru moment)
    double exchangeRate = 1.0;
    if (widget.goal.currency == 'EUR') {
      exchangeRate = 4.97;
    } else if (widget.goal.currency == 'USD') {
      exchangeRate = 4.60;
    }

    // 2. Convertim economiile (care sunt în RON) în moneda goal-ului
    double savingsInGoalCurrency = widget.currentSavings / exchangeRate;

    // 3. Parsăm prețul goal-ului
    double goalPrice = double.tryParse(widget.goal.price) ?? 1.0;

    // 4. Calculăm progresul
    double progressValue = (savingsInGoalCurrency / goalPrice).clamp(0.0, 1.0);
    int percentage = (progressValue * 100).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        // Am schimbat în Column pentru a pune Progress Bar-ul sub date
        children: [
          Row(
            children: [
              // STÂNGA: Prețul și Currency
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.goal.price,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    widget.goal.currency.toUpperCase(),
                    style: TextStyle(
                      color: Colors.redAccent.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 25),
              // MIJLOC: Numele Goal-ului
              Expanded(
                child: Text(
                  widget.goal.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // DREAPTA: Butonul X
              GestureDetector(
                onTap: widget.onDelete,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white54,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20), // Spațiu între date și bară
          // SECȚIUNEA NOUĂ: Progress Bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$percentage%",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${savingsInGoalCurrency.toStringAsFixed(2)} / ${widget.goal.price} ${widget.goal.currency}",
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                // Pentru a rotunji colțurile barei
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressValue,
                  minHeight: 10,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  // Dacă e gata (100%), se face verde, altfel rămâne roșu
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progressValue >= 1.0
                        ? Colors.greenAccent
                        : Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
