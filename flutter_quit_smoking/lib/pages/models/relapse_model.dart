import 'package:cloud_firestore/cloud_firestore.dart';

class RelapseEvent {
  final String id;
  final DateTime relapsedAt;
  final int smokeFreeDurationSeconds;
  final String triggerCategory; // 'stress', 'social_alcohol', 'routine_coffee', 'emotional', 'boredom', 'intense_craving', 'just_one', 'other'
  final String triggerDisplayName;
  final String notes;
  final int cigarettesSmoked;
  final DateTime createdAt;

  RelapseEvent({
    required this.id,
    required this.relapsedAt,
    required this.smokeFreeDurationSeconds,
    required this.triggerCategory,
    required this.triggerDisplayName,
    this.notes = '',
    this.cigarettesSmoked = 1,
    required this.createdAt,
  });

  int get hourOfDay => relapsedAt.hour;
  int get dayOfWeek => relapsedAt.weekday; // 1 = Luni, 7 = Duminică

  String get timeOfDayLabel {
    final h = relapsedAt.hour;
    if (h >= 5 && h < 11) return "Dimineață";
    if (h >= 11 && h < 15) return "Prânz";
    if (h >= 15 && h < 19) return "După-amiază";
    if (h >= 19 && h < 23) return "Seară";
    return "Noapte";
  }

  String get formattedDate {
    final h = relapsedAt.hour.toString().padLeft(2, '0');
    final m = relapsedAt.minute.toString().padLeft(2, '0');
    final day = relapsedAt.day.toString().padLeft(2, '0');
    final month = relapsedAt.month.toString().padLeft(2, '0');
    return "$day.$month.${relapsedAt.year} la $h:$m ($timeOfDayLabel)";
  }

  String get smokeFreeDurationFormatted {
    final duration = Duration(seconds: smokeFreeDurationSeconds);
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    if (days > 0) return "$days zile, $hours ore și $minutes min";
    if (hours > 0) return "$hours ore și $minutes min";
    return "$minutes minute";
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'relapsedAt': relapsedAt.toIso8601String(),
      'smokeFreeDurationSeconds': smokeFreeDurationSeconds,
      'triggerCategory': triggerCategory,
      'triggerDisplayName': triggerDisplayName,
      'notes': notes,
      'cigarettesSmoked': cigarettesSmoked,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'relapsedAt': Timestamp.fromDate(relapsedAt),
      'smokeFreeDurationSeconds': smokeFreeDurationSeconds,
      'triggerCategory': triggerCategory,
      'triggerDisplayName': triggerDisplayName,
      'notes': notes,
      'cigarettesSmoked': cigarettesSmoked,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory RelapseEvent.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return RelapseEvent(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      relapsedAt: parseDate(map['relapsedAt']),
      smokeFreeDurationSeconds: (map['smokeFreeDurationSeconds'] as num?)?.toInt() ?? 0,
      triggerCategory: map['triggerCategory']?.toString() ?? 'other',
      triggerDisplayName: map['triggerDisplayName']?.toString() ?? 'Nespecificat',
      notes: map['notes']?.toString() ?? '',
      cigarettesSmoked: (map['cigarettesSmoked'] as num?)?.toInt() ?? 1,
      createdAt: parseDate(map['createdAt']),
    );
  }
}

class RelapseRiskAssessment {
  final bool isAtRisk;
  final String riskTitle;
  final String riskReason;
  final RelapseEvent? matchingRelapse;
  final String preventativeAction;

  const RelapseRiskAssessment({
    required this.isAtRisk,
    this.riskTitle = '',
    this.riskReason = '',
    this.matchingRelapse,
    this.preventativeAction = '',
  });

  static const safe = RelapseRiskAssessment(isAtRisk: false);
}

class RelapseSummary {
  final int totalRelapses;
  final RelapseEvent? lastRelapse;
  final String? mostCommonTrigger;
  final List<RelapseEvent> history;

  RelapseSummary({
    required this.totalRelapses,
    this.lastRelapse,
    this.mostCommonTrigger,
    this.history = const [],
  });

  /// Evaluează dacă utilizatorul se află într-o situație de risc similară cu un relapse din trecut
  RelapseRiskAssessment detectRiskSituation({
    required DateTime now,
    required String routine,
  }) {
    if (history.isEmpty) return RelapseRiskAssessment.safe;

    // 0. Fază critică post-episod recent (primele 48 de ore sunt cele mai periculoase pentru recidivă)
    if (lastRelapse != null) {
      final hoursSince = now.difference(lastRelapse!.relapsedAt).inHours;
      if (hoursSince >= 0 && hoursSince <= 48) {
        return RelapseRiskAssessment(
          isAtRisk: true,
          riskTitle: "Fază critică post-recidivă (primele 48h)",
          riskReason: "Corpul și mintea încă se recalibrează după episodul recent (${lastRelapse!.triggerDisplayName}). Pericolul de re-fumat este la cote maxime.",
          matchingRelapse: lastRelapse,
          preventativeAction: "Refuză ferm orice nouă țigară. Fă exerciții de respirație și bea apă rece ori de câte ori simți agitație.",
        );
      }
    }

    final lowerRoutine = routine.toLowerCase();
    final currentHour = now.hour;
    final currentWeekday = now.weekday;

    for (final relapse in history) {
      // 1. Potrivire orară directă (aceeași fereastră orară +/- 1 oră)
      final hourDiff = (currentHour - relapse.hourOfDay).abs();
      final isNearHour = hourDiff <= 1 || hourDiff == 23; // gestionează trecerea de miezul nopții

      // 2. Potrivire pe categoria de declanșator legată de rutina declarată sau momentul zilei
      bool matchesRoutineOrContext = false;
      if (relapse.triggerCategory == 'stress' &&
          (lowerRoutine.contains('stres') || lowerRoutine.contains('munc') || (currentHour >= 14 && currentHour <= 19))) {
        matchesRoutineOrContext = true;
      } else if (relapse.triggerCategory == 'social_alcohol' &&
          (lowerRoutine.contains('alcool') || lowerRoutine.contains('bere') || lowerRoutine.contains('ieș') || currentWeekday >= 5)) {
        matchesRoutineOrContext = true;
      } else if (relapse.triggerCategory == 'routine_coffee' &&
          (lowerRoutine.contains('cafea') || (currentHour >= 6 && currentHour <= 11))) {
        matchesRoutineOrContext = true;
      } else if (relapse.triggerCategory == 'boredom' || relapse.triggerCategory == 'emotional') {
        matchesRoutineOrContext = isNearHour;
      }

      if (isNearHour && matchesRoutineOrContext) {
        return RelapseRiskAssessment(
          isAtRisk: true,
          riskTitle: "Fereastră de vulnerabilitate detectată",
          riskReason: "În trecut ai cedat la ora ${relapse.hourOfDay}:00 din cauza: ${relapse.triggerDisplayName}${relapse.notes.isNotEmpty ? ' ("${relapse.notes}")' : ''}.",
          matchingRelapse: relapse,
          preventativeAction: "Fă 3 cicluri de Box Breathing și bea un pahar mare de apă rece înainte de a lua orice decizie.",
        );
      }

      // Potrivire doar pe oră dacă este foarte apropiată
      if (isNearHour) {
        return RelapseRiskAssessment(
          isAtRisk: true,
          riskTitle: "Oră sensibilă conform istoricului tău",
          riskReason: "La această oră (${relapse.hourOfDay}:00) a avut loc un episod de relapse anterior (${relapse.triggerDisplayName}).",
          matchingRelapse: relapse,
          preventativeAction: "Schimbă activitatea sau mediul pentru 5 minute pentru a dezamorsa impulsul.",
        );
      }
    }

    return RelapseRiskAssessment.safe;
  }

  /// Descriere concentrată pentru prompt-ul AI Gemini
  String toPromptDescription() {
    if (totalRelapses == 0) {
      return "Utilizatorul nu a înregistrat niciun relapse anterior.";
    }

    final StringBuffer buffer = StringBuffer();
    buffer.write("Istoric relapse-uri: $totalRelapses episoade anterioare. ");
    if (mostCommonTrigger != null) {
      buffer.write("Declanșatorul cel mai frecvent a fost: $mostCommonTrigger. ");
    }
    if (lastRelapse != null) {
      final last = lastRelapse!;
      buffer.write(
        "Ultimul relapse a avut loc pe ${last.formattedDate}, după ${last.smokeFreeDurationFormatted} fără fumat. "
        "Motivul declarat: ${last.triggerDisplayName}. "
      );
      if (last.notes.trim().isNotEmpty) {
        buffer.write("Notele scrise de utilizator despre ce s-a întâmplat: \"${last.notes.trim()}\". ");
      }
      buffer.write("A fumat ${last.cigarettesSmoked} țigară/țigări. ");
    }

    return buffer.toString().trim();
  }
}
