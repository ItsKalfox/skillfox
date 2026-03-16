import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../auth/sign_in_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Logo / Illustration area
              Positioned(
                top: 150,
                left: 0, right: 0,
                child: Center(
                  child: Transform.rotate(
                    angle: 45 * pi / 180,
                    child: Container(
                      width: 200, height: 200,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFFF2F2F7),                    // top-left: white
                            Color(0xFFC5D6FF),               // light lavender
                            Color(0xFFA7A7FF),               // medium lavender
                            Color(0xFF7C7CFF),               // light purple
                          ],
                          stops: [0.0, 0.35, 0.65, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Transform.rotate(
                          angle: -45 * pi / 180,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 30), // ← adjust this value
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 130,
                              height: 130,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom content
              Positioned(
                bottom: 40, left: 24, right: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'SkillFox ',
                            style: GoogleFonts.poppins(
                              fontSize: 24, color: const Color(0xFFE4B7FF),
                            ),
                          ),
                          TextSpan(
                            text: 'Find Your Trusted Pro',
                            style: GoogleFonts.poppins(
                              fontSize: 24, color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Discover trusted experts in your area whether it\'s home services, repairs, or personal care. SkillFox helps you find the right pro, fast.',
                      style: GoogleFonts.poppins(
                        fontSize: 14, color: const Color(0xFFD1D1D6),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignInScreen()),
                        ),
                        child: Container(
                          width: 60, height: 60,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: Color(0xFF3629B7),
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}