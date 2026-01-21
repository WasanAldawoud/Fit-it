import 'package:flutter/material.dart';
import '../home_page/home_page.dart';
import '../my_plans/my_plans_screen.dart';
import '../common/app_nav_bar.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomePage(),
      const MyPlansScreen(),
      const AiChatPlaceholder(),
      const Profile(),

    ];
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: AppNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}


/// this is JUST a placeholder for the ai chat screen  
class AiChatPlaceholder extends StatelessWidget {
  const AiChatPlaceholder();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(' AI Chat\n\nHI WASAN', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}
class Profile extends StatelessWidget {
  const Profile();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(' Profile\n\nHI MARIYA', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}
