import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  static const String _prefApiKey = 'gemini_api_key';

  // Cache în memorie pentru a evita apelurile repetitive inutile
  String? _cachedRoutineTip;
  String? _cachedRoutineKey;
  DateTime? _lastRoutineTipTime;

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

  /// Generează un sfat personalizat pentru momentul curent al zilei bazat pe rutina de fumat
  Future<String> getRoutineTip({
    required String routine,
    required Duration timeElapsed,
    required int cigarettesAvoided,
    required double moneySaved,
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    final timeLabel = getTimeOfDayLabel(now);
    final cacheKey = "${timeLabel}_${now.hour}_$routine";

    if (!forceRefresh &&
        _cachedRoutineTip != null &&
        _cachedRoutineKey == cacheKey &&
        _lastRoutineTipTime != null &&
        now.difference(_lastRoutineTipTime!).inMinutes < 60) {
      return _cachedRoutineTip!;
    }

    final apiKey = await getApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.7,
            maxOutputTokens: 150,
          ),
        );

        final days = timeElapsed.inDays;
        final hours = timeElapsed.inHours % 24;
        final timeString = days > 0 ? "$days zile și $hours ore" : "$hours ore";

        final prompt = """
Ești un asistent medical și psihologic empatic de renunțare la fumat.
Utilizatorul a renunțat la fumat de: $timeString.
Țigări evitate: $cigarettesAvoided.
Bani economisiți: ${moneySaved.toStringAsFixed(1)} RON.
Momentul curent al zilei: $timeLabel (ora ${now.hour}:${now.minute.toString().padLeft(2, '0')}).
Obiceiurile declarate de utilizator când fuma de obicei (declanșatori / rutină):
"${routine.isEmpty ? 'Nespecificate explicit' : routine}"

Cerințe:
1. Formulează un singur sfat scurt (1-2 propoziții, maxim 40 de cuvinte), direct, pozitiv și acționabil în limba română.
2. Adresează-te la persoana a II-a ("tu").
3. Leagă sfatul de momentul curent ($timeLabel) și de obiceiurile lui (ex: dacă e dimineață și menționează cafea, sau dacă e prânz/seară).
4. Oferă o alternativă sănătoasă imediată (apă, respirație, ceai, plimbare).
5. Nu include ghilimele, titluri, subtitluri sau introduceri gen "Iată un sfat:".
""";

        final response = await model.generateContent([Content.text(prompt)]);
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
    );
    _cachedRoutineTip = fallback;
    _cachedRoutineKey = cacheKey;
    _lastRoutineTipTime = now;
    return fallback;
  }

  /// Generează o listă de 3-4 sfaturi personalizate anti-craving pentru dialogul SOS
  Future<List<String>> getCravingTips({
    required Duration timeElapsed,
    required int cigarettesAvoided,
    required double moneySaved,
    required String routine,
    required String nextMilestone,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.6,
            maxOutputTokens: 260,
          ),
        );

        final days = timeElapsed.inDays;
        final hours = timeElapsed.inHours % 24;
        final timeString = days > 0 ? "$days zile și $hours ore" : "$hours ore";

        final prompt = """
Un utilizator trece printr-un craving intens de nicotină chiar acum și face exerciții de respirație în aplicație.
Date reale din baza de date:
- Timp fără fumat: $timeString
- Țigări evitate: $cigarettesAvoided
- Bani economisiți: ${moneySaved.toStringAsFixed(1)} RON
- Următoarea etapă de recuperare a sănătății: "$nextMilestone"
- Obiceiurile lui de fumat declarate: "${routine.isEmpty ? 'generale' : routine}"

Cerințe:
Generează exact 3 sfaturi scurte anti-craving, numerotate 1, 2, 3.
Fiecare sfat trebuie să aibă maximum 1-2 propoziții (maxim 25 de cuvinte per sfat).
- Sfatul 1: Menționează progresul lui concret ($timeString, $cigarettesAvoided țigări evitate) ca dovadă că are deja controlul.
- Sfatul 2: Conectează momentul de poftă cu beneficiul medical apropiat ("$nextMilestone").
- Sfatul 3: Oferă o acțiune fizică imediată potrivită obiceiurilor lui (apă rece, relaxarea maxilarului, aer curat).
Scrie în limba română, la persoana a II-a, fără introduceri sau concluzii, doar cele 3 linii numerotate.
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
    );
  }

  /// Fallback inteligent local pentru sfatul de rutină
  String _generateFallbackRoutineTip({
    required String routine,
    required DateTime now,
    required int cigarettesAvoided,
    required double moneySaved,
  }) {
    final lowerRoutine = routine.toLowerCase();
    final hour = now.hour;

    if (hour >= 5 && hour < 11) {
      if (lowerRoutine.contains('cafea') || lowerRoutine.contains('diminea')) {
        return "E timpul cafelei de dimineață. Înlocuiește gestul țigării cu un pahar rece de apă înainte de prima înghițitură și respiră adânc.";
      }
      return "Dimineața creierul tău cere doar dopamina obișnuită. Începe ziua cu 3 respirații lente și bucură-te de aerul curat fără fum.";
    } else if (hour >= 11 && hour < 15) {
      if (lowerRoutine.contains('masa') || lowerRoutine.contains('masă') || lowerRoutine.contains('pranz') || lowerRoutine.contains('prânz')) {
        return "După masă, pofta de țigară durează doar 3 minute. Ridică-te de la masă, bea un ceai de mentă sau spală-te pe dinți pentru o senzație de prospețime.";
      }
      return "Pauza de prânz este despre reîncărcare, nu despre fumat. Fă câțiva pași la aer liber și conștientizează cele $cigarettesAvoided țigări evitate!";
    } else if (hour >= 15 && hour < 19) {
      if (lowerRoutine.contains('stres') || lowerRoutine.contains('munca') || lowerRoutine.contains('muncă') || lowerRoutine.contains('birou')) {
        return "Tensiunea de după-amiază nu se rezolvă cu fumatul, ci cu o pauză reală. Relaxează-ți umerii și oferă-ți 5 minute de liniște.";
      }
      return "Ai economisit deja ${moneySaved.toStringAsFixed(1)} RON. Răsplătește-te după-amiază cu o gustare sănătoasă sau o băutură preferată non-alcoolică.";
    } else if (hour >= 19 && hour < 23) {
      if (lowerRoutine.contains('seara') || lowerRoutine.contains('relax') || lowerRoutine.contains('tv')) {
        return "Seara, relaxarea vine din deconectare, nu din nicotină. Pune o muzică liniștitoare și lasă corpul să se regenereze peste noapte.";
      }
      return "O zi întreagă fără fumat este o victorie uriașă. Încheie seara conștientizând că plămânii tăi se curăță în fiecare clipă.";
    } else {
      return "Noaptea este dedicată odihnei și regenerării celulare. Dacă ai insomnie, bea o cană de apă caldă și concentrează-te pe respirație lentă.";
    }
  }

  /// Fallback inteligent local pentru sfaturile din SOS Craving
  List<String> _generateFallbackCravingTips({
    required Duration timeElapsed,
    required int cigarettesAvoided,
    required double moneySaved,
    required String routine,
    required String nextMilestone,
  }) {
    final days = timeElapsed.inDays;
    final hours = timeElapsed.inHours % 24;
    final timeStr = days > 0 ? "$days zile și $hours ore" : "$hours ore";

    final list = <String>[
      "Ai deja $timeStr de când ești liber și ai evitat $cigarettesAvoided țigări. Nu renunța acum la tot ce ai cucerit!",
    ];

    if (nextMilestone.isNotEmpty) {
      list.add("Plămânii tăi luptă chiar acum pentru: $nextMilestone. Cravingul durează 3 minute, beneficiul rămâne o viață.");
    } else {
      list.add("Ai salvat deja ${moneySaved.toStringAsFixed(1)} RON. Fiecare poftă refuzată îți reconfigurează căile neuronale.");
    }

    final lowerRoutine = routine.toLowerCase();
    if (lowerRoutine.contains('cafea')) {
      list.add("Cafeaua are un gust mai intens și mai aromat fără fum. Bea o gură mare de apă rece și continuă respirația.");
    } else if (lowerRoutine.contains('stres')) {
      list.add("Stresul este doar o stare mentală temporară, nicotina doar îl amână. Expiră prelung tot aerul și eliberează tensiunea.");
    } else {
      list.add("Bea un pahar plin cu apă rece și schimbă camera. În câteva minute, pofta va dispărea complet.");
    }

    return list;
  }
}

final geminiService = GeminiService();
