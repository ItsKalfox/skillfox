import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../landing/landing_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../signup/worker/worker_waiting_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _goTo(const LandingScreen());
      return;
    }
    // Check user status
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!doc.exists) { _goTo(const LandingScreen()); return; }

    final status = doc.data()?['status'] ?? '';
    if (status == 'pending') {
      _goTo(const WorkerWaitingScreen());
    } else {
      _goTo(const DashboardScreen());
    }
  }

  void _goTo(Widget screen) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}