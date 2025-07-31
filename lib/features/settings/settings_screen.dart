import 'package:addis_information_highway_mobile/services/auth_service.dart';
import 'package:addis_information_highway_mobile/theme/dracula_theme.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import  'package:lucide_icons_flutter/lucide_icons.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _isBiometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _canCheckBiometrics = canCheck;
      // Load the user's saved preference, defaulting to false
      _isBiometricsEnabled = prefs.getBool('biometrics_enabled') ?? false;
    });
  }

  Future<void> _toggleBiometrics(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      // If turning on, authenticate first to confirm user intent
      try {
        final didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to enable biometric login',
          options: const AuthenticationOptions(biometricOnly: true),
        );
        if (didAuthenticate) {
          await prefs.setBool('biometrics_enabled', true);
          setState(() => _isBiometricsEnabled = true);
        }
      } catch (e) {
        print('Biometric auth error: $e');
      }
    } else {
      // If turning off, just save the preference
      await prefs.setBool('biometrics_enabled', false);
      setState(() => _isBiometricsEnabled = false);
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: draculaCurrentLine,
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: draculaComment)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Log Out', style: TextStyle(color: draculaRed)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                context.read<AuthService>().logout();
                // GoRouter will automatically redirect to /login
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (_canCheckBiometrics)
          SwitchListTile(
            title: const Text('Enable Biometric Login'),
            subtitle: const Text('Use Face ID or Fingerprint to log in'),
            value: _isBiometricsEnabled,
            onChanged: _toggleBiometrics,
            secondary: const Icon(LucideIcons.fingerprint, color: draculaComment),
            activeColor: draculaGreen,
          ),
        const Divider(color: draculaCurrentLine),
        ListTile(
          leading: const Icon(LucideIcons.logOut, color: draculaRed),
          title: const Text('Log Out', style: TextStyle(color: draculaRed)),
          onTap: _showLogoutDialog,
        ),
      ],
    );
  }
}