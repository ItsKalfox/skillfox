import 'package:flutter/material.dart';
import 'screens/splash/splash_screen.dart';

class SkillFoxApp extends StatelessWidget {
  const SkillFoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillFox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3629B7)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}