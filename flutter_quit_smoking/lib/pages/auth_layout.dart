import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/pages/register_page.dart';
import 'package:flutter_quit_smoking/pages/start_quit.dart';
import 'package:flutter_quit_smoking/services/auth_services.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, this.pageIfNotConnected});

  final Widget? pageIfNotConnected;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: authServices,
      builder: (context, authServices, child) {
        return StreamBuilder(
          stream: authServices.authStateChanges,
          builder: (context, snapshot) {
            Widget widget;
            if (snapshot.hasData) {
              widget = const StartQuit();
            } else {
              widget = pageIfNotConnected ?? const RegisterPage();
            }
            return widget;
          },
        );
      },
    );
  }
}
