import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routes/app_router.dart';
import 'progress_screen.dart';
import 'quiz_list_screen.dart';
import 'user_home_screen.dart';

class UserNavShell extends StatefulWidget {
  const UserNavShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<UserNavShell> createState() => _UserNavShellState();
}

class _UserNavShellState extends State<UserNavShell> {
  late int _selectedIndex;

  static const _pages = <Widget>[
    UserHomeScreen(),
    QuizListScreen(),
    ProgressScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, _pages.length - 1);
  }

  void _onDestinationSelected(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        context.go(AppRoutes.userHome);
        break;
      case 1:
        context.go(AppRoutes.quizList);
        break;
      case 2:
        context.go(AppRoutes.userProgress);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      extendBody: true, // lets nav hug the bottom over translucent backgrounds
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
          height: AppSpacing.bottomNavHeight,
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onDestinationSelected,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: 'Quizzes',
            ),
            NavigationDestination(
              icon: Icon(Icons.trending_up_outlined),
              selectedIcon: Icon(Icons.trending_up),
              label: 'Progress',
            ),
          ],
        ),
      ),
    );
  }
}
