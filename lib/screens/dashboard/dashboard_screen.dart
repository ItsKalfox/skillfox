import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../auth/sign_in_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../category_a/worker_requests_screen.dart';
import '../category_a/customer_request_screen.dart';
import '../customer/dashboard/customer_dashboard_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  bool isLoading = false;

  Future<void> _logout(BuildContext context) async {
    await context.read<app_auth.AuthProvider>().signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (_) => false,
    );
  }

  Future<void> _handleNavigation() async {
  setState(() => isLoading = true);

  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    setState(() => isLoading = false);
    return;
  }

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (!mounted) return;

  final role = doc.data()?['role'];

  // ✅ STOP LOADING BEFORE NAVIGATION
  setState(() => isLoading = false);

 if (role == 'customer') {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const CustomerDashboardScreen(),
    ),
  );
} else {
  Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => const WorkerRequestsScreen(),
  ),
);
}
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.mainGradient,
            ),
          ),

          SafeArea(
            child: Column(
              children: [

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Dashboard',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFFDFF),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),

                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        Text(
                          'Welcome to SkillFox! 🦊',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // 🚀 NAVIGATION BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleNavigation,
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Go Next"),
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => _logout(context),
                            icon: const Icon(Icons.logout),
                            label: const Text("Log Out"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}