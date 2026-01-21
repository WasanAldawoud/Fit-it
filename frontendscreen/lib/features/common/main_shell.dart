import 'package:flutter/material.dart';
import '../home_page/home_page.dart';
import '../my_plans/my_plans_screen.dart';
import '../common/app_nav_bar.dart';
import '../profile/profile_screen.dart'; // Import is already here
import '../Ai_chat/chat_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // UPDATED: Added ProfileScreen() to the list
    final pages = <Widget>[
      const HomePage(),          // Index 0
      const MyPlansScreen(),     // Index 1
      const ChatScreen(),        // Index 2
      const ProfileScreen(),     // Index 3 (Matches 'Profile' in AppNavBar)
    ];

    return Scaffold(
      // Using IndexedStack is better as it preserves the state of your 
      // pages (like the timer on the HomePage) when switching tabs.
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: AppNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}


