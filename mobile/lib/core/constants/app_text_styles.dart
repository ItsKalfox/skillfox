import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle title1 = GoogleFonts.poppins(
    fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.primary,
  );
  static TextStyle title2 = GoogleFonts.poppins(
    fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white,
  );
  static TextStyle body1 = GoogleFonts.poppins(
    fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.neutral1,
  );
  static TextStyle body3 = GoogleFonts.poppins(
    fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.neutral1,
  );
  static TextStyle caption1 = GoogleFonts.poppins(
    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDefault,
  );
  static TextStyle caption2 = GoogleFonts.poppins(
    fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.neutral4,
  );
  static TextStyle linkText = GoogleFonts.poppins(
    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary,
  );
}