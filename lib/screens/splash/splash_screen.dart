import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../landing/landing_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../signup/worker/worker_waiting_screen.dart';
import '../customer/dashboard/customer_dashboard_screen.dart';
import '../../services/address_service.dart';

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

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      _goTo(const LandingScreen());
      return;
    }

    final data = doc.data() ?? {};
    final role = (data['role'] ?? '').toString().toLowerCase().trim();
    final status = (data['status'] ?? '').toString().toLowerCase().trim();

    if (role == 'worker') {
      if (status == 'pending') {
        _goTo(const WorkerWaitingScreen());
      } else {
        _goTo(const DashboardScreen());
      }
      return;
    }

    if (role == 'customer') {
      final addressService = AddressService();
      await addressService.ensureDefaultAddressFromUserProfile();
      _goTo(const CustomerDashboardScreen());
      return;
    }

    _goTo(const LandingScreen());
  }

  void _goTo(Widget screen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
