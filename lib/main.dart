
import 'package:flutter/material.dart';

import 'UI/home_screen.dart';
import 'UI/main_quest_screen.dart';
import 'UI/calendar_screen.dart';

void main() {
  runApp(const LifeRPG());
}

class LifeRPG extends StatelessWidget {
  const LifeRPG({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Life RPG',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    body: selectedIndex == 0
        ? const HomeScreen()
        : selectedIndex == 1
            ? const MainQuestScreen()
            : const CalendarScreen(),

    bottomNavigationBar: BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) {
        setState(() {
          selectedIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.flag),
          label: 'Quests',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month),
          label: 'Calendar',
        ),
      ],
    ),
    );
  }
}
