import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/gradient_button.dart';
import 'sign_in_screen.dart';

class PasswordSuccessScreen extends StatelessWidget {
  const PasswordSuccessScreen({super.key});

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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    children: [
                      const SizedBox(width: 24),
                      Expanded(
                        child: Text('',
                          style: GoogleFonts.poppins(fontSize: 20, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFFDFF),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30), topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24, left: 40, right: 40, bottom: 120),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [

                          // ✅ Replaced ✅ emoji with password-change-clipart.png
                          Image.asset(
                            'assets/images/password-change-clipart.png',
                            width: 320,
                            height: 320,
                            fit: BoxFit.contain,
                          ),

                          const SizedBox(height: 0),
                          Text('Change password successfully!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'You have successfully changed your password.\nPlease use the new password when signing in.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14, color: AppColors.neutral1),
                          ),
                          const SizedBox(height: 40),
                          GradientButton(
                            text: 'Ok',
                            onPressed: () => Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const SignInScreen()),
                              (_) => false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Image.asset(
              'assets/images/bottom-line.png',
              fit: BoxFit.fitWidth,
            ),
          ),
        ],
      ),
    );
  }
}