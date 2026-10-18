import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quit_smoking/pages/counter_page.dart';
import 'package:flutter_quit_smoking/pages/register_page.dart';
import 'package:flutter_quit_smoking/pages/start_quit.dart';
import 'package:flutter_quit_smoking/services/auth_services.dart';
import 'package:flutter_quit_smoking/services/database_service.dart';
import 'package:flutter_quit_smoking/utils/password_generator.dart';
import 'package:flutter_quit_smoking/widgets/reset_password_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? onRegisterTap;

  const LoginPage({super.key, this.onRegisterTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    final generated = PasswordGenerator.generatePassword(length: 14);
    setState(() {
      _passwordController.text = generated;
      _isPasswordObscured = false; // Permite utilizatorului să o vadă imediat
      _errorMessage = null;
    });

    Clipboard.setData(ClipboardData(text: generated));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Parolă securizată generată și copiată în clipboard!",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _copyPasswordToClipboard() {
    if (_passwordController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _passwordController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Parola a fost copiată în clipboard!"),
          backgroundColor: const Color(0xFF8B0000),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Vă rugăm să introduceți atât email-ul cât și parola.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await authServices.value.signIn(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (credential.user != null) {
        // Verificăm dacă utilizatorul are deja date de start în Firestore sau SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final startTimeStr = prefs.getString('start_time');

        if (!mounted) return;

        if (startTimeStr != null && startTimeStr.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CounterPage()),
          );
        } else {
          // Verificăm și direct în datele din Firestore
          final userData = await databaseService.getUserData(credential.user!.uid);
          if (!mounted) return;

          if (userData != null && userData['isStarted'] == true && userData['startTime'] != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const CounterPage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const StartQuit()),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AuthServices.getReadableErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = "Introduceți adresa de email pentru a primi instrucțiunile de resetare.";
      });
      return;
    }

    try {
      await authServices.value.resetPassword(email: email);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => const ResetPasswordDialog(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AuthServices.getReadableErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo cu accent roșu închis
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B0000).withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.smoke_free_rounded,
                    size: 60,
                    color: Color(0xFF8B0000),
                  ),
                ),
                const SizedBox(height: 30),

                // Titlu și subtitlu
                const Text(
                  "Bine ai revenit",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Continuă-ți călătoria fără fumat",
                  style: TextStyle(color: Colors.white60, fontSize: 15),
                ),
                const SizedBox(height: 35),

                // Câmp Email
                _buildEmailField(),
                const SizedBox(height: 18),

                // Câmp Parolă
                _buildPasswordField(),
                const SizedBox(height: 12),

                // Buton generare parolă + Link resetare
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    // Buton Generare Parolă
                    TextButton.icon(
                      onPressed: _generatePassword,
                      icon: const Icon(
                        Icons.auto_fix_high_rounded,
                        size: 18,
                        color: Color(0xFFFF6B6B),
                      ),
                      label: const Text(
                        "Generează parolă",
                        style: TextStyle(
                          color: Color(0xFFFF6B6B),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        backgroundColor: const Color(0xFF261214),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Link Ai uitat parola?
                    GestureDetector(
                      onTap: _resetPassword,
                      child: const Text(
                        "Ai uitat parola?",
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Mesaj de eroare dacă există
                if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Buton Autentificare (Login)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B0000),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF501010),
                      elevation: 6,
                      shadowColor: const Color(0xFF8B0000).withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            "AUTENTIFICARE",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 25),

                // Footer către Înregistrare
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      "Nu ai un cont? ",
                      style: TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: widget.onRegisterTap ??
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                      child: const Text(
                        "Înregistrează-te",
                        style: TextStyle(
                          color: Color(0xFFE53935),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Adresă de email",
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _isPasswordObscured,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Parolă",
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400]),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_passwordController.text.isNotEmpty)
                IconButton(
                  tooltip: "Copiază parola",
                  icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 20),
                  onPressed: _copyPasswordToClipboard,
                ),
              IconButton(
                tooltip: _isPasswordObscured ? "Afișează parola" : "Ascunde parola",
                icon: Icon(
                  _isPasswordObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.grey[400],
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordObscured = !_isPasswordObscured;
                  });
                },
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onChanged: (_) {
          setState(() {}); // Pentru afișarea butonului de copiere
        },
      ),
    );
  }
}
