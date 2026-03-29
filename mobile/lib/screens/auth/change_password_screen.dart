import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/gradient_button.dart';
import 'password_success_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String email;
  const ChangePasswordScreen({super.key, required this.email});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  bool _loading = false;
  bool _sent = false;

  Future<void> _sendResetLink() async {
    setState(() => _loading = true);
    try {
      // Send Firebase's official password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.email);

      // Clean up the OTP request since we've completed the verification
      await FirebaseFirestore.instance
          .collection('otp_requests')
          .doc(widget.email)
          .delete();

      setState(() => _sent = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send reset link. Try again.')),
      );
    }
    setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    // Automatically send the reset link when this screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendResetLink());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      ),
                      Expanded(
                        child: Text('Change password',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 20, fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24, left: 40, right: 40),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3629B7).withOpacity(0.07),
                                  blurRadius: 30, offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Icon
                                Container(
                                  width: 72, height: 72,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.mainGradient,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.mark_email_read_rounded,
                                    color: Colors.white, size: 36,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                if (_loading && !_sent) ...[
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 16),
                                  Text('Sending reset link...',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14, color: AppColors.neutral2)),
                                ] else if (_sent) ...[
                                  Text('Reset link sent!',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18, fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(children: [
                                      TextSpan(
                                        text: 'We\'ve sent a password reset link to ',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14, color: AppColors.neutral1,
                                          height: 1.5,
                                        ),
                                      ),
                                      TextSpan(
                                        text: widget.email,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14, fontWeight: FontWeight.w600,
                                          color: AppColors.primary2,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '. Open the link in the email to set your new password.',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14, color: AppColors.neutral1,
                                          height: 1.5,
                                        ),
                                      ),
                                    ]),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Check your spam folder if you don\'t see it.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12, color: AppColors.neutral2),
                                  ),
                                  const SizedBox(height: 24),
                                  GradientButton(
                                    text: 'Back to Sign In',
                                    onPressed: () => Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const PasswordSuccessScreen()),
                                      (_) => false,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: _loading ? null : _sendResetLink,
                                    child: Text('Resend link',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14, fontWeight: FontWeight.w500,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
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