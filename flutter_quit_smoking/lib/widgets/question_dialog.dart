import 'package:flutter/material.dart';

class QuestionDialog extends StatefulWidget {
  final double? initialPrice;
  final int? initialCigarettesPerDay;
  final String? initialSmokingRoutine;

  const QuestionDialog({
    super.key,
    this.initialPrice,
    this.initialCigarettesPerDay,
    this.initialSmokingRoutine,
  });

  @override
  State<QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<QuestionDialog> {
  late TextEditingController _priceController;
  late TextEditingController _cigarettesController;
  late TextEditingController _routineController;

  double _packPrice = 0.0;
  int _cigarettesPerDay = 20;

  @override
  void initState() {
    super.initState();
    _packPrice = widget.initialPrice ?? 26.0;
    _cigarettesPerDay = widget.initialCigarettesPerDay ?? 20;

    _priceController = TextEditingController(
      text: _packPrice > 0 ? _packPrice.toStringAsFixed(2) : "",
    );
    _cigarettesController = TextEditingController(
      text: _cigarettesPerDay > 0 ? _cigarettesPerDay.toString() : "",
    );
    _routineController = TextEditingController(
      text: widget.initialSmokingRoutine ?? "",
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _cigarettesController.dispose();
    _routineController.dispose();
    super.dispose();
  }

  double get _packsPerDay => _cigarettesPerDay / 20.0;
  double get _dailyCost => _packsPerDay * _packPrice;

  void _submit() {
    final price = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.0;
    final cigs = int.tryParse(_cigarettesController.text) ?? 0;

    if (price <= 0 || cigs <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vă rugăm să introduceți valori valide mai mari ca 0."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final double packsPerDay = cigs / 20.0;
    final double dailyCost = packsPerDay * price;

    Navigator.pop(context, {
      'packPrice': price,
      'cigarettesPerDay': cigs,
      'packsPerDay': packsPerDay,
      'dailyCost': dailyCost,
      'smokingRoutine': _routineController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Icon(Icons.smoking_rooms, color: Color(0xFF8B0000)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Obiceiuri de fumat",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Setează datele pentru a calcula economiile și progresul tău în timp real:",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 18),

            // Preț pachet
            const Text(
              "Preț pachet (RON)",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "ex: 26.50",
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: Icon(Icons.attach_money, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (val) {
                  setState(() {
                    _packPrice = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Țigări fumate pe zi
            const Text(
              "Țigări fumate pe zi (bucăți)",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _cigarettesController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "ex: 20 (1 pachet)",
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: Icon(Icons.numbers, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (val) {
                  setState(() {
                    _cigarettesPerDay = int.tryParse(val) ?? 0;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Când fumezi de obicei? (Limbaj natural)
            const Text(
              "Când fumezi de obicei? (obiceiuri / momente)",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            const Text(
              "Descrie în cuvintele tale momentele zilei (la cafea, pauze, stres, după masă etc.)",
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _routineController,
                keyboardType: TextInputType.multiline,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: "ex: Dimineața la prima cafea, după fiecare masă, când am pauză la serviciu la 12:00 sau seara când sunt stresat...",
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Icon(Icons.schedule_rounded, color: Colors.grey),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card rezumat estimări
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Pachete pe zi:", style: TextStyle(color: Colors.white60, fontSize: 12)),
                      Text(
                        "${_packsPerDay.toStringAsFixed(1)} pachete",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Cost zilnic estimat:", style: TextStyle(color: Colors.white60, fontSize: 12)),
                      Text(
                        "${_dailyCost.toStringAsFixed(2)} RON",
                        style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Cost lunar (30 zile):", style: TextStyle(color: Colors.white60, fontSize: 12)),
                      Text(
                        "${(_dailyCost * 30).toStringAsFixed(2)} RON",
                        style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("ANULEAZĂ", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B0000),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          ),
          child: const Text("SALVEAZĂ", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
