import 'package:addis_information_highway_mobile/services/auth_service.dart';
import 'package:addis_information_highway_mobile/theme/dracula_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start the animation when the screen is first built
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // The actual logic is now cleanly handled by the AuthService.
      // This single call will handle the OIDC flow, token exchange,
      // and new device key registration if needed.
      await context.read<AuthService>().login();

      // GoRouter's redirect logic will handle navigation automatically on success,
      // as the authState will change to 'authenticated'.
    } catch (e) {
      // Show an error message if the login process fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Login failed. Please try again.',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      // Ensure the loading state is always turned off, regardless of outcome
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(32.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Section
                      const Icon(
                        Icons.gite_rounded,
                        size: 80,
                        color: draculaPurple,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Addis Information Highway',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your Data, Your Control. Securely sign in to manage your data consent.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          color: draculaComment,
                        ),
                      ),
                      const SizedBox(height: 64),

                      // Login Button Section
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleLogin,
                        icon: _isLoading
                            ? Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            strokeWidth: 3,
                            color: draculaBackground,
                          ),
                        )
                            : const Icon(Icons.lock_open_rounded, size: 20),
                        label: Text(
                          _isLoading ? 'Connecting...' : 'Sign In with VeriFayda',
                          style: textTheme.labelLarge?.copyWith(fontSize: 16),
                        ),
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all<EdgeInsets>(
                            const EdgeInsets.symmetric(vertical: 18),
                          ),
                          backgroundColor: WidgetStateProperty.all(draculaGreen),
                          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          elevation: WidgetStateProperty.all(5),
                        ),
                      ),
                      const SizedBox(height: 120),

                      // Footer Section
                      Text(
                        'Powered by ASCII Technologies',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}