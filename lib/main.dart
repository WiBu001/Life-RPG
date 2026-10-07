import 'package:flutter/material.dart';
import 'ui/home_screen.dart';

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
      home: const HomeScreen(),
    );
  }
}