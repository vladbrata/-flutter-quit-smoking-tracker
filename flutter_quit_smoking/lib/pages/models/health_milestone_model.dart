import 'package:flutter/material.dart';

class HealthMilestone {
  final String title;
  final String description;
  final Duration duration;
  final IconData icon;

  const HealthMilestone({
    required this.title,
    required this.description,
    required this.duration,
    this.icon = Icons.favorite_rounded,
  });
}

class HealthMilestoneService {
  static const List<HealthMilestone> milestones = [
    // Short-Term
    HealthMilestone(
      title: "20 Minute",
      description: "Pulsul și tensiunea arterială revin la valori normale.",
      duration: Duration(minutes: 20),
      icon: Icons.monitor_heart_rounded,
    ),
    HealthMilestone(
      title: "8 Ore",
      description: "Monoxidul de carbon din sânge scade la 50%. Nivelul de oxigen revine la normal.",
      duration: Duration(hours: 8),
      icon: Icons.air_rounded,
    ),
    HealthMilestone(
      title: "24 Ore",
      description: "Riscul de infarct începe să scadă. Plămânii încep curățarea mucusului.",
      duration: Duration(hours: 24),
      icon: Icons.cleaning_services_rounded,
    ),
    HealthMilestone(
      title: "48 Ore",
      description: "Nicotina a fost complet eliminată! Gustul și mirosul încep să se refacă.",
      duration: Duration(hours: 48),
      icon: Icons.restaurant_rounded,
    ),
    HealthMilestone(
      title: "72 Ore",
      description: "Respirația devine mult mai ușoară. Bronhiile se relaxează și energia crește.",
      duration: Duration(hours: 72),
      icon: Icons.spa_rounded,
    ),
    // Medium-Term
    HealthMilestone(
      title: "2 Săptămâni",
      description: "Circulația sanguină se îmbunătățește. Mersul pe jos și sportul devin mai ușoare.",
      duration: Duration(days: 14),
      icon: Icons.directions_run_rounded,
    ),
    HealthMilestone(
      title: "1 Lună",
      description: "Cilii pulmonari se regenerează. Tusea și oboseala respiratorie scad simțitor.",
      duration: Duration(days: 30),
      icon: Icons.nature_people_rounded,
    ),
    HealthMilestone(
      title: "1 An",
      description: "Riscul de boală coronariană scade la jumătate față de cel al unui fumător.",
      duration: Duration(days: 365),
      icon: Icons.favorite_rounded,
    ),
    // Long-Term
    HealthMilestone(
      title: "5 Ani",
      description: "Riscul de accident vascular cerebral devine egal cu cel al unui nefumător.",
      duration: Duration(days: 365 * 5),
      icon: Icons.shield_rounded,
    ),
    HealthMilestone(
      title: "10 Ani",
      description: "Riscul de deces din cauza cancerului pulmonar scade la jumătate.",
      duration: Duration(days: 365 * 10),
      icon: Icons.health_and_safety_rounded,
    ),
    HealthMilestone(
      title: "15 Ani",
      description: "Riscul de afecțiuni cardiace coronariene devine egal cu al unui nefumător.",
      duration: Duration(days: 365 * 15),
      icon: Icons.verified_user_rounded,
    ),
    HealthMilestone(
      title: "20 Ani",
      description: "Riscul general de deces legat de fumat revine complet la cel al unui nefumător.",
      duration: Duration(days: 365 * 20),
      icon: Icons.celebration_rounded,
    ),
  ];

  /// Calculează progresul total în roadmap (0.0 până la 1.0)
  /// Interpolat lin între etape, astfel încât utilizatorul să vadă avansul încă din primele minute.
  static double calculateOverallProgress(Duration elapsed) {
    if (elapsed <= Duration.zero) return 0.0;
    if (elapsed >= milestones.last.duration) return 1.0;

    for (int i = 0; i < milestones.length; i++) {
      if (elapsed < milestones[i].duration) {
        final Duration prevDuration = i == 0 ? Duration.zero : milestones[i - 1].duration;
        final Duration currentDuration = milestones[i].duration;
        final double segmentDurationMs = (currentDuration - prevDuration).inMilliseconds.toDouble();
        final double elapsedInSegmentMs = (elapsed - prevDuration).inMilliseconds.toDouble();
        final double segmentFraction = (elapsedInSegmentMs / segmentDurationMs).clamp(0.0, 1.0);
        return ((i + segmentFraction) / milestones.length).clamp(0.0, 1.0);
      }
    }
    return 1.0;
  }

  /// Numărul de etape completate
  static int getCompletedCount(Duration elapsed) {
    int count = 0;
    for (final m in milestones) {
      if (elapsed >= m.duration) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  /// Ultima etapă atinsă (sau null dacă e sub prima etapă)
  static HealthMilestone? getCurrentMilestone(Duration elapsed) {
    HealthMilestone? last;
    for (final m in milestones) {
      if (elapsed >= m.duration) {
        last = m;
      } else {
        break;
      }
    }
    return last;
  }

  /// Următoarea etapă către care se avansează (sau null dacă toate sunt atinse)
  static HealthMilestone? getNextMilestone(Duration elapsed) {
    for (final m in milestones) {
      if (elapsed < m.duration) {
        return m;
      }
    }
    return null;
  }

  /// Progresul către următoarea etapă (0.0 la 1.0)
  static double getNextMilestoneProgress(Duration elapsed) {
    for (int i = 0; i < milestones.length; i++) {
      if (elapsed < milestones[i].duration) {
        final Duration prevDuration = i == 0 ? Duration.zero : milestones[i - 1].duration;
        final Duration currentDuration = milestones[i].duration;
        final double segmentDurationMs = (currentDuration - prevDuration).inMilliseconds.toDouble();
        final double elapsedInSegmentMs = (elapsed - prevDuration).inMilliseconds.toDouble();
        return (elapsedInSegmentMs / segmentDurationMs).clamp(0.0, 1.0);
      }
    }
    return 1.0;
  }

  /// Durata rămasă până la următoarea etapă
  static Duration getTimeRemainingToNext(Duration elapsed) {
    final next = getNextMilestone(elapsed);
    if (next == null) return Duration.zero;
    final remaining = next.duration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Formatează durata rămasă într-un text scurt și prietenos (ex: "în 4h 15m", "în 3 zile", "în 18m")
  static String formatTimeRemaining(Duration remaining) {
    if (remaining <= Duration.zero) return "atingi acum!";

    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    final minutes = remaining.inMinutes.remainder(60);

    if (days >= 365) {
      final years = (days / 365).toStringAsFixed(1);
      return "în ~$years ani";
    } else if (days >= 30) {
      final months = (days / 30).toStringAsFixed(0);
      return "în ~$months luni";
    } else if (days > 0) {
      if (hours > 0) {
        return "în ${days}z ${hours}h";
      }
      return "în $days zile";
    } else if (hours > 0) {
      if (minutes > 0) {
        return "în ${hours}h ${minutes}m";
      }
      return "în $hours ore";
    } else if (minutes > 0) {
      return "în $minutes min";
    } else {
      return "în ${remaining.inSeconds} secunde";
    }
  }
}
