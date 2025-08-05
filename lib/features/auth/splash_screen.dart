import 'dart:async';
import 'package:addis_information_highway_mobile/services/auth_service.dart';
import 'package:addis_information_highway_mobile/services/test_user_service.dart';
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

  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();

    // --- NEW LOGIC: Trigger the test user fetch ---
    // We use `context.read` because we only want to call this method once
    // and don't need to rebuild the splash screen when the data arrives.
    context.read<TestUserService>().fetchTestUsers();

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

    _animationController.forward();
    _startRedirectTimer();
  }

  void _startRedirectTimer() {
    _redirectTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        print("Splash Screen: 5-second timeout reached. Forcing navigation to /login.");
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This watch call is still crucial for the main auth flow redirection.
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
                      LucideIcons.pipette, // Using a more appropriate icon
                      size: 100,
                      color: draculaPurple,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Addis Information Highway',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your Data, Your Control.',
                      style: textTheme.bodyLarge?.copyWith(color: draculaComment),
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