import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import '../../core/interfaces/firebase_auth_interface.dart';
import '../../services/credential_service.dart';
import 'token_management_service.dart';
import 'user_document_service.dart';
import '../../domain/interfaces/auth_service_interface.dart';

/// Service responsible for core authentication operations
/// Single Responsibility: Authentication flows (email, Google, Apple)
class AuthenticationService implements IAuthService {
  final IFirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final CredentialService _credentialService;
  final TokenManagementService _tokenService;
  final UserDocumentService _userDocumentService;

  AuthenticationService(
    this._auth,
    this._googleSignIn,
    this._credentialService,
    this._tokenService,
    this._userDocumentService,
  );

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
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
      await _userDocumentService.ensureUserDocument(credential);

      // Store user account details
      if (credential.user != null) {
        await _credentialService.saveUserAccount(
          credential.user!,
          password: password,
          authType: 'password',
        );

        // Obtain and store custom token for this user
        await _tokenService.obtainAndStoreCustomToken(credential.user!);
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

  @override
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

      await _userDocumentService.ensureUserDocument(userCredential);
      await _credentialService.addUserAccount(googleUser.email, null, 'google');

      // Store Firebase token and custom token
      if (userCredential.user != null) {
        await _tokenService.storeFirebaseToken(userCredential.user!);
        await _tokenService.obtainAndStoreCustomToken(userCredential.user!);
      }

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

  @override
  Future<UserCredential> signInWithApple() async {
    try {
      debugPrint('Attempting Apple sign-in');

      // Web implementation for Apple Sign-In
      if (kIsWeb) {
        debugPrint('Using web implementation for Apple Sign-In');

        // Create an OAuthProvider for Apple
        final provider = OAuthProvider('apple.com');
        provider.setCustomParameters({
          'locale': 'en',
          'prompt': 'consent',
        });

        debugPrint('Opening Apple sign-in popup');
        return await _auth.signInWithPopup(provider);
      }

      // Native iOS/macOS implementation
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        debugPrint('Apple Sign-In is not available on this device');
        throw Exception('Apple Sign-In is not available on this device');
      }

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

      if (appleCredential.identityToken == null) {
        debugPrint('Apple identity token is null');
        throw Exception('Could not get Apple identity token');
      }

      debugPrint('Creating OAuth credential with Apple tokens');
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken!,
        accessToken: appleCredential.authorizationCode,
      );

      debugPrint('Signing in with Apple credential to Firebase');
      final userCredential =
          await _auth.signInWithCredential(oauthCredential).catchError((error) {
        debugPrint('Firebase sign-in with Apple credential failed: $error');
        throw Exception('Firebase sign-in with Apple failed: $error');
      });

      debugPrint('Apple sign-in successful for ${userCredential.user?.email}');

      String? email = userCredential.user?.email;
      String? firstName = appleCredential.givenName;
      String? lastName = appleCredential.familyName;

      // Update display name if available
      String? displayName;
      if (firstName != null || lastName != null) {
        displayName = [firstName, lastName]
            .where((name) => name?.isNotEmpty ?? false)
            .join(' ');

        if (displayName.isNotEmpty &&
            (userCredential.user?.displayName == null ||
                userCredential.user?.displayName!.isEmpty == true)) {
          await userCredential.user?.updateDisplayName(displayName);
        }
      }

      // Create or update Firestore user document
      await _userDocumentService.createOrUpdateUserDocument(
        userCredential.user!.uid,
        email: email,
        firstName: firstName ?? 'User',
        lastName: lastName,
      );

      await _userDocumentService.ensureUserDocument(userCredential);
      if (email != null) {
        await _credentialService.addUserAccount(email, null, 'apple');
      }

      // Store Firebase token
      if (userCredential.user != null) {
        await _tokenService.storeFirebaseToken(userCredential.user!);
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

  @override
  Future<void> switchAccount(String email) async {
    try {
      debugPrint('Switching to account: $email');

      final accountDetails = await _credentialService.getAccountDetails(email);
      if (accountDetails == null) {
        throw Exception('Account details not found for email: $email');
      }

      final userId = accountDetails['userId'];
      final authType = accountDetails['authType'] ?? 'password';

      // Try to use stored Firebase token first
      if (userId != null) {
        final idToken = await _tokenService.getStoredFirebaseToken(userId);
        final isValid = await _tokenService.isStoredTokenValid(userId);

        if (idToken != null && isValid) {
          try {
            await _auth.signInWithCustomToken(idToken);
            debugPrint('Successfully signed in with stored Firebase token');
            return;
          } catch (e) {
            debugPrint('Error signing in with stored Firebase token: $e');
          }
        }
      }

      // Re-authenticate based on auth type
      if (authType == 'password') {
        final password = accountDetails['password'];
        if (password == null || password.isEmpty) {
          throw Exception('Password not found for account');
        }
        await _auth.signInWithEmailAndPassword(email: email, password: password);
        debugPrint('Successfully signed in with password');
      } else if (authType == 'google') {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser != null) {
          final GoogleSignInAuthentication googleAuth =
              await googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          await _auth.signInWithCredential(credential);
          debugPrint('Successfully signed in with Google');
        } else {
          throw Exception('Google sign-in was cancelled by user');
        }
      } else if (authType == 'apple') {
        throw Exception(
            'Please sign in with Apple again to access this account');
      } else {
        throw Exception(
            'Unable to switch to account automatically. Please sign in again.');
      }
    } catch (e) {
      debugPrint('Error switching account: $e');
      rethrow;
    }
  }

  @override
  Future<SignOutResult> signOut() async {
    try {
      final userEmail = _auth.currentUser?.email;

      await _auth.signOut();
      debugPrint('Successfully signed out from Firebase');

      if (userEmail != null) {
        await _tokenService.removeOAuthToken(userEmail);
      }

      final accounts = await _credentialService.getUserAccounts();
      final activeUserId = await _credentialService.getActiveUserId();

      await _credentialService.clearActiveUser();

      if (activeUserId != null) {
        await _credentialService.removeUserAccount(activeUserId);
      }

      accounts.removeWhere((account) => account['userId'] == activeUserId);
      if (accounts.isNotEmpty) {
        final nextAccount = accounts.first;
        final email = nextAccount['email'];
        if (email != null && email.isNotEmpty) {
          debugPrint('Switching to next available account: $email');
          await switchAccount(email);
          return SignOutResult.switchedToAnotherUser;
        }
      }

      if (!kIsWeb) {
        try {
          await _googleSignIn.signOut();
        } catch (e) {
          debugPrint('Google Sign-Out Error (non-critical): $e');
        }
      }

      return SignOutResult.fullySignedOut;
    } catch (e) {
      debugPrint('Sign-out error: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  @override
  Future<void> deleteAccount(String userId) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.uid != userId) {
        throw Exception('No matching user is currently signed in');
      }

      // Delete user data from Firestore
      await _userDocumentService.deleteUserDocument(user.uid);

      // Remove user account from credential service
      await _credentialService.removeUserAccount(user.uid);

      // Delete the Firebase Auth user
      await _auth.deleteUser(user);

      debugPrint('Account deleted successfully: ${user.email}');
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'Firebase auth exception during account deletion: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Error deleting account: $e');
      throw Exception('Failed to delete account: $e');
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

