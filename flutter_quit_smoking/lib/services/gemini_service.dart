import 'package:flutter/foundation.dart';
import 'package:flutter_quit_smoking/pages/models/breathing_session_model.dart';
import 'package:flutter_quit_smoking/pages/models/craving_model.dart';
import 'package:flutter_quit_smoking/pages/models/goal_model.dart';
import 'package:flutter_quit_smoking/pages/models/relapse_model.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  static const String _prefApiKey = 'gemini_api_key';

  // Cache în memorie pentru a evita apelurile repetitive inutile (valabil max 5 minute pentru dinamism crescut)
  String? _cachedRoutineTip;
  String? _cachedRoutineKey;
  DateTime? _lastRoutineTipTime;
  int _refreshCounter = 0;

  /// Returnează cheia API din mediu (--dart-define=GEMINI_API_KEY=...)
  /// sau salvată de utilizator în SharedPreferences
  Future<String?> getApiKey() async {
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envKey.isNotEmpty) {
      return envKey;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString(_prefApiKey);
      if (savedKey != null && savedKey.trim().isNotEmpty) {
        return savedKey.trim();
      }
    } catch (_) {}
    return null;
  }

  /// Salvează cheia API introdusă de utilizator
  Future<void> setApiKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (key.trim().isEmpty) {
        await prefs.remove(_prefApiKey);
      } else {
        await prefs.setString(_prefApiKey, key.trim());
      }
    } catch (_) {}
    // Resetare cache la schimbarea cheii
    _cachedRoutineTip = null;
  }

  /// Șterge cheia API salvată
  Future<void> clearApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefApiKey);
    } catch (_) {}
    _cachedRoutineTip = null;
  }

  /// Determină eticheta momentului zilei
  String getTimeOfDayLabel(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 11) {
      return "🌅 Dimineață";
    } else if (hour >= 11 && hour < 15) {
      return "☀️ Prânz";
    } else if (hour >= 15 && hour < 19) {
      return "🌇 După-amiază";
    } else if (hour >= 19 && hour < 23) {
      return "🌆 Seară";
    } else {
      return "🌙 Noapte";
    }
  }

  /// Generează un sfat personalizat și specific, incluzând predicții AI din pofte, recidive, respirație și obiective financiare
  Future<String> getRoutineTip({
    required String routine,
    required Duration timeElapsed,
    required int cigarettesAvoided,
    required double moneySaved,
    double dailyCost = 0.0,
    Goal? selectedGoal,
    BreathingSummary? breathingSummary,
    RelapseSummary? relapseSummary,
    CravingSummary? cravingSummary,
    CombinedRiskPrediction? riskPrediction,
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    final timeLabel = getTimeOfDayLabel(now);
    final lastSessionId = breathingSummary?.lastSession?.id ?? 'none';
    final goalKey = selectedGoal != null ? "${selectedGoal.name}_${selectedGoal.price}" : "none";
    final lastRelapseId = relapseSummary?.lastRelapse?.id ?? 'none';

    final prediction = riskPrediction ??
        CombinedRiskPrediction.predict(
          now: now,
          routine: routine,
          relapseSummary: relapseSummary,
          cravingSummary: cravingSummary,
        );

    if (forceRefresh) {
      _refreshCounter++;
      _cachedRoutineTip = null;
    }

    final fiveMinuteSlot = now.minute ~/ 5;
    final riskFlag = prediction.isAtRisk ? prediction.riskType.name : "SAFE";
    final cravingCount = cravingSummary?.totalCravings ?? 0;
    final cacheKey = "${timeLabel}_${now.hour}_${fiveMinuteSlot}_${routine}_${goalKey}_${lastSessionId}_${lastRelapseId}_${cravingCount}_${riskFlag}_$_refreshCounter";

    // Cache-ul expiră după 5 minute pentru ca mesajele să se schimbe frecvent pe parcursul zilei
    if (!forceRefresh &&
        _cachedRoutineTip != null &&
        _cachedRoutineKey == cacheKey &&
        _lastRoutineTipTime != null &&
        now.difference(_lastRoutineTipTime!).inMinutes < 5) {
      return _cachedRoutineTip!;
    }

    final apiKey = await getApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.85,
            maxOutputTokens: 250,
          ),
        );

        final days = timeElapsed.inDays;
        final hours = timeElapsed.inHours % 24;
        final timeString = days > 0 ? "$days zile și $hours ore" : "$hours ore";

        final StringBuffer promptBuffer = StringBuffer();
        promptBuffer.writeln("Ești un ghid AI avansat de renunțare la fumat, extrem de empatic, intuitiv, realist, specific și proactiv.");
        promptBuffer.writeln("DATE PROGRES UTILIZATOR:");
        promptBuffer.writeln("- Timp fără fumat: $timeString.");
        promptBuffer.writeln("- Țigări evitate: $cigarettesAvoided.");
        promptBuffer.writeln("- Bani economisiți din fumat: ${moneySaved.toStringAsFixed(1)} RON.");
        promptBuffer.writeln("- Momentul curent: $timeLabel (ora exactă ${now.hour}:${now.minute.toString().padLeft(2, '0')}).");
        promptBuffer.writeln("- Declanșatori / când fuma de obicei (rutină): \"${routine.isEmpty ? 'Nespecificate explicit' : routine}\".");

        if (selectedGoal != null) {
          final pInRon = selectedGoal.priceInRon;
          final pct = selectedGoal.calculatePercentage(moneySaved);
          final remRon = selectedGoal.remainingRon(moneySaved);
          final daysLeft = selectedGoal.daysRemaining(moneySaved, dailyCost);
          promptBuffer.writeln("- OBIECTIV FINANCIAR SETAT:");
          promptBuffer.writeln("  * Nume: \"${selectedGoal.name}\"");
          promptBuffer.writeln("  * Preț țintă: ${selectedGoal.price} ${selectedGoal.currency} (~${pInRon.toStringAsFixed(0)} RON)");
          promptBuffer.writeln("  * Progres atins: $pct% (${moneySaved.toStringAsFixed(1)} RON adunați)");
          promptBuffer.writeln("  * Mai are de strâns: ${remRon.toStringAsFixed(1)} RON");
          if (daysLeft > 0) {
            promptBuffer.writeln("  * Timp estimat până la atingere: aprox. $daysLeft zile.");
          }
        } else {
          promptBuffer.writeln("- Obiectiv financiar: Neconfigurat încă.");
        }

        if (breathingSummary != null) {
          promptBuffer.writeln("- SISTEM DE RESPIRAȚIE (SOS CRAVING) & INTERACȚIUNE:");
          promptBuffer.writeln("  * ${breathingSummary.toPromptDescription()}");
        }

        if (cravingSummary != null && cravingSummary.totalCravings > 0) {
          promptBuffer.writeln("- ISTORIC POFTE (CRAVINGS) ÎNREGISTRATE:");
          promptBuffer.writeln("  * Total pofte înregistrate: ${cravingSummary.totalCravings} (azi: ${cravingSummary.cravingsToday}).");
          if (cravingSummary.peakHours.isNotEmpty) {
            promptBuffer.writeln("  * Ore critice de vârf când apar poftele: ${cravingSummary.peakHours.map((h) => '$h:00').join(', ')}.");
          }
          if (cravingSummary.mostCommonTrigger != null) {
            promptBuffer.writeln("  * Declanșator cel mai frecvent: ${cravingSummary.mostCommonTrigger}.");
          }
          if (cravingSummary.topReasons.isNotEmpty) {
            promptBuffer.writeln("  * Motive reale scrise de utilizator când a avut poftă:");
            for (final r in cravingSummary.topReasons) {
              promptBuffer.writeln("    - \"$r\"");
            }
          }
        }

        if (relapseSummary != null && relapseSummary.totalRelapses > 0) {
          promptBuffer.writeln("- ISTORIC RECIDIVE (RELAPSES):");
          promptBuffer.writeln("  * ${relapseSummary.toPromptDescription()}");
        }

        if (prediction.isAtRisk) {
          promptBuffer.writeln("⚠️ PREDICȚIE AI ACTIVĂ DE RISC / ANTICIPARE:");
          promptBuffer.writeln("  * Tip alertă: ${prediction.alertTitle}");
          promptBuffer.writeln("  * Motivul predicției: ${prediction.riskReason}");
          if (prediction.relevantPastReasons.isNotEmpty) {
            promptBuffer.writeln("  * Contexte notate de utilizator în situații similare:");
            for (final pr in prediction.relevantPastReasons) {
              promptBuffer.writeln("    - \"$pr\"");
            }
          }
        }

        promptBuffer.writeln("""
REGULI STRICTE DE COMUNICARE (FĂRĂ AI SLOP):
- Ton: Calm, direct, matur, empatic și realist. FĂRĂ CLIȘEE CORPORATISTE, FĂRĂ DRAMATISM (interzis: 'fii un scut', 'luptă', 'recompensa visată', 'capcană', 'dopamină', 'scrum', 'pilot automat', 'eroe', 'dezamorsează').
- Lungime: Exact 2 propoziții scurte (maximum 30-40 de cuvinte). Fără ghilimele, fără introduceri.
- Conținut:
  * Dacă există risc sau poftă anticipată (${prediction.isAtRisk ? prediction.riskReason : 'fără risc iminent'}): Menționează simplu contextul și oferă o acțiune fizică imediată (apă rece, ieși la aer, respiră adânc 1 minut).
  * Dacă are obiectiv financiar: Menționează-l natural pe '${selectedGoal?.name ?? ''}' doar dacă se leagă firesc de propoziție.
  * Altfel: Un gând simplu, practic și liniștitor adaptat momentului zilei ($timeLabel).
""");

        final response = await model.generateContent([Content.text(promptBuffer.toString())]);
        final text = response.text?.trim();
        if (text != null && text.isNotEmpty) {
          _cachedRoutineTip = text;
          _cachedRoutineKey = cacheKey;
          _lastRoutineTipTime = now;
          return text;
        }
      } catch (e) {
        debugPrint("Gemini routine tip API call failed, using intelligent fallback: $e");
      }
    }

    final fallback = _generateFallbackRoutineTip(
      routine: routine,
      now: now,
      cigarettesAvoided: cigarettesAvoided,
      moneySaved: moneySaved,
      dailyCost: dailyCost,
      selectedGoal: selectedGoal,
      breathingSummary: breathingSummary,
      relapseSummary: relapseSummary,
      cravingSummary: cravingSummary,
      prediction: prediction,
      refreshSeed: _refreshCounter,
    );
    _cachedRoutineTip = fallback;
    _cachedRoutineKey = cacheKey;
    _lastRoutineTipTime = now;
    return fallback;
  }

  /// Generează o listă de 3 sfaturi personalizate anti-craving pentru dialogul SOS
  Future<List<String>> getCravingTips({
    required Duration timeElapsed,
    required int cigarettesAvoided,
    required double moneySaved,
    required String routine,
    required String nextMilestone,
    Goal? selectedGoal,
    double dailyCost = 0.0,
    BreathingSummary? breathingSummary,
    RelapseSummary? relapseSummary,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.6,
            maxOutputTokens: 280,
          ),
        );

        final days = timeElapsed.inDays;
        final hours = timeElapsed.inHours % 24;
        final timeString = days > 0 ? "$days zile și $hours ore" : "$hours ore";

        final goalText = selectedGoal != null
            ? "Obiectiv financiar: \"${selectedGoal.name}\" (cost ${selectedGoal.price} ${selectedGoal.currency}, progres ${selectedGoal.calculatePercentage(moneySaved)}%, rămas ${selectedGoal.remainingRon(moneySaved).toStringAsFixed(0)} RON)."
            : "Bani economisiți: ${moneySaved.toStringAsFixed(1)} RON.";

        final relapseContext = relapseSummary?.lastRelapse != null
            ? "Avertisment relapse trecut: În trecut a cedat la ora ${relapseSummary!.lastRelapse!.hourOfDay}:00 din cauza: \"${relapseSummary.lastRelapse!.triggerDisplayName}\"${relapseSummary.lastRelapse!.notes.isNotEmpty ? ' (${relapseSummary.lastRelapse!.notes})' : ''}."
            : "";

        final prompt = """
Un utilizator trece printr-un craving intens de nicotină chiar acum și face exerciții de respirație în aplicație.
Date reale:
- Timp fără fumat: $timeString
- Țigări evitate: $cigarettesAvoided
- $goalText
- Următoarea etapă de sănătate: "$nextMilestone"
- Obiceiuri declarate: "${routine.isEmpty ? 'generale' : routine}"
- $relapseContext

Cerințe:
Generează exact 3 sfaturi specifice și foarte motivaționale, numerotate 1, 2, 3 (maxim 25 de cuvinte per sfat).
- Sfatul 1: Conectează progresul concret ($timeString, $cigarettesAvoided țigări evitate) cu dovada că mintea lui deține controlul.
- Sfatul 2: Conectează dorința cu ${selectedGoal != null ? 'OBIECTIVUL FINANCIAR ("${selectedGoal.name}")' : 'banii economisiți'}. Arată-i că refuzând țigara acum, visul său financiar rămâne neatins și cu un pas mai aproape!
- Sfatul 3: ${relapseSummary?.lastRelapse != null ? 'Amintește-i că aceeași capcană ca în trecut (${relapseSummary!.lastRelapse!.triggerDisplayName}) încearcă să-l testeze, dar acum are respirația.' : 'Ghidare pe respirație lentă și conștientă + o acțiune fizică imediată (apă rece, coborârea umerilor).' }
Scrie în română, persoana a II-a, fără introduceri.
""";

        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text?.trim();
        if (text != null && text.isNotEmpty) {
          final lines = text
              .split('\n')
              .map((l) => l.trim())
              .where((l) => l.isNotEmpty)
              .map((l) => l.replaceFirst(RegExp(r'^\d+[\.\)]\s*'), ''))
              .where((l) => l.isNotEmpty)
              .toList();
          if (lines.length >= 2) {
            return lines;
          }
        }
      } catch (e) {
        debugPrint("Gemini craving tips API call failed, using intelligent fallback: $e");
      }
    }

    return _generateFallbackCravingTips(
      timeElapsed: timeElapsed,
      cigarettesAvoided: cigarettesAvoided,
      moneySaved: moneySaved,
      routine: routine,
      nextMilestone: nextMilestone,
      selectedGoal: selectedGoal,
      relapseSummary: relapseSummary,
    );
  }

  /// Fallback inteligent local pentru sfatul de rutină cu predicții AI din pofte, recidive, respirație și obiective
  String _generateFallbackRoutineTip({
    required String routine,
    required DateTime now,
    required int cigarettesAvoided,
    required double moneySaved,
    double dailyCost = 0.0,
    Goal? selectedGoal,
    BreathingSummary? breathingSummary,
    RelapseSummary? relapseSummary,
    CravingSummary? cravingSummary,
    CombinedRiskPrediction? prediction,
    int refreshSeed = 0,
  }) {
    final lowerRoutine = routine.toLowerCase();
    final hour = now.hour;

    // Evaluare predicție risc
    final pred = prediction ??
        CombinedRiskPrediction.predict(
          now: now,
          routine: routine,
          relapseSummary: relapseSummary,
          cravingSummary: cravingSummary,
        );

    // 0. Dacă există o predicție de risc sau poftă anticipată:
    if (pred.isAtRisk) {
      final reasonSnippet = pred.relevantPastReasons.isNotEmpty
          ? " (${pred.relevantPastReasons.first})"
          : "";

      final riskTemplates = [
        "În acest interval apar de obicei cele mai mari pofte$reasonSnippet. Bea un pahar cu apă rece și fă o scurtă pauză; impulsul trece în 3 minute.",
        "Atenție la acest moment al zilei$reasonSnippet. Dacă simți nevoia de o țigară, schimbă încăperea sau ieși la aer înainte să iei o decizie.",
        "În trecut, această oră a fost mai vulnerabilă$reasonSnippet. Relaxează umerii, respiră adânc de câteva ori și lasă valul să treacă de la sine.",
        "Este un moment sensibil pe baza tiparelor tale$reasonSnippet. Fă un scurt exercițiu de respirație dacă simți tensiune acumulată.",
      ];
      return riskTemplates[refreshSeed % riskTemplates.length];
    }

    // 1. Fragment Obiectiv Financiar
    String goalSnippet = "";
    if (selectedGoal != null) {
      final pct = selectedGoal.calculatePercentage(moneySaved);
      if (pct >= 100) {
        goalSnippet = " Ai atins 100% din '${selectedGoal.name}'.";
      } else {
        goalSnippet = " Ai economisit deja $pct% din '${selectedGoal.name}'.";
      }
    }

    // 2. Pool variat de mesaje dinamice pe intervale orare (rotite cu refreshSeed)
    if (hour >= 5 && hour < 11) {
      final morningTemplates = [
        "La cafea, nevoia de a fuma este doar o obișnuință a mâinilor. Savurează gustul cafelei fără grabă.$goalSnippet",
        "Primele ore ale dimineții sunt mai ușoare dacă bei un pahar mare de apă înainte de orice activitate.$goalSnippet",
        "Rutina de dimineață se așază mai bine fără fum. Ai deja $cigarettesAvoided țigări evitate.$goalSnippet",
      ];
      if (lowerRoutine.contains('cafea') || lowerRoutine.contains('diminea')) {
        return "E timpul cafelei. Înlocuiește gestul țigării cu un pahar rece de apă și 3 respirații lente.$goalSnippet";
      }
      return morningTemplates[refreshSeed % morningTemplates.length];
    } else if (hour >= 11 && hour < 15) {
      final lunchTemplates = [
        "După prânz, impulsul mecanic scade în câteva minute dacă te ridici direct de la masă și faci câțiva pași.$goalSnippet",
        "Pauza de prânz este pentru odihnă și hrană bună. Bea un ceai cald sau un pahar cu apă.$goalSnippet",
        "Masa de prânz este completă fără țigară. Ai economisit deja ${moneySaved.toStringAsFixed(0)} RON.$goalSnippet",
      ];
      return lunchTemplates[refreshSeed % lunchTemplates.length];
    } else if (hour >= 15 && hour < 19) {
      final afternoonTemplates = [
        "Oboseala de după-amiază cere o gură de oxigen. Deschide geamul larg și respiră adânc.$goalSnippet",
        "Tensiunea de peste zi se eliberează cel mai bine printr-o scurtă plimbare de 5 minute departe de birou.$goalSnippet",
        "După-amiaza trece mai ușor când bei apă regulat și îți lași privirea să se odihnească câteva clipe.$goalSnippet",
      ];
      return afternoonTemplates[refreshSeed % afternoonTemplates.length];
    } else if (hour >= 19 && hour < 23) {
      final eveningTemplates = [
        "Seara este pentru liniște și deconectare. Respiră calm și bucură-te că ai încheiat o altă zi fără fum.$goalSnippet",
        "O zi întreagă fără fumat aduce o noapte cu somn odihnitor. Continuă în ritmul tău.$goalSnippet",
        "Momentele de relaxare de seară sunt mult mai curate fără mirosul de tutun.$goalSnippet",
      ];
      return eveningTemplates[refreshSeed % eveningTemplates.length];
    } else {
      return "Noaptea corpul se regenerează cel mai bine. Dacă adormi greu, bea o cană de apă caldă și respiră lent.$goalSnippet";
    }
  }

  /// Fallback inteligent local pentru sfaturile din SOS Craving
  List<String> _generateFallbackCravingTips({
    required Duration timeElapsed,
    required int cigarettesAvoided,
    required double moneySaved,
    required String routine,
    required String nextMilestone,
    Goal? selectedGoal,
    RelapseSummary? relapseSummary,
  }) {
    final days = timeElapsed.inDays;
    final hours = timeElapsed.inHours % 24;
    final timeStr = days > 0 ? "$days zile și $hours ore" : "$hours ore";

    final list = <String>[
      "Ai deja $timeStr fără fum și $cigarettesAvoided țigări evitate. Pofta fizică scade în intensitate după circa 3 minute dacă nu acționezi pe moment.",
    ];

    if (relapseSummary?.lastRelapse != null) {
      list.add(
        "În trecut ai simțit o presiune similară legată de: ${relapseSummary!.lastRelapse!.triggerDisplayName}. Bea o gură mare de apă rece.",
      );
    } else if (selectedGoal != null) {
      final pct = selectedGoal.calculatePercentage(moneySaved);
      final remaining = selectedGoal.remainingRon(moneySaved);
      list.add(
        "Ești la $pct% din '${selectedGoal.name}' (mai ai ${remaining.toStringAsFixed(0)} RON). Păstrează-ți economiile intacte.",
      );
    } else if (nextMilestone.isNotEmpty) {
      list.add("Următoarea etapă de sănătate: $nextMilestone. Tentația trece repede, dar recuperarea rămâne.");
    } else {
      list.add("Ai economisit deja ${moneySaved.toStringAsFixed(0)} RON. Schimbă mediul fizic sau încăperea pentru 5 minute.");
    }

    if (routine.toLowerCase().contains('cafea')) {
      list.add("Savurează băutura fără grabă. Gestul mâinii este doar un reflex care dispare repede.");
    } else {
      list.add("Inspiră lent pe nas și expiră prelung pe gură. Tensiunea musculară din umeri va scădea.");
    }

    return list;
  }
}

final geminiService = GeminiService();
