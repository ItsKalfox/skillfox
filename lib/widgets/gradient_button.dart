import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !isLoading;
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.mainGradient : null,
          color: enabled ? null : AppColors.neutral4,
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white,
                ),
              ),
      ),
    );
  }
}