import 'package:flutter/material.dart';

class ResetPasswordDialog extends StatelessWidget {
  const ResetPasswordDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AlertDialog(
        title: const Text("Reset Password"),
        content: const Text("You can't reset your password, at the moment"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
