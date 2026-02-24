import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance
    ..initialize(
      serverClientId: '467050386231-1nsm8dljegao008nlo3lr0etd4pkatl9.apps.googleusercontent.com',
    );

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      // ✅ DO NOT sign out before login
      final GoogleSignInAccount? account = await _googleSignIn.authenticate();

      // User cancelled or dialog dismissed
      if (account == null) return null;

      final GoogleSignInAuthentication auth = await account.authentication;

      if (auth.idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-id-token',
          message: 'Google ID token was null',
        );
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(credential);

      final user = result.user;
      if (user == null) return null;

      await _ensureUserDocument(user);
      return user;
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('🔥 FirebaseAuthException');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('🔥 Non-Firebase Exception');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  Future<void> _ensureUserDocument(User user) async {
    final ref = _firestore.collection('users').doc(user.uid);
    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        'name': user.displayName ?? 'User',
        'email': user.email,
        'role': 'member',
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}