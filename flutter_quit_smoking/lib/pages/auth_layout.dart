import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/pages/counter_page.dart';
import 'package:flutter_quit_smoking/pages/login_page.dart';
import 'package:flutter_quit_smoking/pages/start_quit.dart';
import 'package:flutter_quit_smoking/services/auth_services.dart';
import 'package:flutter_quit_smoking/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, this.pageIfNotConnected});

  final Widget? pageIfNotConnected;

  Future<bool> _hasStartedQuit(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final startTime = prefs.getString('start_time');
    if (startTime != null && startTime.isNotEmpty) {
      return true;
    }

    try {
      final data = await databaseService.getUserData(uid);
      if (data != null && data['isStarted'] == true && data['startTime'] != null) {
        await databaseService.syncFromFirestoreToLocal(uid);
        return true;
      }
    } catch (_) {}

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: authServices,
      builder: (context, auth, child) {
        return StreamBuilder(
          stream: auth.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF8B0000)),
                ),
              );
            }

            if (snapshot.hasData && snapshot.data != null) {
              final user = snapshot.data!;
              return FutureBuilder<bool>(
                future: _hasStartedQuit(user.uid),
                builder: (context, quitSnapshot) {
                  if (quitSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      backgroundColor: Colors.black,
                      body: Center(
                        child: CircularProgressIndicator(color: Color(0xFF8B0000)),
                      ),
                    );
                  }

                  if (quitSnapshot.data == true) {
                    return const CounterPage();
                  } else {
                    return const StartQuit();
                  }
                },
              );
            } else {
              return pageIfNotConnected ?? const LoginPage();
            }
          },
        );
      },
    );
  }
}
