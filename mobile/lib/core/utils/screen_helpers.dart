import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class ScreenHelpers {
  static Widget navBar(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          ),
          Expanded(
            child: Text(title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  static Widget signInLink(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Have an account? ',
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.neutral2)),
          GestureDetector(
            onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
            child: Text('Sign In',
              style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<Widget> buildDots() {
    return [
      Positioned(top: 8, right: 8,
        child: Container(width: 10, height: 10,
          decoration: const BoxDecoration(color: Color(0xFFFF4267), shape: BoxShape.circle))),
      Positioned(top: 30, left: 0,
        child: Container(width: 8, height: 8,
          decoration: const BoxDecoration(color: Color(0xFF52D5BA), shape: BoxShape.circle))),
      Positioned(bottom: 20, left: 10,
        child: Container(width: 14, height: 14,
          decoration: const BoxDecoration(color: Color(0xFFFFAF2A), shape: BoxShape.circle))),
      Positioned(bottom: 10, right: 10,
        child: Container(width: 8, height: 8,
          decoration: const BoxDecoration(color: Color(0xFF0890FE), shape: BoxShape.circle))),
      Positioned(top: 10, left: 10,
        child: Container(width: 8, height: 8,
          decoration: const BoxDecoration(color: Color(0xFF3629B7), shape: BoxShape.circle))),
    ];
  }
}