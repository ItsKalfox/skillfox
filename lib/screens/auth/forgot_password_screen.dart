import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../services/otp_service.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/app_text_field.dart';
import 'otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final otp = await OtpService().sendOtp(_emailCtrl.text.trim());
    setState(() => _loading = false);
    if (!mounted) return;
    if (otp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email not found in our records.')),
      );
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => OtpScreen(email: _emailCtrl.text.trim()),
      ));
    }
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
                      padding: const EdgeInsets.only(top: 24, left: 40, right: 40),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                  Text('Enter your email',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12, fontWeight: FontWeight.w600,
                                      color: AppColors.textDefault,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  AppTextField(
                                    placeholder: 'email@example.com',
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: Validators.email,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'We email you a code to verify your email',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14, color: AppColors.neutral1,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  GradientButton(
                                    text: 'Send',
                                    onPressed: _send,
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