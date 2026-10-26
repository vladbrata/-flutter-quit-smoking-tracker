import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_quit_smoking/pages/models/relapse_model.dart';

class CravingEvent {
  final String id;
  final DateTime timestamp;
  final String triggerCategory; // 'stress', 'coffee', 'meal', 'social_alcohol', 'boredom', 'emotional', 'habit', 'driving', 'other'
  final String triggerDisplayName;
  final String reason; // "De ce ai o poftă" - motivul scris detaliat de utilizator
  final int intensity; // 1 to 10
  final bool overcame; // true dacă a depășit pofta
  final String? breathingSessionId;
  final DateTime createdAt;

  CravingEvent({
    required this.id,
    required this.timestamp,
    required this.triggerCategory,
    required this.triggerDisplayName,
    required this.reason,
    this.intensity = 5,
    this.overcame = false,
    this.breathingSessionId,
    required this.createdAt,
  });

  int get hourOfDay => timestamp.hour;
  int get dayOfWeek => timestamp.weekday; // 1 = Luni, 7 = Duminică

  String get timeOfDayLabel {
    final h = timestamp.hour;
    if (h >= 5 && h < 11) return "Dimineață";
    if (h >= 11 && h < 15) return "Prânz";
    if (h >= 15 && h < 19) return "După-amiază";
    if (h >= 19 && h < 23) return "Seară";
    return "Noapte";
  }

  String get formattedDate {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    return "$day.$month.${timestamp.year} la $h:$m";
  }

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'triggerCategory': triggerCategory,
      'triggerDisplayName': triggerDisplayName,
      'reason': reason,
      'intensity': intensity,
      'overcame': overcame,
      'breathingSessionId': breathingSessionId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'timestamp': Timestamp.fromDate(timestamp),
      'hourOfDay': hourOfDay,
      'formattedTime': formattedTime,
      'triggerCategory': triggerCategory,
      'triggerDisplayName': triggerDisplayName,
      'reason': reason,
      'intensity': intensity,
      'overcame': overcame,
      'breathingSessionId': breathingSessionId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CravingEvent.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return CravingEvent(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: parseDate(map['timestamp']),
      triggerCategory: map['triggerCategory']?.toString() ?? 'other',
      triggerDisplayName: map['triggerDisplayName']?.toString() ?? 'Nespecificat',
      reason: map['reason']?.toString() ?? '',
      intensity: (map['intensity'] as num?)?.toInt() ?? 5,
      overcame: map['overcame'] == true,
      breathingSessionId: map['breathingSessionId']?.toString(),
      createdAt: parseDate(map['createdAt']),
    );
  }

  CravingEvent copyWith({
    bool? overcame,
    String? breathingSessionId,
    String? reason,
  }) {
    return CravingEvent(
      id: id,
      timestamp: timestamp,
      triggerCategory: triggerCategory,
      triggerDisplayName: triggerDisplayName,
      reason: reason ?? this.reason,
      intensity: intensity,
      overcame: overcame ?? this.overcame,
      breathingSessionId: breathingSessionId ?? this.breathingSessionId,
      createdAt: createdAt,
    );
  }
}

class CravingSummary {
  final int totalCravings;
  final int cravingsToday;
  final List<int> peakHours; // Orele cu cele mai multe pofte (ex: [9, 14, 21])
  final String? mostCommonTrigger;
  final List<String> topReasons; // Motivele recente notate de utilizator
  final CravingEvent? lastCraving;
  final List<CravingEvent> history;

  CravingSummary({
    required this.totalCravings,
    required this.cravingsToday,
    required this.peakHours,
    this.mostCommonTrigger,
    required this.topReasons,
    this.lastCraving,
    required this.history,
  });

  /// Verifică dacă ora curentă este aproape de oricare dintre orele de vârf ale poftelor
  bool isNearCravingPeakHour(DateTime now, {int windowHours = 1}) {
    final currentHour = now.hour;
    for (final peak in peakHours) {
      final diff = (currentHour - peak).abs();
      if (diff <= windowHours || diff >= (24 - windowHours)) {
        return true;
      }
    }
    return false;
  }
}

enum RiskType {
  none,
  cravingPrediction, // AI-ul anticipează o poftă bazat pe poftele anterioare din același interval orar
  relapseProximity,  // AI-ul detectează apropierea de ora la care a avut loc o recidivă
  recentRelapse48h,  // Fereastră critică în primele 48 de ore după o recidivă
  routineMatch,      // Coincide cu rutina obișnuită declarată de utilizator
}

class CombinedRiskPrediction {
  final bool isAtRisk;
  final RiskType riskType;
  final String alertTitle;
  final String riskReason;
  final List<String> relevantPastReasons;
  final int? peakHour;

  const CombinedRiskPrediction({
    required this.isAtRisk,
    required this.riskType,
    required this.alertTitle,
    required this.riskReason,
    this.relevantPastReasons = const [],
    this.peakHour,
  });

  static const CombinedRiskPrediction safe = CombinedRiskPrediction(
    isAtRisk: false,
    riskType: RiskType.none,
    alertTitle: 'Ghid zilnic',
    riskReason: '',
  );

  /// Evaluează combinat istoricul de recidive, istoricul de pofte și rutina pentru a prezice situații de risc
  static CombinedRiskPrediction predict({
    required DateTime now,
    required String routine,
    required RelapseSummary? relapseSummary,
    required CravingSummary? cravingSummary,
  }) {
    // 1. Verificare recidivă recentă (< 48h)
    if (relapseSummary != null && relapseSummary.lastRelapse != null) {
      final diffHours = now.difference(relapseSummary.lastRelapse!.relapsedAt).inHours;
      if (diffHours >= 0 && diffHours < 48) {
        final lastR = relapseSummary.lastRelapse!;
        return CombinedRiskPrediction(
          isAtRisk: true,
          riskType: RiskType.recentRelapse48h,
          alertTitle: 'Fereastră vulnerabilă',
          riskReason: 'Au trecut ${diffHours}h de la ultima recidivă (${lastR.triggerDisplayName}). Menține atenția sporită.',
          relevantPastReasons: lastR.notes.isNotEmpty ? [lastR.notes] : [],
          peakHour: lastR.hourOfDay,
        );
      }
    }

    // 2. Verificare proximitate oră recidivă (+/- 1h)
    if (relapseSummary != null && relapseSummary.history.isNotEmpty) {
      for (final r in relapseSummary.history) {
        final diff = (now.hour - r.hourOfDay).abs();
        if (diff <= 1 || diff >= 23) {
          final hourStr = "${r.hourOfDay.toString().padLeft(2, '0')}:00";
          return CombinedRiskPrediction(
            isAtRisk: true,
            riskType: RiskType.relapseProximity,
            alertTitle: 'Risc de recidivă',
            riskReason: 'În jurul orei $hourStr ai cedat anterior (${r.triggerDisplayName}).',
            relevantPastReasons: r.notes.isNotEmpty ? [r.notes] : [],
            peakHour: r.hourOfDay,
          );
        }
      }
    }

    // 3. Verificare PREDICȚIE POFTĂ (Peak craving hours +/- 1h)
    if (cravingSummary != null && cravingSummary.peakHours.isNotEmpty) {
      for (final peak in cravingSummary.peakHours) {
        final diff = (now.hour - peak).abs();
        if (diff <= 1 || diff >= 23) {
          final matchingReasons = cravingSummary.history
              .where((c) => (c.hourOfDay - peak).abs() <= 1 && c.reason.trim().isNotEmpty)
              .map((c) => c.reason.trim())
              .take(3)
              .toList();

          final peakStr = "${peak.toString().padLeft(2, '0')}:00";
          final reasonSnippet = matchingReasons.isNotEmpty
              ? " (notat: \"${matchingReasons.first}\")"
              : "";

          return CombinedRiskPrediction(
            isAtRisk: true,
            riskType: RiskType.cravingPrediction,
            alertTitle: 'Predispoziție la poftă',
            riskReason: 'În jurul orei $peakStr apar de obicei pofte$reasonSnippet.',
            relevantPastReasons: matchingReasons,
            peakHour: peak,
          );
        }
      }
    }

    // 4. Verificare rutină de fumat declarată
    if (routine.isNotEmpty) {
      final rLower = routine.toLowerCase();
      final h = now.hour;
      bool routineMatches = false;
      String matchText = '';

      if ((rLower.contains('cafea') || rLower.contains('dimine')) && (h >= 6 && h <= 10)) {
        routineMatches = true;
        matchText = 'Intervalul asociat cafelei de dimineață.';
      } else if (rLower.contains('pranz') && (h >= 12 && h <= 14)) {
        routineMatches = true;
        matchText = 'Intervalul asociat pauzei de prânz.';
      } else if ((rLower.contains('seara') || rLower.contains('noapte')) && (h >= 19 && h <= 23)) {
        routineMatches = true;
        matchText = 'Intervalul asociat relaxării de seară.';
      }

      if (routineMatches) {
        return CombinedRiskPrediction(
          isAtRisk: true,
          riskType: RiskType.routineMatch,
          alertTitle: 'Rutină activă',
          riskReason: matchText,
          relevantPastReasons: [routine],
          peakHour: h,
        );
      }
    }

    return CombinedRiskPrediction.safe;
  }
}
