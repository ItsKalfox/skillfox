import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

class AppTextField extends StatefulWidget {
  final String placeholder;
  final bool obscure;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final String? label;
  final void Function(String)? onChanged;

  const AppTextField({
    super.key,
    required this.placeholder,
    this.obscure = false,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.label,
    this.onChanged,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Text(widget.label!,
            style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: AppColors.textDefault,
            ),
          ),
        if (widget.label != null) const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.obscure && !_showPassword,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: widget.onChanged,
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.neutral1),
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: GoogleFonts.poppins(fontSize: 14, color: AppColors.neutral4),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.red),
            ),
            suffixIcon: widget.obscure
                ? IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.neutral4,
                    ),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}