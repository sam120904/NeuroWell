import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '591423985812-as1njdt01j4t84samc3sf6vgfh8i2vk4.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      debugPrint('Attempting Google Sign-In');
      
      // For web, use Firebase Auth's signInWithPopup directly
      // The google_sign_in plugin's signIn() method is deprecated for web
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        final UserCredential result = await _auth.signInWithPopup(googleProvider);
        debugPrint('Firebase Sign-In successful for user: ${result.user?.uid}');
        return result.user;
      }
      
      // For mobile platforms, use the google_sign_in plugin
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('Google Sign-In was cancelled by user');
        return null;
      }

      debugPrint('Google Sign-In successful for: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential result = await _auth.signInWithCredential(credential);
      debugPrint('Firebase Sign-In successful for user: ${result.user?.uid}');
      
      return result.user;
    } catch (e) {
      debugPrint('Google Sign-In failed: $e');
      rethrow;
    }
  }

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
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
