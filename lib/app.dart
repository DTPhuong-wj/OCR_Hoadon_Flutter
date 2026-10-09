import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/analytics/analytics_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/expense_history/history_screen.dart';
import 'features/settings/settings_screen.dart';
import 'widgets/custom_bottom_nav.dart';

class ReceiptTrackerApp extends StatelessWidget {
  const ReceiptTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Receipt OCR & Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigationScaffold(),
    );
  }
}

class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(onNavigateTab: _onTabTapped),
      const HistoryScreen(),
      const AnalyticsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
