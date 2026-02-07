import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      debugPrint('Attempting sign in with email: $email');
      debugPrint('Auth Config: ${_auth.app.options.asMap}');
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('Sign in successful for user: ${result.user?.uid}');
      return result.user;
    } catch (e) {
      debugPrint('Sign in failed: $e');
      if (e is FirebaseAuthException) {
        debugPrint('Auth Error Code: ${e.code}');
        debugPrint('Auth Error Message: ${e.message}');
      }
      rethrow;
    }
  }

  // Register with email and password
  Future<User?> signUp(String email, String password) async {
    try {
      debugPrint('Attempting sign up with email: $email');
      debugPrint('Auth Config: ${_auth.app.options.asMap}');
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('Sign up successful for user: ${result.user?.uid}');
      return result.user;
    } catch (e) {
      debugPrint('Sign up failed: $e');
      if (e is FirebaseAuthException) {
        debugPrint('Auth Error Code: ${e.code}');
        debugPrint('Auth Error Message: ${e.message}');
      }
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
