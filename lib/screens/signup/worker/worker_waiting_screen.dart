import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../dashboard/dashboard_screen.dart';

class WorkerWaitingScreen extends StatefulWidget {
  const WorkerWaitingScreen({super.key});
  @override
  State<WorkerWaitingScreen> createState() => _WorkerWaitingScreenState();
}

class _WorkerWaitingScreenState extends State<WorkerWaitingScreen> {
  @override
  void initState() {
    super.initState();
    _listenForApproval();
  }

  void _listenForApproval() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    FirebaseFirestore.instance.collection('users').doc(uid)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      if (snap.data()?['status'] == 'approved') {
        Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (_) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppColors.mainGradient)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {},
                      child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30), topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Illustration
                          Container(
                            width: 200, height: 200,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF0F0F6), shape: BoxShape.circle,
                            ),
                            child: const Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(Icons.phone_android, size: 80, color: Color(0xFF5655B9)),
                                Positioned(
                                  bottom: 40, right: 40,
                                  child: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.white,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(0xFF3629B7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text('Your Approval is in Progress',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "We're reviewing your profile. You'll be notified once a decision is made.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.neutral2),
                          ),
                          const SizedBox(height: 36),
                          // Progress tracker: Submit → Review → Approve
                          _ProgressTracker(currentStep: 1),
                        ],
                      ),
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

class _ProgressTracker extends StatelessWidget {
  final int currentStep; // 0=Submit, 1=Review, 2=Approve
  const _ProgressTracker({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = ['Submit', 'Review', 'Approve'];
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Line between dots
          final lineIndex = i ~/ 2;
          final isCompleted = lineIndex < currentStep;
          return Expanded(
            child: Container(
              height: 3,
              color: isCompleted ? AppColors.primary : const Color(0xFFE0E0E0),
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final isCompleted = stepIndex <= currentStep;
        return Column(
          children: [
            Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.primary : const Color(0xFFE0E0E0),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 6),
            Text(steps[stepIndex],
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isCompleted ? AppColors.primary : AppColors.neutral4,
                fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        );
      }),
    );
  }
}