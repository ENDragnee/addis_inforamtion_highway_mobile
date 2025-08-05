import 'package:addis_information_highway_mobile/services/auth_service.dart';
import 'package:addis_information_highway_mobile/theme/dracula_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:addis_information_highway_mobile/services/test_user_service.dart'; // IMPORT

// A simple model for the test user data fetched from the backend.
class TestUser {
  final String id;
  final String name;
  final String sessionToken;
  final bool needsFcmTokenSetup;

  TestUser({
    required this.id,
    required this.name,
    required this.sessionToken,
    required this.needsFcmTokenSetup,
  });

  factory TestUser.fromJson(Map<String, dynamic> json) {
    return TestUser(
      id: json['id'],
      name: json['name'],
      sessionToken: json['sessionToken'],
      needsFcmTokenSetup: json['needsFcmTokenSetup'],
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _isLoadingOidc = false;

  // State for the animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleOidcLogin() async {
    setState(() => _isLoadingOidc = true);
    try {
      await context.read<AuthService>().login();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Login failed. Please try again.', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoadingOidc = false);
    }
  }

  Future<void> _handleTestUserLogin(TestUser user) async {
    await context.read<AuthService>().debugLogin(
      sessionToken: user.sessionToken,
      needsFcmTokenSetup: user.needsFcmTokenSetup,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Listen to the TestUserService to rebuild when its data changes
    final testUserService = context.watch<TestUserService>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Card(
                  elevation: 8,
                  shadowColor: Colors.black.withAlpha(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.shieldCheck, size: 48, color: draculaPurple),
                        const SizedBox(height: 16),
                        Text('Choose an account', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('to continue to Addis Information Highway', style: textTheme.bodyMedium?.copyWith(color: draculaComment)),
                        const SizedBox(height: 24),
                        const Divider(color: draculaCurrentLine),

                        // Pass the state from the service to the build method
                        _buildTestUserSection(
                          isLoading: testUserService.isLoading,
                          error: testUserService.error,
                          testUsers: testUserService.testUsers,
                        ),

                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          leading: _isLoadingOidc
                              ? const SizedBox(width: 40, height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                              : const CircleAvatar(backgroundColor: draculaCurrentLine, child: Icon(LucideIcons.keyRound, color: draculaCyan)),
                          title: Text('Sign In with VeriFayda', style: textTheme.titleMedium),
                          subtitle: Text('Use the official secure login', style: textTheme.bodySmall),
                          onTap: _isLoadingOidc ? null : _handleOidcLogin,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          hoverColor: draculaPink.withAlpha(10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestUserSection({
    required bool isLoading,
    required String? error,
    required List<TestUser> testUsers,
  }) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: Center(child: CircularProgressIndicator(color: draculaComment)),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(error, style: const TextStyle(color: draculaRed), textAlign: TextAlign.center),
      );
    }
    if (testUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: testUsers.length,
      itemBuilder: (context, index) {
        final user = testUsers[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          leading: const CircleAvatar(backgroundColor: draculaCurrentLine, child: Icon(LucideIcons.user, color: draculaComment)),
          title: Text(user.name, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text('Test Account', style: Theme.of(context).textTheme.bodySmall),
          onTap: () => _handleTestUserLogin(user),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          hoverColor: draculaPink.withAlpha(10),
        );
      },
      separatorBuilder: (context, index) => const Divider(color: draculaCurrentLine, height: 1),
    );
  }
}