import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/pages/models/goal_model.dart';

class AddGoalsQuestionDialog extends StatefulWidget {
  const AddGoalsQuestionDialog({super.key});

  @override
  State<AddGoalsQuestionDialog> createState() => _AddGoalsQuestionDialogState();
}

class _AddGoalsQuestionDialogState extends State<AddGoalsQuestionDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCurrency = "RON";

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final priceStr = _priceController.text.trim().replaceAll(',', '.');
    final price = double.tryParse(priceStr);

    if (name.isEmpty || price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Introduceți un nume și un preț valid mai mare ca 0."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newGoal = Goal(
      name: name,
      price: price.toStringAsFixed(0),
      currency: _selectedCurrency,
    );

    Navigator.pop(context, newGoal);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: const [
          Icon(Icons.flag_rounded, color: Color(0xFF8B0000)),
          SizedBox(width: 10),
          Text(
            "Obiectiv Nou",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ce dorești să cumperi din banii economisiți?",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Nume obiectiv
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "ex: Adidași, Vacanță, Laptop",
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: Icon(Icons.card_giftcard, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Preț și Valută
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Preț (ex: 500)",
                        hintStyle: TextStyle(color: Colors.white38),
                        prefixIcon: Icon(Icons.attach_money, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCurrency,
                        dropdownColor: const Color(0xFF2A2A2A),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        items: const [
                          DropdownMenuItem(value: "RON", child: Text("RON")),
                          DropdownMenuItem(value: "EUR", child: Text("EUR")),
                          DropdownMenuItem(value: "USD", child: Text("USD")),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCurrency = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
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
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          ),
          child: const Text("ADAVGĂ", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
