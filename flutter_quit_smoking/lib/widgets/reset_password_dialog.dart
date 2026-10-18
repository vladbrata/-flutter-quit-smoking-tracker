import 'package:flutter/material.dart';

class ResetPasswordDialog extends StatelessWidget {
  const ResetPasswordDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "Resetare Parolă",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: const Text(
        "A fost trimis un link de resetare pe adresa dvs. de email. Vă rugăm să verificați căsuța de mesaje (inclusiv folderul Spam).",
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF8B0000),
          ),
          child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
