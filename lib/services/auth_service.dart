import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:math';
import 'credential_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final CredentialService _credentialService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService(this._auth, this._googleSignIn, this._credentialService);

  Future<void> _ensureUserDocument(UserCredential credential) async {
    try {
      final userDoc = _firestore.collection('users').doc(credential.user!.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        debugPrint('Creating new user document for ${credential.user!.email}');
        await userDoc.set({
          'email': credential.user!.email,
          'createdAt': FieldValue.serverTimestamp(),
          'authType': credential.credential?.signInMethod ?? 'password',
        });
      }
    } catch (e) {
      debugPrint('Error ensuring user document: $e');
      // Don't throw here - we want authentication to succeed even if this fails
    }
  }

  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      debugPrint('Attempting email/password sign-in for $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('Email sign-in successful for ${credential.user?.email}');
      await _ensureUserDocument(credential);
      await _credentialService.addUserAccount(email, password, 'password');

      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'Firebase auth exception during sign-in: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Unexpected error during sign-in: $e');
      throw Exception('Login failed: $e');
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      debugPrint('Attempting Google sign-in');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google sign-in aborted by user');
        throw Exception('Sign in aborted');
      }

      debugPrint('Getting Google auth tokens');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('Signing in with Google credential');
      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('Google sign-in successful for ${userCredential.user?.email}');

      await _ensureUserDocument(userCredential);
      await _credentialService.addUserAccount(
        googleUser.email,
        null,
        'google',
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'Firebase auth exception during Google sign-in: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Unexpected error during Google sign-in: $e');
      throw Exception('Google sign-in failed: $e');
    }
  }

  Future<UserCredential> signInWithApple() async {
    try {
      debugPrint('Attempting Apple sign-in');

      // Web implementation for Apple Sign-In
      if (kIsWeb) {
        debugPrint('Using web implementation for Apple Sign-In');

        // Create an OAuthProvider for Apple
        final provider = OAuthProvider('apple.com');
        provider.setCustomParameters({
          'locale': 'en', // Specify language
          'prompt': 'consent' // Always require consent
        });

        // Sign in with popup for better user experience on web
        debugPrint('Opening Apple sign-in popup');
        return await _auth.signInWithPopup(provider);
      }

      // Native iOS/macOS implementation - use existing code
      // Check if Apple Sign-In is available on this device
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        debugPrint('Apple Sign-In is not available on this device');
        throw Exception('Apple Sign-In is not available on this device');
      }

      // Request credential for the Apple ID with detailed error handling
      debugPrint('Requesting Apple ID credential...');
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      ).catchError((error) {
        debugPrint('Detailed Apple sign-in error: $error');
        if (error is SignInWithAppleAuthorizationException) {
          switch (error.code) {
            case AuthorizationErrorCode.canceled:
              throw Exception('Apple Sign-In was canceled by the user');
            case AuthorizationErrorCode.failed:
              throw Exception('Apple Sign-In failed: ${error.message}');
            case AuthorizationErrorCode.invalidResponse:
              throw Exception('Apple Sign-In returned an invalid response');
            case AuthorizationErrorCode.notHandled:
              throw Exception('Apple Sign-In request was not handled');
            case AuthorizationErrorCode.unknown:
              throw Exception(
                  'Apple Sign-In failed with an unknown error: ${error.message}');
            default:
              throw Exception('Apple Sign-In failed: ${error.message}');
          }
        }
        throw Exception('Apple Sign-In failed: $error');
      });

      debugPrint('Apple ID credential obtained. Checking token...');

      // Verify we have the identity token
      if (appleCredential.identityToken == null) {
        debugPrint('Apple identity token is null');
        throw Exception('Could not get Apple identity token');
      }

      debugPrint('Creating OAuth credential with Apple tokens');
      // Create an OAuthCredential
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken!,
        accessToken: appleCredential.authorizationCode,
      );

      debugPrint('Signing in with Apple credential to Firebase');
      // Sign in with Firebase
      final userCredential =
          await _auth.signInWithCredential(oauthCredential).catchError((error) {
        debugPrint('Firebase sign-in with Apple credential failed: $error');
        throw Exception('Firebase sign-in with Apple failed: $error');
      });

      debugPrint('Apple sign-in successful for ${userCredential.user?.email}');

      // Get user email, which may be null if the user has hidden their email
      String? email = userCredential.user?.email;
      debugPrint('User email from credential: $email');

      // Get first and last name
      String? displayName;
      if (appleCredential.givenName != null ||
          appleCredential.familyName != null) {
        displayName = [appleCredential.givenName, appleCredential.familyName]
            .where((name) => name != null && name.isNotEmpty)
            .join(' ');

        debugPrint('Display name from Apple credential: $displayName');

        // Update display name if we got it and it's not already set
        if (displayName.isNotEmpty &&
            (userCredential.user?.displayName == null ||
                userCredential.user?.displayName!.isEmpty == true)) {
          await userCredential.user?.updateDisplayName(displayName);
          debugPrint('Updated user display name to: $displayName');
        }
      }

      await _ensureUserDocument(userCredential);
      if (email != null) {
        await _credentialService.addUserAccount(
          email,
          null,
          'apple',
        );
        debugPrint('Added Apple user account to credential service: $email');
      } else {
        debugPrint('Warning: No email available from Apple Sign-In');
      }

      return userCredential;
    } on SignInWithAppleException catch (e) {
      debugPrint('Apple sign-in exception: ${e.toString()}');
      throw Exception('Apple sign-in failed: $e');
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'Firebase auth exception during Apple sign-in: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Unexpected error during Apple sign-in: $e');
      throw Exception('Apple sign-in failed: $e');
    }
  }

  Future<void> switchAccount(String email) async {
    final accountDetails = await _credentialService.getAccountDetails(email);
    if (accountDetails == null) throw Exception('Account not found');

    if (accountDetails['authType'] == 'google') {
      await signInWithGoogle();
    } else if (accountDetails['authType'] == 'apple') {
      await signInWithApple();
    } else if (accountDetails['authType'] == 'password') {
      final password = accountDetails['password'];
      if (password == null || password.isEmpty) {
        throw Exception('Password not found for account');
      }
      await signInWithEmailAndPassword(email, password);
    }
  }

  Future<void> signOut() async {
    try {
      // First try to sign out from Firebase, as this is most important
      await _auth.signOut();
      debugPrint('Successfully signed out from Firebase');

      // Then attempt to sign out from Google, but handle errors gracefully
      if (_auth.currentUser == null) {
        try {
          // On web, the sign-out may fail due to localhost issues during development
          // For native platforms, we can still try
          if (!kIsWeb) {
            await _googleSignIn.signOut();
            debugPrint('Successfully signed out from Google');
          } else {
            debugPrint('Skipping Google sign-out on web platform');
          }
        } catch (e) {
          // Just log the error but don't fail the whole sign-out process
          // This addresses the PlatformException on localhost development
          debugPrint('Google Sign-Out Error (non-critical): $e');
        }
      }
    } catch (e) {
      debugPrint('Sign-out error: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    debugPrint('Handling auth exception: ${e.code}');
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found with this email');
      case 'wrong-password':
        return Exception('Wrong password');
      case 'invalid-email':
        return Exception('Invalid email address');
      case 'user-disabled':
        return Exception('This account has been disabled');
      case 'account-exists-with-different-credential':
        return Exception(
            'An account already exists with the same email address');
      case 'invalid-credential':
        return Exception('The credential is malformed or has expired');
      case 'operation-not-allowed':
        return Exception('This operation is not allowed');
      case 'weak-password':
        return Exception('The password is too weak');
      case 'network-request-failed':
        return Exception(
            'Network connection failed. Please check your internet connection');
      default:
        return Exception(e.message ?? 'Authentication failed');
    }
  }
}
