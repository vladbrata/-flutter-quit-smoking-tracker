import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/pages/models/goal_model.dart';

class GoalContainer extends StatefulWidget {
  final Goal goal;
  final VoidCallback onDelete;

  const GoalContainer({super.key, required this.goal, required this.onDelete});

  @override
  State<GoalContainer> createState() => _GoalContainerState();
}

class _GoalContainerState extends State<GoalContainer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Fundal gri foarte închis
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white10), // O bordură fină pentru stil
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // STÂNGA: Prețul și Currency (Mare)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.goal.price, // Prețul fără zecimale inutile
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold, // Foarte gros/mare
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

          const SizedBox(width: 25), // Spațiu între preț și nume
          // MIJLOC: Numele Goal-ului
          Expanded(
            child: Text(
              widget.goal.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              overflow:
                  TextOverflow.ellipsis, // Dacă numele e prea lung, pune ...
            ),
          ),

          // DREAPTA: Butonul X pentru ștergere
          GestureDetector(
            onTap: widget.onDelete,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white54, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
