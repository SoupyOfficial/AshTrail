import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool isAddingAccount;

  const LoginScreen({
    super.key,
    this.isAddingAccount = false,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Only check auth state if not adding an account
    if (!widget.isAddingAccount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(authStateProvider).whenData((user) {
          if (user != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        });
      });
    }
  }

  Future<void> _login() async {
    // Clear previous errors
    setState(() => _errorMessage = null);

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        // Debug print to verify credentials format
        debugPrint('Attempting login with email: $email');

        await ref.read(authServiceProvider).signInWithEmailAndPassword(
              email,
              password,
            );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } catch (e) {
        // Enhanced error handling
        setState(() {
          _errorMessage = 'Login failed: ${e.toString()}';
          _isLoading = false;
        });
        debugPrint('Login error: $e');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(_errorMessage ?? 'An unknown error occurred')),
          );
        }
      } finally {
        if (mounted && _isLoading) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('---------------------------------------------');
      debugPrint('Attempting Google Sign-In');
      debugPrint('isAddingAccount: ${widget.isAddingAccount}');

      final result = await ref.read(authServiceProvider).signInWithGoogle();

      // Debug user info after sign-in
      debugPrint('Google Sign-In successful');
      debugPrint('User email: ${result.user?.email}');
      debugPrint('User displayName: ${result.user?.displayName}');
      debugPrint('User photoURL: ${result.user?.photoURL}');
      debugPrint('Provider ID: ${result.credential?.providerId}');
      debugPrint('---------------------------------------------');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google login failed: ${e.toString()}';
        _isLoading = false;
      });
      debugPrint('Google login error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage ?? 'An unknown error occurred')),
        );
      }
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('=============================================');
      debugPrint('APPLE SIGN-IN DEBUG - LOGIN SCREEN');
      debugPrint('isAddingAccount: ${widget.isAddingAccount}');
      debugPrint(
          'Platform: ${kIsWeb ? 'Web' : defaultTargetPlatform.toString()}');

      final result = await ref.read(authServiceProvider).signInWithApple();

      // Debug user info after sign-in
      debugPrint('Apple Sign-In successful');
      debugPrint('User email: ${result.user?.email}');
      debugPrint('User displayName: ${result.user?.displayName}');
      debugPrint('User photoURL: ${result.user?.photoURL}');
      debugPrint('Provider ID: ${result.credential?.providerId}');

      // Continue with navigation
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Widget _buildAppleSignInButton() {
    if (kIsWeb) {
      // Custom button for web platform
      return ElevatedButton.icon(
        icon: const Icon(Icons.apple),
        onPressed: _isLoading ? null : _signInWithApple,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        label: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Text('Sign in with Apple'),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      // Use the native Apple Sign-In button for iOS and macOS
      return SignInWithAppleButton(
        onPressed: _isLoading ? () {} : _signInWithApple,
        style: SignInWithAppleButtonStyle.black,
      );
    } else {
      // For other platforms where Apple Sign-In isn't available, return an empty container
      return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAddingAccount ? 'Add Account' : 'Login'),
        leading: widget.isAddingAccount
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App logo or icon
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  height: 100,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Image error: $error');
                    return const Icon(Icons.cloud, size: 100);
                  },
                ),
              ),

              // Error message display
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                ),
                obscureText: !_showPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                onPressed: _isLoading ? null : _loginWithGoogle,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                label: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login with Google'),
              ),

              const SizedBox(height: 12),

              // Replace the conditional Apple button with our new method
              _buildAppleSignInButton(),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegisterScreen()),
                  );
                },
                child: const Text('Need an account? Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
