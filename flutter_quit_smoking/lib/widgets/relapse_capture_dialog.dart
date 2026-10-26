import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/pages/models/relapse_model.dart';

class RelapseResult {
  final RelapseEvent relapseEvent;
  final bool restartImmediately;
  final DateTime newStartTime;

  RelapseResult({
    required this.relapseEvent,
    required this.restartImmediately,
    required this.newStartTime,
  });
}

class RelapseCaptureDialog extends StatefulWidget {
  final int smokeFreeDurationSeconds;

  const RelapseCaptureDialog({
    super.key,
    required this.smokeFreeDurationSeconds,
  });

  @override
  State<RelapseCaptureDialog> createState() => _RelapseCaptureDialogState();
}

class _RelapseCaptureDialogState extends State<RelapseCaptureDialog> {
  DateTime _relapseTime = DateTime.now();
  String _selectedTiming = 'now'; // 'now', 'earlier_today', 'yesterday', 'custom'

  String _selectedTriggerCategory = 'stress';
  String _selectedTriggerDisplayName = 'Stres / Muncă / Anxietate';

  final TextEditingController _notesController = TextEditingController();
  int _cigarettesCount = 1;
  bool _restartImmediately = true;

  final List<Map<String, String>> _triggers = [
    {
      'category': 'stress',
      'label': 'Stres / Muncă / Anxietate',
      'icon': '😫',
    },
    {
      'category': 'social_alcohol',
      'label': 'Ieșire socială / Alcool / Prieteni',
      'icon': '🍻',
    },
    {
      'category': 'routine_coffee',
      'label': 'Rutină automată (cafea / masă)',
      'icon': '☕',
    },
    {
      'category': 'emotional',
      'label': 'Supărare / Emoții grele / Ceartă',
      'icon': '😢',
    },
    {
      'category': 'boredom',
      'label': 'Plictiseală / Singurătate',
      'icon': '🥱',
    },
    {
      'category': 'intense_craving',
      'label': 'Poftă fizică bruscă și intensă',
      'icon': '⚡',
    },
    {
      'category': 'just_one',
      'label': 'Iluzia „doar un singur fum”',
      'icon': '💭',
    },
    {
      'category': 'other',
      'label': 'Alt motiv',
      'icon': '❓',
    },
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _pickCustomDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _relapseTime,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE11D48),
              surface: Color(0xFF1E1E22),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_relapseTime),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFE11D48),
                surface: Color(0xFF1E1E22),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _relapseTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _selectedTiming = 'custom';
        });
      }
    }
  }

  void _onTimingSelected(String timing) {
    final now = DateTime.now();
    setState(() {
      _selectedTiming = timing;
      if (timing == 'now') {
        _relapseTime = now;
      } else if (timing == 'earlier_today') {
        _relapseTime = now.subtract(const Duration(hours: 3));
      } else if (timing == 'yesterday') {
        _relapseTime = now.subtract(const Duration(days: 1));
      } else if (timing == 'custom') {
        _pickCustomDateTime();
      }
    });
  }

  void _submit() {
    final event = RelapseEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      relapsedAt: _relapseTime,
      smokeFreeDurationSeconds: widget.smokeFreeDurationSeconds,
      triggerCategory: _selectedTriggerCategory,
      triggerDisplayName: _selectedTriggerDisplayName,
      notes: _notesController.text.trim(),
      cigarettesSmoked: _cigarettesCount,
      createdAt: DateTime.now(),
    );

    final result = RelapseResult(
      relapseEvent: event,
      restartImmediately: _restartImmediately,
      newStartTime: _relapseTime,
    );

    Navigator.of(context).pop(result);
  }

  String _formatRelapseTimeString() {
    final h = _relapseTime.hour.toString().padLeft(2, '0');
    final m = _relapseTime.minute.toString().padLeft(2, '0');
    final isToday = _relapseTime.day == DateTime.now().day &&
        _relapseTime.month == DateTime.now().month &&
        _relapseTime.year == DateTime.now().year;
    return isToday ? "Azi la ora $h:$m" : "${_relapseTime.day}.${_relapseTime.month} la ora $h:$m";
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF101013),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.7),
                  blurRadius: 36,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header cu iconiță empatică
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE11D48).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE11D48).withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 22,
                            color: Color(0xFFFB7185),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Ai fumat o țigară?",
                                style: TextStyle(
                                  color: Color(0xFFFAFAFA),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                "Nu te descuraja! Recuperarea e un proces de învățare.",
                                style: TextStyle(
                                  color: Color(0xFFA1A1AA),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Mesaj explicativ pentru utilizator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16161A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.auto_awesome_rounded, size: 15, color: Color(0xFF2DD4BF)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Spune-ne când și ce s-a întâmplat. Asistentul tău AI va învăța din această situație și te va avertiza când vei fi în contexte similare de risc.",
                              style: TextStyle(
                                color: Color(0xFFD4D4D8),
                                fontSize: 11.5,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // SECȚIUNEA 1: CÂND S-A ÎNTÂMPLAT?
                    _buildSectionTitle("1. CÂND S-A ÎNTÂMPLAT?"),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTimingChip(id: 'now', label: "Chiar acum"),
                        _buildTimingChip(id: 'earlier_today', label: "Azi mai devreme"),
                        _buildTimingChip(id: 'yesterday', label: "Ieri"),
                        _buildTimingChip(id: 'custom', label: "Altă oră / zi..."),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickCustomDateTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E24),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFFFB7185)),
                            const SizedBox(width: 6),
                            Text(
                              "Înregistrat la: ${_formatRelapseTimeString()} (apasă pentru modificare)",
                              style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // SECȚIUNEA 2: DE CE AI SIMȚIT NEVOIA? (DECLANȘATOR)
                    _buildSectionTitle("2. CARE A FOST DECLANȘATORUL PRINCIPAL?"),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _triggers.map((item) {
                        final isSelected = _selectedTriggerCategory == item['category'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTriggerCategory = item['category']!;
                              _selectedTriggerDisplayName = item['label']!;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFE11D48).withValues(alpha: 0.18)
                                  : const Color(0xFF16161A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFE11D48).withValues(alpha: 0.5)
                                    : Colors.white.withValues(alpha: 0.07),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(item['icon']!, style: const TextStyle(fontSize: 13)),
                                const SizedBox(width: 6),
                                Text(
                                  item['label']!,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : const Color(0xFFA1A1AA),
                                    fontSize: 11.5,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 18),

                    // SECȚIUNEA 3: DETALII SITUAȚIE (TEXT PENTRU AI)
                    _buildSectionTitle("3. CE S-A ÎNTÂMPLAT MAI EXACT? (PENTRU AI)"),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white, fontSize: 12.5),
                      decoration: InputDecoration(
                        hintText: "Unde te aflai? Cu cine erai sau ce ai simțit? (ex: eram la terasă după o zi grea și când am văzut că toți fumau, am cedat...)",
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11.5),
                        filled: true,
                        fillColor: const Color(0xFF16161A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE11D48)),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // SECȚIUNEA 4: CÂTE ȚIGĂRI AI FUMAT?
                    _buildSectionTitle("4. CÂTE ȚIGĂRI AI FUMAT?"),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildCigCountChip(count: 1, label: "1 țigară"),
                        const SizedBox(width: 8),
                        _buildCigCountChip(count: 2, label: "2 - 3 țigări"),
                        const SizedBox(width: 8),
                        _buildCigCountChip(count: 5, label: "Mai multe"),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // OPȚIUNE REPORNIRE IMEDIATĂ
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16161A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _restartImmediately,
                            activeColor: const Color(0xFFE11D48),
                            onChanged: (val) {
                              setState(() {
                                _restartImmediately = val ?? true;
                              });
                            },
                          ),
                          const Expanded(
                            child: Text(
                              "Repornește noul cronometru imediat de la ora acestui episod",
                              style: TextStyle(color: Color(0xFFE4E4E7), fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // BUTOANE DE ACȚIUNE
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              "Anulează",
                              style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 12.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE11D48),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              "Salvează și Repornește",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
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
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFA1A1AA),
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTimingChip({required String id, required String label}) {
    final isSelected = _selectedTiming == id;
    return GestureDetector(
      onTap: () => _onTimingSelected(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF27272A) : const Color(0xFF16161A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFA1A1AA),
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildCigCountChip({required int count, required String label}) {
    final isSelected = _cigarettesCount == count;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _cigarettesCount = count;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF27272A) : const Color(0xFF16161A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFFA1A1AA),
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
