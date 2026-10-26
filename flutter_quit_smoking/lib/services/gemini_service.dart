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
CERINȚE PENTRU RĂSPUNS:
1. Formulează un singur mesaj concentrat (2-3 propoziții, 40-60 de cuvinte), direct, viu, empatic și extrem de personalizat în limba română la persoana a II-a ('tu').
2. DACĂ EXISTĂ O PREDICȚIE DE RISC SAU POFTĂ (${prediction.isAtRisk ? prediction.riskReason : 'fără risc iminent'}):
   - Fii un scut proactiv! Avertizează-l că se află în intervalul sau contextul vulnerabil.
   - Folosește subtil și inteligent chiar motivele sau cuvintele scrise de el în trecut (ex: dacă a menționat 'cafea cu colegii' sau 'stres la prânz', fă referire directă la acel moment).
   - Dă-i o alternativă practică imediată de a trece peste impuls (ex: bea apă rece, respiră adânc 2 minute, schimbă mediul fizic).
3. DACĂ NU EXISTĂ RISC IMINENT:
   - Oferă un sfat proaspăt potrivit momentului zilei ($timeLabel) și progresului său.
4. DACĂ ARE OBIECTIV FINANCIAR ACTIV:
   - Menționează-l pe nume ('${selectedGoal?.name ?? ''}') cu căldură și arată-i cum fiecare clipă de rezistență îl aduce mai aproape de realizarea lui.
5. FĂRĂ CLIȘEE: Nu folosi generalități impersonale, fără introduceri ca 'Iată sfatul tău:' sau ghilimele exterioare. Schimbă formulările pentru a fi mereu surprinzător și motivant.
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
          ? " (notat anterior: \"${pred.relevantPastReasons.first}\")"
          : "";

      final riskTemplates = [
        "🛡️ AI Preventiv: Te afli într-un interval vulnerabil$reasonSnippet. Bea un pahar plin cu apă rece și fă 2 minute de respirație ghidată înainte să apară impulsul!",
        "⚠️ Atenție la tiparul tău: În trecut, această oră a generat pofte sau dificultăți$reasonSnippet. Nu lăsa pilotul automat să decidă – fă o scurtă pauză activă fără fum!",
        "🛡️ Alertă de protecție: Recunoaște capcana din timp$reasonSnippet. Fiecare minut de atenție conștientă îți consolidează libertatea și te ține departe de recidivă.",
        "⚡ Moment critic anticipat de AI: Corpul tău își amintește vechile obiceiuri$reasonSnippet. Schimbă încăperea sau respiră profund în 4 timpi chiar acum!",
      ];
      return riskTemplates[refreshSeed % riskTemplates.length];
    }

    // 1. Fragment Obiectiv Financiar
    String goalSnippet = "";
    if (selectedGoal != null) {
      final pct = selectedGoal.calculatePercentage(moneySaved);
      final remaining = selectedGoal.remainingRon(moneySaved);
      if (pct >= 100) {
        goalSnippet = " 🎯 Ai atins 100% din '${selectedGoal.name}'! Mergi și bucură-te de recompensa ta fără fum.";
      } else if (pct >= 50) {
        goalSnippet = " Ești la $pct% din '${selectedGoal.name}' – mai ai doar ${remaining.toStringAsFixed(0)} RON până la visul tău!";
      } else {
        goalSnippet = " Fiecare zi fără fum te apropie de '${selectedGoal.name}', unde ai strâns deja $pct%.";
      }
    }

    // 2. Fragment Respirație recentă
    String breathingSnippet = "";
    if (breathingSummary != null && breathingSummary.lastSession != null) {
      final last = breathingSummary.lastSession!;
      final isToday = last.startedAt.year == now.year &&
          last.startedAt.month == now.month &&
          last.startedAt.day == now.day;
      if (isToday) {
        breathingSnippet = " Ai calmat excelent pofta mai devreme la ${last.formattedStartTime} prin ${last.techniqueDisplayName}.";
      }
    }

    // 3. Pool variat de mesaje dinamice pe intervale orare (rotite cu refreshSeed)
    if (hour >= 5 && hour < 11) {
      final morningTemplates = [
        "Dimineața creierul tău cere doar dopamina obișnuită. Începe ziua bucurându-te de plămânii curați și aerul proaspăt fără nicotină.",
        "E timpul cafelei. Înlocuiește gestul mecanic al țigării cu 3 respirații lente și savurează aroma autentică a băuturii.",
        "Un nou început de zi fără fumat! Cele $cigarettesAvoided țigări evitate până acum îți dau energie reală pentru întreaga zi.",
      ];
      if (lowerRoutine.contains('cafea') || lowerRoutine.contains('diminea')) {
        return "E timpul cafelei de dimineață. Înlocuiește gestul țigării cu un pahar rece de apă și 3 respirații lente.$breathingSnippet$goalSnippet";
      }
      return "${morningTemplates[refreshSeed % morningTemplates.length]}$breathingSnippet$goalSnippet";
    } else if (hour >= 11 && hour < 15) {
      final lunchTemplates = [
        "După masă, pofta de nicotină durează doar 3 minute. Bea o gură mare de apă rece sau fă o scurtă plimbare pentru a rupe asocierea reflexă.",
        "Pauza de prânz este pentru reîncărcare, nu pentru fumat. Conștientizează cele $cigarettesAvoided țigări evitate și cele ${moneySaved.toStringAsFixed(0)} RON economisiți!",
        "Masa de prânz se așază mult mai bine când nu este urmată de fum. Ridică-te de la masă imediat și schimbă peisajul.",
      ];
      return "${lunchTemplates[refreshSeed % lunchTemplates.length]}$breathingSnippet$goalSnippet";
    } else if (hour >= 15 && hour < 19) {
      final afternoonTemplates = [
        "Tensiunea de după-amiază se rezolvă cu o pauză reală de respirație, nu cu fumat. Relaxează umerii și expiră prelung.",
        "După-amiaza este momentul să-ți admiri progresul de ${moneySaved.toStringAsFixed(0)} RON economisiți și claritatea mentală.",
        "Oboseala de la birou cere oxigen, nu monoxid de carbon. Deschide geamul larg și inspiră adânc de 4 ori.",
      ];
      return "${afternoonTemplates[refreshSeed % afternoonTemplates.length]}$breathingSnippet$goalSnippet";
    } else if (hour >= 19 && hour < 23) {
      final eveningTemplates = [
        "Seara, relaxarea adevărată vine din deconectare profundă, nu din nicotină. Respiră conștient și lasă corpul să se regenereze.",
        "O altă zi întreagă fără fumat este o victorie uriașă! Încheie seara mândru de disciplina și sănătatea ta.",
        "Momentele de liniște de seară sunt magice fără scrum și fum. Meriți această libertate deplină.",
      ];
      return "${eveningTemplates[refreshSeed % eveningTemplates.length]}$breathingSnippet$goalSnippet";
    } else {
      return "Noaptea este dedicată odihnei și regenerării celulare. Dacă ai insomnie, bea o cană de apă caldă și concentrează-te pe respirație lentă.$goalSnippet";
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
      "Ai deja $timeStr fără fum și $cigarettesAvoided țigări refuzate. Nu lăsa un impuls de 3 minute să șteargă această victorie!",
    ];

    if (relapseSummary?.lastRelapse != null) {
      list.add(
        "Amintește-ți că data trecută declanșatorul a fost: \"${relapseSummary!.lastRelapse!.triggerDisplayName}\". Recunoaște capcana acum înainte să acționezi!",
      );
    } else if (selectedGoal != null) {
      final pct = selectedGoal.calculatePercentage(moneySaved);
      final remaining = selectedGoal.remainingRon(moneySaved);
      list.add(
        "Ai strâns deja ${moneySaved.toStringAsFixed(0)} RON ($pct%) pentru '${selectedGoal.name}'! Mai ai doar ${remaining.toStringAsFixed(0)} RON – nu da foc banilor tăi pentru o secundă de fum.",
      );
    } else if (nextMilestone.isNotEmpty) {
      list.add("Corpul tău luptă chiar acum pentru etapa: $nextMilestone. Cravingul trece repede, dar sănătatea recâștigată rămâne!");
    } else {
      list.add("Ai economisit deja ${moneySaved.toStringAsFixed(1)} RON. Fiecare impuls depășit îți reconfigurează creierul spre libertate.");
    }

    final lowerRoutine = routine.toLowerCase();
    if (lowerRoutine.contains('cafea')) {
      list.add("Cafeaua are un gust mult mai bogat fără fum. Bea o gură mare de apă rece și continuă respirația în 4 timpi.");
    } else if (lowerRoutine.contains('stres')) {
      list.add("Stresul este doar o stare trecătoare, nicotina doar îl adâncește. Expiră prelung pe gură și eliberează maxilarul.");
    } else {
      list.add("Inspiră lent pe nas și expiră prelung pe gură. În 3 minute corpul tău va reveni la starea de calm.");
    }

    return list;
  }
}

final geminiService = GeminiService();
