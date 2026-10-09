import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import '../widgets/app_bottom_navigation.dart';
import 'assistant_screen.dart';
import 'dashboard_screen.dart';
import 'goals_screen.dart';
import 'transactions_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(controller: widget.controller),
      const TransactionsScreen(),
      GoalsScreen(controller: widget.controller),
      AssistantScreen(controller: widget.controller),
    ];
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onChanged: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
