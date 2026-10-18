import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_quit_smoking/pages/models/goal_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
}

final databaseService = DatabaseService();
