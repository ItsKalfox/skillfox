import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Customer Home Screen',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
