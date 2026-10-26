import 'package:cloud_firestore/cloud_firestore.dart';

class BreathingSession {
  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSeconds;
  final String technique; // 'boxBreathing' | 'relax478'
  final bool switchedTechnique;
  final int completedCycles;
  final int targetCycles;
  final int pauseCount;
  final int tipsViewedCount;
  final String completionStatus; // 'completed' | 'overcame_craving' | 'interrupted'

  BreathingSession({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    required this.technique,
    this.switchedTechnique = false,
    required this.completedCycles,
    this.targetCycles = 4,
    this.pauseCount = 0,
    this.tipsViewedCount = 0,
    required this.completionStatus,
  });

  String get techniqueDisplayName {
    if (technique == 'relax478') return 'Relaxare (4-7-8)';
    return 'Box Breathing (4-4-4-4)';
  }

  String get statusDisplayName {
    switch (completionStatus) {
      case 'completed':
        return 'Toate ciclurile finalizate';
      case 'overcame_craving':
        return 'Poftă depășită cu succes';
      case 'interrupted':
      default:
        return 'Sesiune parțială';
    }
  }

  bool get isSuccessful =>
      completionStatus == 'completed' ||
      completionStatus == 'overcame_craving' ||
      completedCycles >= targetCycles;

  String get formattedStartTime {
    final hour = startedAt.hour.toString().padLeft(2, '0');
    final minute = startedAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'durationSeconds': durationSeconds,
      'technique': technique,
      'switchedTechnique': switchedTechnique,
      'completedCycles': completedCycles,
      'targetCycles': targetCycles,
      'pauseCount': pauseCount,
      'tipsViewedCount': tipsViewedCount,
      'completionStatus': completionStatus,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'startedAt': Timestamp.fromDate(startedAt),
      'endedAt': Timestamp.fromDate(endedAt),
      'durationSeconds': durationSeconds,
      'technique': technique,
      'switchedTechnique': switchedTechnique,
      'completedCycles': completedCycles,
      'targetCycles': targetCycles,
      'pauseCount': pauseCount,
      'tipsViewedCount': tipsViewedCount,
      'completionStatus': completionStatus,
    };
  }

  factory BreathingSession.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return BreathingSession(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      startedAt: parseDate(map['startedAt']),
      endedAt: parseDate(map['endedAt']),
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      technique: map['technique']?.toString() ?? 'boxBreathing',
      switchedTechnique: map['switchedTechnique'] == true,
      completedCycles: (map['completedCycles'] as num?)?.toInt() ?? 0,
      targetCycles: (map['targetCycles'] as num?)?.toInt() ?? 4,
      pauseCount: (map['pauseCount'] as num?)?.toInt() ?? 0,
      tipsViewedCount: (map['tipsViewedCount'] as num?)?.toInt() ?? 0,
      completionStatus: map['completionStatus']?.toString() ?? 'interrupted',
    );
  }
}

class BreathingSummary {
  final int totalSessions;
  final int totalSessionsToday;
  final int successfulSessionsToday;
  final int totalSecondsToday;
  final BreathingSession? lastSession;
  final String preferredTechnique;

  BreathingSummary({
    required this.totalSessions,
    required this.totalSessionsToday,
    required this.successfulSessionsToday,
    required this.totalSecondsToday,
    this.lastSession,
    required this.preferredTechnique,
  });

  /// Descriere concisă și detaliată pentru prompt-ul AI Gemini
  String toPromptDescription() {
    if (totalSessions == 0) {
      return "Utilizatorul nu a folosit încă exercițiile de respirație ghidată (SOS Craving) din aplicație.";
    }

    final StringBuffer buffer = StringBuffer();
    buffer.write("Istoric respirație: $totalSessions sesiuni în total, ");
    buffer.write("$totalSessionsToday sesiuni astăzi ($successfulSessionsToday cu poftă depășită cu succes). ");

    if (lastSession != null) {
      final last = lastSession!;
      final isToday = last.startedAt.year == DateTime.now().year &&
          last.startedAt.month == DateTime.now().month &&
          last.startedAt.day == DateTime.now().day;
      final dayStr = isToday ? "astăzi" : "recent";
      buffer.write(
        "Ultima sesiune: $dayStr la ora ${last.formattedStartTime}, "
        "tehnica folosită: ${last.techniqueDisplayName}, "
        "cicluri completate: ${last.completedCycles}/${last.targetCycles}, "
        "durată: ${last.durationSeconds}s, "
        "rezultat: ${last.statusDisplayName}. ",
      );
      if (last.pauseCount > 0) {
        buffer.write("A folosit pauza de ${last.pauseCount} ori. ");
      }
      if (last.switchedTechnique) {
        buffer.write("A experimentat ambele tehnici de respirație în aceeași sesiune. ");
      }
    }

    return buffer.toString().trim();
  }
}
