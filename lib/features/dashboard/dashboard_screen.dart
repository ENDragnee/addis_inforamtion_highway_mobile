import 'package:addis_information_highway_mobile/features/dashboard/dashboard_content.dart';
import 'package:addis_information_highway_mobile/features/history/history_screen.dart';
import 'package:addis_information_highway_mobile/features/settings/settings_screen.dart';
import 'package:addis_information_highway_mobile/services/notification_service.dart'; // IMPORT the new service
import 'package:addis_information_highway_mobile/theme/dracula_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import  'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart'; // IMPORT provider to access the service
import 'package:firebase_messaging/firebase_messaging.dart'; // Import Firebase Messaging

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    DashboardContent(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  static const List<String> _pageTitles = <String>[
    'Dashboard',
    'History',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    context.read<NotificationService>().initialize();
  }
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        elevation: 0,
      ),
      // IndexedStack is efficient because it keeps the state of all pages
      // in the bottom navigation bar alive, even when they are not visible.
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.house),
            activeIcon: Icon(LucideIcons.house),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.history),
            activeIcon: Icon(LucideIcons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.settings),
            activeIcon: Icon(LucideIcons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: draculaCurrentLine,
        selectedItemColor: draculaPink,
        unselectedItemColor: draculaComment,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}