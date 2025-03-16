import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:smoke_log/theme/theme_provider.dart';
import 'dart:math';
import 'credential_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provide credential service
final credentialServiceProvider = Provider<CredentialService>((ref) {
  return CredentialService();
});

// Provide list of user accounts
final userAccountsProvider = FutureProvider<List<Map<String, String>>>((
  ref,
) async {
  final credentialService = ref.watch(credentialServiceProvider);
  return await credentialService.getUserAccounts();
});

// Provide active user ID
final activeUserIdProvider = FutureProvider<String?>((ref) async {
  final credentialService = ref.watch(credentialServiceProvider);
  return await credentialService.getActiveUserId();
});

// Track the currently active user type
final userAuthTypeProvider = StateProvider<String?>((ref) => null);

// Auth provider for managing authentication
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CredentialService _credentialService;

  AuthNotifier(this._credentialService) : super(const AsyncValue.loading()) {
    _initialize();
  }

  void _initialize() async {
    try {
      // Save the current user immediately if there is one
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        debugPrint('Current user found on startup: ${currentUser.email}');
        await _credentialService.saveUserAccount(currentUser);
      } else {
        debugPrint('No current user on startup');
      }

      // Listen to Firebase auth state changes
      _auth.authStateChanges().listen((user) async {
        if (user != null) {
          debugPrint('Auth state changed: user ${user.email} logged in');
          // Save user without signing out others
          await _credentialService.saveUserAccount(user);
        } else {
          debugPrint('Auth state changed: user logged out');
        }
        state = AsyncValue.data(user);
      });

      // Check if we have an active user that should be used
      final activeUserId = await _credentialService.getActiveUserId();
      if (activeUserId != null &&
          currentUser != null &&
          currentUser.uid != activeUserId) {
        // We need to switch to the active user
        debugPrint('Switching to active user: $activeUserId');
        await switchToUser(activeUserId);
      }
    } catch (e) {
      debugPrint('Error in AuthNotifier initialization: $e');
    }
  }

  // Sign in with email and password
  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  // Switch to a different user without signing out
  Future<void> switchToUser(String userId) async {
    try {
      state = const AsyncValue.loading();

      // Get all accounts
      final accounts = await _credentialService.getUserAccounts();
      final targetAccount = accounts.firstWhere(
        (account) => account['userId'] == userId,
        orElse: () => {'userId': '', 'email': '', 'authType': ''},
      );

      if (targetAccount['userId']!.isNotEmpty) {
        // Set as active user
        await _credentialService.setActiveUser(userId);

        // Update user auth type for UI
        if (targetAccount['authType'] != null) {
          // This would need a ref to the provider - will be handled in the switchAccount method
        }

        // Check if this is already the current user
        if (_auth.currentUser?.uid != userId) {
          // We need to sign in as this user
          if (targetAccount['email']?.isNotEmpty == true) {
            await _credentialService.setActiveUser(targetAccount['email']!);
          }
        }
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Add a new account without signing out current one
  Future<void> addNewAccount(String email, String password) async {
    // First save the current user's credentials
    final currentUser = _auth.currentUser;

    try {
      // Sign in with the new account
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      final newUser = _auth.currentUser!;

      // Save the new account
      await _credentialService.saveUserAccount(newUser);

      // If we had a previous user, switch back to them
      if (currentUser != null) {
        // Here you would restore the previous session
        // This is where the implementation would need custom Firebase token handling
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((
  ref,
) {
  final credentialService = ref.watch(credentialServiceProvider);
  return AuthNotifier(credentialService);
});

// Add a provider for ThemeProvider
final themeProvider = Provider<ThemeProvider>((ref) => ThemeProvider());

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final CredentialService _credentialService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProviderRef _ref;

  AuthService(
      this._auth, this._googleSignIn, this._credentialService, this._ref);

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
    String email,
    String password,
  ) async {
    try {
      debugPrint('Attempting email/password sign-in for $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('Email sign-in successful for ${credential.user?.email}');
      await _ensureUserDocument(credential);

      // Store the password for future account switching
      if (credential.user != null) {
        await _credentialService.saveUserAccount(
          credential.user!,
          password: password,
          authType: 'password',
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Firebase auth exception during sign-in: ${e.code} - ${e.message}',
      );
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
      await _credentialService.addUserAccount(googleUser.email, null, 'google');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Firebase auth exception during Google sign-in: ${e.code} - ${e.message}',
      );
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
          'prompt': 'consent', // Always require consent
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
                'Apple Sign-In failed with an unknown error: ${error.message}',
              );
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
        displayName = [
          appleCredential.givenName,
          appleCredential.familyName,
        ].where((name) => name != null && name.isNotEmpty).join(' ');

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
        await _credentialService.addUserAccount(email, null, 'apple');
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
        'Firebase auth exception during Apple sign-in: ${e.code} - ${e.message}',
      );
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Unexpected error during Apple sign-in: $e');
      throw Exception('Apple sign-in failed: $e');
    }
  }

  Future<void> switchToUser(String userId) async {
    try {
      // Get all accounts
      final accounts = await _credentialService.getUserAccounts();
      final targetAccount = accounts.firstWhere(
        (account) => account['userId'] == userId,
        orElse: () => {},
      );

      if (targetAccount.isNotEmpty) {
        final email = targetAccount['email'];
        if (email != null && email.isNotEmpty) {
          await switchAccount(email);
        } else {
          throw Exception('Account has no email address');
        }
      } else {
        throw Exception('Account not found');
      }
    } catch (e) {
      debugPrint('Error switching to user: $e');
      throw Exception('Failed to switch accounts: $e');
    }
  }

  Future<void> switchAccount(String email) async {
    try {
      debugPrint('Attempting to switch to account: $email');

      // If this is already the current account, return immediately
      if (_auth.currentUser?.email == email) {
        debugPrint('Already signed in as $email, no need to switch');
        return;
      }

      final accountDetails = await _credentialService.getAccountDetails(email);
      if (accountDetails == null) {
        throw Exception('Account details not found');
      }

      final authType = accountDetails['authType'] ?? 'password';
      debugPrint('Account auth type: $authType');

      // Pre-set the active user to avoid unnecessary operations
      final userId = accountDetails['userId'];
      if (userId != null) {
        await _credentialService.setActiveUser(userId);
      }

      // For password auth, handle it more efficiently
      if (authType == 'password') {
        final password = accountDetails['password'];
        if (password == null || password.isEmpty) {
          throw Exception('Password not found for account: $email');
        }

        // Sign in directly without extra operations
        await _auth.signInWithEmailAndPassword(
            email: email, password: password);
        debugPrint('Switched to account: $email via password auth');
        return;
      }

      // For other auth types, use the existing methods
      switch (authType) {
        case 'google':
          await signInWithGoogle();
          break;
        case 'apple':
          await signInWithApple();
          break;
        default:
          throw Exception('Unsupported authentication type: $authType');
      }
      // After successful switch, ensure we reload theme preferences
      try {
        // Access ThemeProvider through Riverpod
        await _ref.read(themeProvider).reloadPreferences();
      } catch (e) {
        debugPrint('Error reloading theme preferences: $e');
        // Don't fail the account switch if theme reload fails
      }
    } catch (e) {
      debugPrint('Error switching account: $e');
      throw Exception('Failed to switch to account: $e');
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
          'An account already exists with the same email address',
        );
      case 'invalid-credential':
        return Exception('The credential is malformed or has expired');
      case 'operation-not-allowed':
        return Exception('This operation is not allowed');
      case 'weak-password':
        return Exception('The password is too weak');
      case 'network-request-failed':
        return Exception(
          'Network connection failed. Please check your internet connection',
        );
      default:
        return Exception(e.message ?? 'Authentication failed');
    }
  }
}
