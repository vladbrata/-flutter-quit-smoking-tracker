import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_quit_smoking/pages/models/breathing_session_model.dart';
import 'package:flutter_quit_smoking/pages/models/craving_model.dart';
import 'package:flutter_quit_smoking/pages/models/goal_model.dart';
import 'package:flutter_quit_smoking/pages/models/relapse_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  /// Salvează sau actualizează profilul utilizatorului la autentificare sau înregistrare
  Future<void> saveUserProfile({
    required String uid,
    required String email,
    String? name,
  }) async {
    final docRef = _userDoc(uid);
    final docSnap = await docRef.get();

    final Map<String, dynamic> data = {
      'uid': uid,
      'email': email,
      'lastLoginAt': FieldValue.serverTimestamp(),
    };

    if (name != null && name.trim().isNotEmpty) {
      data['name'] = name.trim();
    }

    if (!docSnap.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['isStarted'] = false;
      data['packPrice'] = 0.0;
      data['cigarettesPerDay'] = 0;
      data['packsPerDay'] = 0.0;
      data['dailyCost'] = 0.0;
      data['smokingRoutine'] = '';
      data['goals'] = [];
      await docRef.set(data, SetOptions(merge: true));
    } else {
      await docRef.set(data, SetOptions(merge: true));
    }
  }

  /// Obține datele complete ale utilizatorului din Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  /// Stream în timp real pentru documentul utilizatorului
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(String uid) {
    return _userDoc(uid).snapshots();
  }

  /// Salvează datele complete despre renunțarea la fumat:
  /// - preț pachet
  /// - țigări fumate pe zi
  /// - pachete pe zi
  /// - cost zilnic
  /// - date despre când fumează de obicei (smokingRoutine)
  /// - data de debut (startTime)
  Future<void> saveQuitData({
    required String uid,
    required DateTime startTime,
    required double packPrice,
    required int cigarettesPerDay,
    required double packsPerDay,
    required double dailyCost,
    String? smokingRoutine,
  }) async {
    // 1. Salvare locală în SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('start_time', startTime.toIso8601String());
    await prefs.setDouble('pack_price', packPrice);
    await prefs.setInt('cigarettes_per_day', cigarettesPerDay);
    await prefs.setDouble('packs_per_day', packsPerDay);
    await prefs.setDouble('daily_cost', dailyCost);
    if (smokingRoutine != null) {
      await prefs.setString('smoking_routine', smokingRoutine.trim());
    }
    await prefs.setBool('is_started', true);

    // 2. Salvare completă în Firestore
    final Map<String, dynamic> firestoreData = {
      'isStarted': true,
      'startTime': Timestamp.fromDate(startTime),
      'packPrice': packPrice,
      'cigarettesPerDay': cigarettesPerDay,
      'packsPerDay': packsPerDay,
      'dailyCost': dailyCost,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (smokingRoutine != null) {
      firestoreData['smokingRoutine'] = smokingRoutine.trim();
    }
    await _userDoc(uid).set(firestoreData, SetOptions(merge: true));
  }

  /// Actualizează obiceiurile legate de fumat (preț, țigări pe zi și momente de fumat)
  Future<void> updateSmokingHabits({
    required String uid,
    required double packPrice,
    required int cigarettesPerDay,
    required double packsPerDay,
    required double dailyCost,
    String? smokingRoutine,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pack_price', packPrice);
    await prefs.setInt('cigarettes_per_day', cigarettesPerDay);
    await prefs.setDouble('packs_per_day', packsPerDay);
    await prefs.setDouble('daily_cost', dailyCost);
    if (smokingRoutine != null) {
      await prefs.setString('smoking_routine', smokingRoutine.trim());
    }

    final Map<String, dynamic> firestoreData = {
      'packPrice': packPrice,
      'cigarettesPerDay': cigarettesPerDay,
      'packsPerDay': packsPerDay,
      'dailyCost': dailyCost,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (smokingRoutine != null) {
      firestoreData['smokingRoutine'] = smokingRoutine.trim();
    }
    await _userDoc(uid).set(firestoreData, SetOptions(merge: true));
  }

  /// Actualizează doar data/ora de început
  Future<void> updateStartTime({
    required String uid,
    required DateTime newStartTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('start_time', newStartTime.toIso8601String());

    await _userDoc(uid).set({
      'startTime': Timestamp.fromDate(newStartTime),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Resetează progresul în cazul relapsului
  Future<void> resetProgression(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('start_time');
    await prefs.remove('selected_goal');
    await prefs.setBool('is_started', false);

    await _userDoc(uid).set({
      'isStarted': false,
      'startTime': FieldValue.delete(),
      'selectedGoal': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Salvează lista de obiective (goals)
  Future<void> saveGoals({
    required String uid,
    required List<Goal> goals,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = jsonEncode(goals.map((g) => g.toMap()).toList());
    await prefs.setString('saved_goals_list', jsonList);

    await _userDoc(uid).set({
      'goals': goals.map((g) => g.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Selectează sau deselectează obiectivul activ
  Future<void> setSelectedGoal({
    required String uid,
    Goal? goal,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (goal != null) {
      await prefs.setString('selected_goal', jsonEncode(goal.toMap()));
      await _userDoc(uid).set({
        'selectedGoal': goal.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await prefs.remove('selected_goal');
      await _userDoc(uid).set({
        'selectedGoal': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Sincronizează TOATE datele din Firestore în SharedPreferences
  Future<void> syncFromFirestoreToLocal(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      if (!doc.exists || doc.data() == null) return;
      final data = doc.data()!;
      final prefs = await SharedPreferences.getInstance();

      if (data['name'] != null) {
        await prefs.setString('user_name', data['name'].toString());
      }
      if (data['email'] != null) {
        await prefs.setString('user_email', data['email'].toString());
      }
      if (data['packPrice'] != null) {
        await prefs.setDouble(
          'pack_price',
          (data['packPrice'] as num).toDouble(),
        );
      }
      if (data['cigarettesPerDay'] != null) {
        await prefs.setInt(
          'cigarettes_per_day',
          (data['cigarettesPerDay'] as num).toInt(),
        );
      }
      if (data['packsPerDay'] != null) {
        await prefs.setDouble(
          'packs_per_day',
          (data['packsPerDay'] as num).toDouble(),
        );
      }
      if (data['dailyCost'] != null) {
        await prefs.setDouble(
          'daily_cost',
          (data['dailyCost'] as num).toDouble(),
        );
      }
      if (data['isStarted'] != null) {
        await prefs.setBool('is_started', data['isStarted'] == true);
      }
      if (data['startTime'] is Timestamp) {
        final DateTime st = (data['startTime'] as Timestamp).toDate();
        await prefs.setString('start_time', st.toIso8601String());
      }
      if (data['goals'] is List) {
        final List goalsList = data['goals'];
        await prefs.setString('saved_goals_list', jsonEncode(goalsList));
      }
      if (data['selectedGoal'] is Map) {
        await prefs.setString('selected_goal', jsonEncode(data['selectedGoal']));
      }
      if (data['smokingRoutine'] != null) {
        await prefs.setString('smoking_routine', data['smokingRoutine'].toString());
      }
    } catch (_) {}
  }

  /// Salvează o sesiune de respirație ghidată (ora, durata, tehnica, ciclurile și modul de interacțiune)
  Future<void> saveBreathingSession({
    required String? uid,
    required BreathingSession session,
  }) async {
    try {
      // 1. Salvare locală în SharedPreferences pentru acces instant și offline
      final prefs = await SharedPreferences.getInstance();
      final historyStr = prefs.getString('breathing_sessions_history');
      List<dynamic> list = [];
      if (historyStr != null && historyStr.isNotEmpty) {
        try {
          list = jsonDecode(historyStr);
        } catch (_) {}
      }
      list.insert(0, session.toMap());
      if (list.length > 50) {
        list = list.sublist(0, 50);
      }
      await prefs.setString('breathing_sessions_history', jsonEncode(list));
      await prefs.setString('last_breathing_session', jsonEncode(session.toMap()));

      // 2. Salvare în Firestore dacă utilizatorul este conectat
      if (uid != null && uid.isNotEmpty) {
        await _userDoc(uid)
            .collection('breathing_sessions')
            .doc(session.id)
            .set(session.toFirestoreMap());

        await _userDoc(uid).set({
          'lastBreathingSession': session.toFirestoreMap(),
          'totalBreathingSessions': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  /// Returnează sesiunile recente de respirație pentru analiza AI și istoric
  Future<List<BreathingSession>> getRecentBreathingSessions({
    String? uid,
    int limit = 15,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStr = prefs.getString('breathing_sessions_history');
      if (historyStr != null && historyStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(historyStr);
        return decoded
            .take(limit)
            .map((e) => BreathingSession.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }

      if (uid != null && uid.isNotEmpty) {
        final snap = await _userDoc(uid)
            .collection('breathing_sessions')
            .orderBy('startedAt', descending: true)
            .limit(limit)
            .get();

        final sessions = snap.docs
            .map((doc) => BreathingSession.fromMap(doc.data()))
            .toList();

        if (sessions.isNotEmpty) {
          await prefs.setString(
            'breathing_sessions_history',
            jsonEncode(sessions.map((s) => s.toMap()).toList()),
          );
        }
        return sessions;
      }
    } catch (_) {}
    return [];
  }

  /// Calculează un sumar analitic al modului în care utilizatorul interacționează cu respirația
  Future<BreathingSummary> getBreathingSummary({String? uid}) async {
    final sessions = await getRecentBreathingSessions(uid: uid, limit: 50);
    if (sessions.isEmpty) {
      return BreathingSummary(
        totalSessions: 0,
        totalSessionsToday: 0,
        successfulSessionsToday: 0,
        totalSecondsToday: 0,
        lastSession: null,
        preferredTechnique: 'boxBreathing',
      );
    }

    final now = DateTime.now();
    int todaySessions = 0;
    int todaySuccess = 0;
    int todaySeconds = 0;
    int boxCount = 0;
    int relaxCount = 0;

    for (final s in sessions) {
      if (s.startedAt.year == now.year &&
          s.startedAt.month == now.month &&
          s.startedAt.day == now.day) {
        todaySessions++;
        if (s.isSuccessful) todaySuccess++;
        todaySeconds += s.durationSeconds;
      }
      if (s.technique == 'relax478') {
        relaxCount++;
      } else {
        boxCount++;
      }
    }

    return BreathingSummary(
      totalSessions: sessions.length,
      totalSessionsToday: todaySessions,
      successfulSessionsToday: todaySuccess,
      totalSecondsToday: todaySeconds,
      lastSession: sessions.first,
      preferredTechnique: relaxCount > boxCount ? 'relax478' : 'boxBreathing',
    );
  }

  /// Salvează informațiile despre relapse (când, de ce, declanșator, număr țigări, note)
  /// Salvează atât în subcolecție cât și în documentul principal de utilizator pentru vizibilitate imediată
  Future<void> saveRelapseEvent({
    required String? uid,
    required RelapseEvent relapse,
  }) async {
    try {
      // 1. Salvare locală în SharedPreferences (istoric permanent, nu se șterge la resetare)
      final prefs = await SharedPreferences.getInstance();
      final historyStr = prefs.getString('relapse_history');
      List<dynamic> list = [];
      if (historyStr != null && historyStr.isNotEmpty) {
        try {
          list = jsonDecode(historyStr);
        } catch (_) {}
      }
      list.insert(0, relapse.toMap());
      if (list.length > 50) {
        list = list.sublist(0, 50);
      }
      await prefs.setString('relapse_history', jsonEncode(list));
      await prefs.setString('last_relapse', jsonEncode(relapse.toMap()));

      // 2. Salvare completă în Firestore:
      // a) În subcolecția relapses
      // b) În documentul root al utilizatorului cu array-uri de ore și istoric recent (pentru vizibilitate directă în consolă)
      if (uid != null && uid.isNotEmpty) {
        await _userDoc(uid)
            .collection('relapses')
            .doc(relapse.id)
            .set(relapse.toFirestoreMap());

        final recentRelapsesList = list.take(5).map((e) {
          final r = RelapseEvent.fromMap(Map<String, dynamic>.from(e));
          return {
            'id': r.id,
            'relapsedAt': Timestamp.fromDate(r.relapsedAt),
            'formattedDate': r.formattedDate,
            'hourOfDay': r.hourOfDay,
            'triggerDisplayName': r.triggerDisplayName,
            'notes': r.notes,
            'cigarettesSmoked': r.cigarettesSmoked,
          };
        }).toList();

        await _userDoc(uid).set({
          'lastRelapse': relapse.toFirestoreMap(),
          'totalRelapses': FieldValue.increment(1),
          'relapseHours': FieldValue.arrayUnion([relapse.hourOfDay]),
          'recentRelapses': recentRelapsesList,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  /// Returnează istoricul episoadelor de relapse
  Future<List<RelapseEvent>> getRelapseHistory({
    String? uid,
    int limit = 15,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStr = prefs.getString('relapse_history');
      if (historyStr != null && historyStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(historyStr);
        return decoded
            .take(limit)
            .map((e) => RelapseEvent.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }

      if (uid != null && uid.isNotEmpty) {
        final snap = await _userDoc(uid)
            .collection('relapses')
            .orderBy('relapsedAt', descending: true)
            .limit(limit)
            .get();

        final relapses = snap.docs
            .map((doc) => RelapseEvent.fromMap(doc.data()))
            .toList();

        if (relapses.isNotEmpty) {
          await prefs.setString(
            'relapse_history',
            jsonEncode(relapses.map((r) => r.toMap()).toList()),
          );
        }
        return relapses;
      }
    } catch (_) {}
    return [];
  }

  /// Calculează sumarul și tiparele de risc din relapse-urile trecute
  Future<RelapseSummary> getRelapseSummary({String? uid}) async {
    final history = await getRelapseHistory(uid: uid, limit: 30);
    if (history.isEmpty) {
      return RelapseSummary(
        totalRelapses: 0,
        lastRelapse: null,
        mostCommonTrigger: null,
        history: [],
      );
    }

    final Map<String, int> triggerCounts = {};
    for (final r in history) {
      triggerCounts[r.triggerDisplayName] = (triggerCounts[r.triggerDisplayName] ?? 0) + 1;
    }

    String? mostCommon;
    int maxCount = 0;
    triggerCounts.forEach((k, v) {
      if (v > maxCount) {
        maxCount = v;
        mostCommon = k;
      }
    });

    return RelapseSummary(
      totalRelapses: history.length,
      lastRelapse: history.first,
      mostCommonTrigger: mostCommon,
      history: history,
    );
  }

  /// Salvează o poftă (craving) cu ora exactă, motivul scris de utilizator ("de ce ai o poftă"), declanșator și intensitate
  /// Salvează atât în SharedPreferences cât și în Firestore (subcolecție + câmpuri pe documentul root)
  Future<void> saveCravingEvent({
    required String? uid,
    required CravingEvent craving,
  }) async {
    try {
      // 1. Salvare locală în SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final historyStr = prefs.getString('cravings_history');
      List<dynamic> list = [];
      if (historyStr != null && historyStr.isNotEmpty) {
        try {
          list = jsonDecode(historyStr);
        } catch (_) {}
      }
      list.insert(0, craving.toMap());
      if (list.length > 50) {
        list = list.sublist(0, 50);
      }
      await prefs.setString('cravings_history', jsonEncode(list));
      await prefs.setString('last_craving', jsonEncode(craving.toMap()));

      // 2. Salvare completă în Firestore (subcolecția cravings + root user doc)
      if (uid != null && uid.isNotEmpty) {
        await _userDoc(uid)
            .collection('cravings')
            .doc(craving.id)
            .set(craving.toFirestoreMap());

        final recentCravingsList = list.take(5).map((e) {
          final c = CravingEvent.fromMap(Map<String, dynamic>.from(e));
          return {
            'id': c.id,
            'timestamp': Timestamp.fromDate(c.timestamp),
            'formattedDate': c.formattedDate,
            'formattedTime': c.formattedTime,
            'hourOfDay': c.hourOfDay,
            'triggerDisplayName': c.triggerDisplayName,
            'reason': c.reason,
            'intensity': c.intensity,
            'overcame': c.overcame,
          };
        }).toList();

        // Calcul ore de vârf pofte
        final Map<int, int> hourFreq = {};
        for (final item in list) {
          final c = CravingEvent.fromMap(Map<String, dynamic>.from(item));
          hourFreq[c.hourOfDay] = (hourFreq[c.hourOfDay] ?? 0) + 1;
        }
        final sortedHours = hourFreq.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final peakHours = sortedHours.take(3).map((e) => e.key).toList();

        await _userDoc(uid).set({
          'lastCraving': craving.toFirestoreMap(),
          'totalCravings': FieldValue.increment(1),
          'cravingHours': FieldValue.arrayUnion([craving.hourOfDay]),
          'recentCravings': recentCravingsList,
          'cravingPeakHours': peakHours,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  /// Marchează o poftă ca fiind depășită cu succes (overcame = true)
  Future<void> markCravingOvercame({
    required String? uid,
    required String cravingId,
    String? breathingSessionId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStr = prefs.getString('cravings_history');
      if (historyStr != null && historyStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(historyStr);
        for (int i = 0; i < list.length; i++) {
          if (list[i]['id'] == cravingId) {
            list[i]['overcame'] = true;
            if (breathingSessionId != null) {
              list[i]['breathingSessionId'] = breathingSessionId;
            }
            break;
          }
        }
        await prefs.setString('cravings_history', jsonEncode(list));
      }

      if (uid != null && uid.isNotEmpty) {
        final Map<String, dynamic> updateData = {'overcame': true};
        if (breathingSessionId != null) {
          updateData['breathingSessionId'] = breathingSessionId;
        }
        await _userDoc(uid).collection('cravings').doc(cravingId).update(updateData);
      }
    } catch (_) {}
  }

  /// Returnează istoricul poftelor înregistrate
  Future<List<CravingEvent>> getCravingHistory({
    String? uid,
    int limit = 20,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStr = prefs.getString('cravings_history');
      if (historyStr != null && historyStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(historyStr);
        return decoded
            .take(limit)
            .map((e) => CravingEvent.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }

      if (uid != null && uid.isNotEmpty) {
        final snap = await _userDoc(uid)
            .collection('cravings')
            .orderBy('timestamp', descending: true)
            .limit(limit)
            .get();

        final cravings = snap.docs
            .map((doc) => CravingEvent.fromMap(doc.data()))
            .toList();

        if (cravings.isNotEmpty) {
          await prefs.setString(
            'cravings_history',
            jsonEncode(cravings.map((c) => c.toMap()).toList()),
          );
        }
        return cravings;
      }
    } catch (_) {}
    return [];
  }

  /// Calculează sumarul poftelor (ore de vârf, motive menționate, declanșator cel mai frecvent)
  Future<CravingSummary> getCravingSummary({String? uid}) async {
    final history = await getCravingHistory(uid: uid, limit: 40);
    if (history.isEmpty) {
      return CravingSummary(
        totalCravings: 0,
        cravingsToday: 0,
        peakHours: [],
        mostCommonTrigger: null,
        topReasons: [],
        lastCraving: null,
        history: [],
      );
    }

    final now = DateTime.now();
    int cravingsToday = 0;
    final Map<int, int> hourCounts = {};
    final Map<String, int> triggerCounts = {};
    final List<String> topReasons = [];

    for (final c in history) {
      if (c.timestamp.year == now.year &&
          c.timestamp.month == now.month &&
          c.timestamp.day == now.day) {
        cravingsToday++;
      }
      hourCounts[c.hourOfDay] = (hourCounts[c.hourOfDay] ?? 0) + 1;
      triggerCounts[c.triggerDisplayName] = (triggerCounts[c.triggerDisplayName] ?? 0) + 1;
      if (c.reason.trim().isNotEmpty && !topReasons.contains(c.reason.trim())) {
        topReasons.add(c.reason.trim());
      }
    }

    final sortedHourEntries = hourCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final peakHours = sortedHourEntries.take(3).map((e) => e.key).toList();

    String? mostCommon;
    int maxCount = 0;
    triggerCounts.forEach((k, v) {
      if (v > maxCount) {
        maxCount = v;
        mostCommon = k;
      }
    });

    return CravingSummary(
      totalCravings: history.length,
      cravingsToday: cravingsToday,
      peakHours: peakHours,
      mostCommonTrigger: mostCommon,
      topReasons: topReasons.take(5).toList(),
      lastCraving: history.first,
      history: history,
    );
  }

  /// Evaluează combinat recidivele, poftele și rutina pentru a genera predicția de risc AI
  Future<CombinedRiskPrediction> getCombinedRiskPrediction({
    String? uid,
    required String routine,
  }) async {
    final relapseSummary = await getRelapseSummary(uid: uid);
    final cravingSummary = await getCravingSummary(uid: uid);
    return CombinedRiskPrediction.predict(
      now: DateTime.now(),
      routine: routine,
      relapseSummary: relapseSummary,
      cravingSummary: cravingSummary,
    );
  }
}

final databaseService = DatabaseService();
