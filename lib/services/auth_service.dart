import 'dart:convert';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  // Null on web: constructing GoogleSignIn() there eagerly initializes the
  // google_sign_in_web plugin, which asserts unless a client ID / meta tag is
  // configured. Web sign-in/out goes through FirebaseAuth's popup flow instead.
  final GoogleSignIn? _googleSignIn;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _functions = functions ?? FirebaseFunctions.instance,
       _googleSignIn = googleSignIn ?? (kIsWeb ? null : GoogleSignIn());

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(displayName);
    return credential;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      // On web, FirebaseAuth's own popup flow avoids extra OAuth client wiring.
      return _auth.signInWithPopup(GoogleAuthProvider());
    }
    final googleUser = await _googleSignIn!.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Sign in was cancelled',
      );
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithApple() async {
    if (kIsWeb) {
      // The sign_in_with_apple plugin's web flow needs its own Services ID
      // wiring; FirebaseAuth's popup flow reuses the Apple provider already
      // configured in the Firebase console (Services ID + key), and handles
      // the nonce and name for us.
      final provider =
          OAuthProvider('apple.com')
            ..addScope('email')
            ..addScope('name');
      return _auth.signInWithPopup(provider);
    }
    // Firebase requires the raw nonce alongside the SHA-256 of it sent to
    // Apple, so it can verify the ID token was issued for this request.
    final rawNonce = _generateNonce();
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
    );
    final oauthCredential = OAuthProvider(
      'apple.com',
    ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);
    final userCredential = await _auth.signInWithCredential(oauthCredential);
    // Apple only returns the name on the very first authorization, and
    // Firebase doesn't populate displayName from the Apple credential itself.
    final givenName = appleCredential.givenName;
    final familyName = appleCredential.familyName;
    if ((givenName != null || familyName != null) &&
        userCredential.user?.displayName == null) {
      await userCredential.user?.updateDisplayName(
        [givenName, familyName].whereType<String>().join(' '),
      );
    }
    return userCredential;
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateDisplayName(String displayName) async {
    await _auth.currentUser?.updateDisplayName(displayName);
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn!.signOut();
    }
    await _auth.signOut();
  }

  /// Permanently deletes the signed-in user's account and all of their data
  /// (profile, weight/meal/workout history, photos, friendships, chats) via
  /// the `deleteAccount` Cloud Function, then clears the local session.
  ///
  /// Runs server-side under the Admin SDK rather than `currentUser.delete()`
  /// so it isn't blocked by Firestore's owner-delete rules or Firebase
  /// Auth's `requires-recent-login` check for stale sessions.
  Future<void> deleteAccount() async {
    await _revokeAppleTokenIfNeeded();
    await _functions.httpsCallable('deleteAccount').call();
    if (!kIsWeb) {
      await _googleSignIn!.signOut();
    }
    await _auth.signOut();
  }

  /// Apple requires that deleting an account created with Sign in with Apple
  /// also revoke the associated Apple token (App Store Review Guideline
  /// 5.1.1(v)) — the account must not just disappear from our own backend.
  ///
  /// Revocation needs a *fresh* authorization code; the one from the user's
  /// original sign-in is long since expired and single-use, so this shows
  /// the native Apple sign-in sheet again right before deleting and revokes
  /// with that code. It never calls [FirebaseAuth.signInWithCredential], so
  /// it only reads a fresh code from Apple — it doesn't touch or replace the
  /// current session.
  ///
  /// iOS/macOS only: on web, `sign_in_with_apple`'s popup flow doesn't
  /// return an authorization code to revoke, and non-Apple accounts have
  /// nothing to revoke.
  Future<void> _revokeAppleTokenIfNeeded() async {
    final isAppleUser =
        _auth.currentUser?.providerData.any(
          (p) => p.providerId == 'apple.com',
        ) ??
        false;
    if (!isAppleUser || kIsWeb) return;

    final rawNonce = _generateNonce();
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email],
      nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
    );
    await _auth.revokeTokenWithAuthorizationCode(
      appleCredential.authorizationCode,
    );
  }
}
