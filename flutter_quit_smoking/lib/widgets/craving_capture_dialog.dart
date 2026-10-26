import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/pages/models/craving_model.dart';
import 'package:flutter_quit_smoking/services/auth_services.dart';
import 'package:flutter_quit_smoking/services/database_service.dart';

class CravingCaptureResult {
  final CravingEvent craving;
  final bool startBreathing;

  CravingCaptureResult({
    required this.craving,
    required this.startBreathing,
  });
}

class CravingCaptureDialog extends StatefulWidget {
  final VoidCallback? onDirectBreathingRequested;

  const CravingCaptureDialog({
    super.key,
    this.onDirectBreathingRequested,
  });

  @override
  State<CravingCaptureDialog> createState() => _CravingCaptureDialogState();
}

class _CravingCaptureDialogState extends State<CravingCaptureDialog> {
  final TextEditingController _reasonController = TextEditingController();
  final DateTime _currentTime = DateTime.now();

  String _selectedCategory = 'stress';
  String _selectedDisplayName = 'Stres / Presiune';
  int _intensity = 6;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _triggers = [
    {'id': 'stress', 'name': 'Stres / Presiune', 'icon': Icons.bolt_rounded, 'color': Color(0xFFEF4444)},
    {'id': 'coffee', 'name': 'Cafea / Dimineață', 'icon': Icons.coffee_rounded, 'color': Color(0xFFF59E0B)},
    {'id': 'meal', 'name': 'După masă', 'icon': Icons.restaurant_rounded, 'color': Color(0xFF10B981)},
    {'id': 'social_alcohol', 'name': 'Alcool / Social', 'icon': Icons.local_bar_rounded, 'color': Color(0xFF8B5CF6)},
    {'id': 'boredom', 'name': 'Plictiseală / Pauză', 'icon': Icons.access_time_rounded, 'color': Color(0xFF3B82F6)},
    {'id': 'emotional', 'name': 'Emoții / Supărare', 'icon': Icons.sentiment_very_dissatisfied_rounded, 'color': Color(0xFFEC4899)},
    {'id': 'driving', 'name': 'Trafic / Mașină', 'icon': Icons.directions_car_rounded, 'color': Color(0xFF06B6D4)},
    {'id': 'habit', 'name': 'Obicei automat', 'icon': Icons.replay_rounded, 'color': Color(0xFF64748B)},
    {'id': 'other', 'name': 'Alt motiv', 'icon': Icons.more_horiz_rounded, 'color': Color(0xFF94A3B8)},
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _getIntensityLabel(int value) {
    if (value <= 3) return "Ușoară ($value/10)";
    if (value <= 6) return "Medie ($value/10)";
    if (value <= 8) return "Intensă ($value/10)";
    return "Critică / Urgență ($value/10)";
  }

  Color _getIntensityColor(int value) {
    if (value <= 3) return const Color(0xFF10B981);
    if (value <= 6) return const Color(0xFFF59E0B);
    if (value <= 8) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  Future<void> _submitCraving({required bool startBreathing, bool isDirectEmergency = false}) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final String reasonText = isDirectEmergency
        ? "Declanșare de urgență directă (fără notițe)"
        : _reasonController.text.trim();

    final craving = CravingEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: _currentTime,
      triggerCategory: isDirectEmergency ? 'urgent' : _selectedCategory,
      triggerDisplayName: isDirectEmergency ? 'Urgență directă' : _selectedDisplayName,
      reason: reasonText,
      intensity: isDirectEmergency ? 8 : _intensity,
      overcame: false,
      createdAt: DateTime.now(),
    );

    final user = authServices.value.currentUser;
    await databaseService.saveCravingEvent(uid: user?.uid, craving: craving);

    if (!mounted) return;
    Navigator.of(context).pop(
      CravingCaptureResult(craving: craving, startBreathing: startBreathing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hourStr = _currentTime.hour.toString().padLeft(2, '0');
    final minuteStr = _currentTime.minute.toString().padLeft(2, '0');

    return Dialog(
      backgroundColor: const Color(0xFF141417),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: const Color(0xFFFB7185).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE11D48).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Înregistrează Pofta",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time_filled, color: Color(0xFFFB7185), size: 13),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                "Ora: $hourStr:$minuteStr (${_currentTime.day}.${_currentTime.month}.${_currentTime.year})",
                                style: const TextStyle(
                                  color: Color(0xFFFDA4AF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1D24),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFFFB7185), size: 16),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "AI-ul analizează ora și motivele notate pentru a anticipa și bloca poftele înainte să reapară.",
                        style: TextStyle(color: Color(0xFFD4D4D8), fontSize: 12, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Secțiunea 1: Declanșator
              const Text(
                "Ce a declanșat pofta?",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _triggers.map((t) {
                  final isSelected = _selectedCategory == t['id'];
                  final Color c = t['color'] as Color;
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() {
                        _selectedCategory = t['id'];
                        _selectedDisplayName = t['name'];
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? c.withValues(alpha: 0.22) : const Color(0xFF1E1E24),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? c : Colors.white.withValues(alpha: 0.1),
                          width: isSelected ? 1.4 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(t['icon'] as IconData, size: 14, color: isSelected ? c : const Color(0xFFA1A1AA)),
                          const SizedBox(width: 6),
                          Text(
                            t['name'] as String,
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFFA1A1AA),
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Secțiunea 2: De ce ai o poftă (Câmp text)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      "De ce simți că ai nevoie de o țigară acum?",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Personalizare AI",
                    style: TextStyle(
                      color: const Color(0xFFFB7185).withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _reasonController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Ex: Am o ședință tensionată / stau la cafea cu colegii fumători / mă simt epuizat după o zi lungă...",
                  hintStyle: const TextStyle(color: Color(0xFF71717A), fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF1B1B20),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFB7185), width: 1.4),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Secțiunea 3: Intensitate poftă
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Intensitatea poftei:",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getIntensityColor(_intensity).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getIntensityColor(_intensity).withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      _getIntensityLabel(_intensity),
                      style: TextStyle(
                        color: _getIntensityColor(_intensity),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _getIntensityColor(_intensity),
                  inactiveTrackColor: Colors.white12,
                  thumbColor: _getIntensityColor(_intensity),
                  overlayColor: _getIntensityColor(_intensity).withValues(alpha: 0.2),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _intensity.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (val) {
                    setState(() => _intensity = val.round());
                  },
                ),
              ),

              const SizedBox(height: 18),

              // Butoane de acțiune
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () => _submitCraving(startBreathing: true),
                  icon: const Icon(Icons.air_rounded, size: 20),
                  label: Text(
                    _isSaving ? "Se salvează..." : "Înregistrează și Respiră SOS",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => _submitCraving(startBreathing: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD4D4D8),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Doar Salvează Pofta",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => _submitCraving(startBreathing: true, isDirectEmergency: true),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFDA4AF),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    child: const Text(
                      "Urgență / Fără text",
                      style: TextStyle(fontSize: 11, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
