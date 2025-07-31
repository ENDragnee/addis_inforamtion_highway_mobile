import 'package:addis_information_highway_mobile/services/auth_service.dart';
import 'package:addis_information_highway_mobile/theme/dracula_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();

    // Setup the controller for our entry animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Define a fade-in animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Define a slide-up animation
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This line is crucial. It tells the widget to listen for changes in the
    // AuthService. When the auth state changes (e.g., from 'unknown' to
    // 'unauthenticated'), the GoRouter's redirect logic will fire and
    // navigate away from this screen automatically.
    context.watch<AuthService>();

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Using a Spacer to push the main content up from the center
            const Spacer(flex: 2),

            // The animated content block
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    const Icon(
                      Icons.gite_rounded,
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

            // A delayed progress indicator that fades in after the main animation
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

            // Using another Spacer to push the footer to the bottom
            const Spacer(flex: 3),

            // Footer
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