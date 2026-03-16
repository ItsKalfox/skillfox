import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../services/otp_service.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/app_text_field.dart';
import 'change_password_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _verify() async {
    if (_otpCtrl.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 4-digit OTP')),
      );
      return;
    }
    setState(() => _loading = true);
    final valid = await OtpService().verifyOtp(widget.email, _otpCtrl.text.trim());
    setState(() => _loading = false);
    if (!mounted) return;
    if (valid) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChangePasswordScreen(email: widget.email),
      ));
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Invalid OTP'),
          content: const Text('The OTP you entered is incorrect or has expired.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  Future<void> _resend() async {
    final otp = await OtpService().sendOtp(widget.email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(otp != null ? 'OTP resent!' : 'Failed to resend OTP')),
    );
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      ),
                      Expanded(
                        child: Text('Forgot password',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white,
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
                        topLeft: Radius.circular(30), topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Type the code',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12, fontWeight: FontWeight.w600,
                                    color: AppColors.textDefault,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppTextField(
                                        placeholder: '----',
                                        controller: _otpCtrl,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: _resend,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          gradient: AppColors.mainGradient,
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: Text('Resend',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14, color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                RichText(
                                  text: TextSpan(children: [
                                    TextSpan(
                                      text: 'We email you a code to verify your email ',
                                      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.neutral2),
                                    ),
                                    TextSpan(
                                      text: widget.email,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14, fontWeight: FontWeight.w600,
                                        color: AppColors.primary2,
                                      ),
                                    ),
                                  ]),
                                ),
                                const SizedBox(height: 4),
                                Text('This code will expire 10 minutes after this message.',
                                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.neutral2),
                                ),
                                const SizedBox(height: 16),
                                GradientButton(
                                  text: 'Change password',
                                  onPressed: _verify,
                                  isLoading: _loading,
                                ),
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
        ],
      ),
    );
  }
}