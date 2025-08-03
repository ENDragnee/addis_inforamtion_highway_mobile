import 'dart:async';
import 'package:addis_information_highway_mobile/services/auth_service.dart';
import 'package:addis_information_highway_mobile/theme/dracula_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // A timer to handle the 5-second fallback redirect.
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();

    // Setup the controller for our entry animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    // Start the animations
    _animationController.forward();

    // --- NEW LOGIC: Start the 5-second timer ---
    _startRedirectTimer();
  }

  void _startRedirectTimer() {
    // This timer will fire after 5 seconds.
    _redirectTimer = Timer(const Duration(seconds: 5), () {
      // Check if the widget is still in the widget tree before navigating.
      if (mounted) {
        print("Splash Screen: 5-second timeout reached. Forcing navigation to /login.");
        // Use GoRouter to navigate to the login screen.
        // The router's redirect logic will still run, but this ensures
        // we leave the splash screen if the auth state is stuck on 'unknown'.
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    // It's crucial to cancel the timer to prevent memory leaks if the
    // user navigates away before the 5 seconds are up.
    _redirectTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This line is still important. If the AuthService finishes its check
    // *before* the 5-second timer, the GoRouter's redirect logic will
    // navigate away immediately, and the timer will be cancelled in dispose().
    context.watch<AuthService>();

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    const Icon(
                      LucideIcons.house, // Corrected the icon name
                      size: 100,
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
                      'Your Data, Your Control.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: draculaComment,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80),

            FadeTransition(
              opacity: CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(draculaPink),
                strokeWidth: 3,
              ),
            ),

            const Spacer(flex: 3),

            Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Powered by ASCII Technologies',
                  style: textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}