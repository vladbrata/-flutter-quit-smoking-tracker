import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/services/database_service.dart';

ValueNotifier<AuthServices> authServices = ValueNotifier<AuthServices>(
  AuthServices(),
);

class AuthServices {
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  User? get currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  Stream<User?> get authStateChanges {
    try {
      return FirebaseAuth.instance.authStateChanges();
    } catch (_) {
      return const Stream.empty();
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final userCredential = await firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (userCredential.user != null) {
      await databaseService.saveUserProfile(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email ?? email.trim(),
        name: userCredential.user!.displayName,
      );
      await databaseService.syncFromFirestoreToLocal(userCredential.user!.uid);
    }

    return userCredential;
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
    String? name,
  }) async {
    final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (userCredential.user != null) {
      if (name != null && name.trim().isNotEmpty) {
        await userCredential.user!.updateDisplayName(name.trim());
      }
      await databaseService.saveUserProfile(
        uid: userCredential.user!.uid,
        email: email.trim(),
        name: name,
      );
    }

    return userCredential;
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> resetPassword({required String email}) async {
    await firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> updateUsername({required String username}) async {
    await currentUser!.updateDisplayName(username);
    await databaseService.saveUserProfile(
      uid: currentUser!.uid,
      email: currentUser!.email ?? '',
      name: username,
    );
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.delete();
    await firebaseAuth.signOut();
  }

  static String getReadableErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Nu a fost găsit niciun cont cu această adresă de email.';
        case 'wrong-password':
          return 'Parola introdusă este incorectă.';
        case 'invalid-credential':
          return 'Email sau parolă incorectă.';
        case 'email-already-in-use':
          return 'Există deja un cont înregistrat cu acest email.';
        case 'invalid-email':
          return 'Adresa de email introdusă nu este validă.';
        case 'weak-password':
          return 'Parola este prea simplă (trebuie să aibă cel puțin 6 caractere).';
        case 'too-many-requests':
          return 'Prea multe încercări eșuate. Vă rugăm să încercați din nou mai târziu.';
        case 'network-request-failed':
          return 'Problemă de conexiune la internet. Verificați rețeaua.';
        default:
          return error.message ?? 'A apărut o eroare necunoscută.';
      }
    }
    return error.toString();
  }
}
