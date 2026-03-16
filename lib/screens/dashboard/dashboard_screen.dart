import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
                  padding: const EdgeInsets.all(24),
                  child: Text('Dashboard',
                    style: GoogleFonts.poppins(
                      fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFFDFF),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30), topRight: Radius.circular(30),
                      ),
                    ),
                    child: Center(
                      child: Text('Welcome to SkillFox! 🦊',
                        style: GoogleFonts.poppins(fontSize: 18, color: AppColors.primary)),
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