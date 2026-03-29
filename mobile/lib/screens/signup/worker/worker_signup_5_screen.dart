import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillfox/core/utils/screen_helpers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../services/otp_service.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/gradient_button.dart';
import 'worker_signup_complete_screen.dart';

class WorkerSignup5Screen extends StatefulWidget {
  final String name, phone, nationalId, jobType;
  final String nicFrontUrl, nicBackUrl, profilePhotoUrl, address;
  final List<String> certificationUrls;
  final double lat, lng;

  const WorkerSignup5Screen({
    super.key, required this.name, required this.phone,
    required this.nationalId, required this.jobType,
    required this.nicFrontUrl, required this.nicBackUrl,
    required this.profilePhotoUrl, required this.certificationUrls,
    required this.address, required this.lat, required this.lng,
  });

  @override
  State<WorkerSignup5Screen> createState() => _WorkerSignup5ScreenState();
}

class _WorkerSignup5ScreenState extends State<WorkerSignup5Screen> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _otpSent = false, _otpVerified = false;
  bool _termsAccepted = false, _loading = false;

  bool get _canSignup =>
      _otpVerified && _termsAccepted &&
      _passCtrl.text.isNotEmpty && _confirmCtrl.text == _passCtrl.text;

  Future<void> _sendOtp() async {
    if (Validators.email(_emailCtrl.text.trim()) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email first')));
      return;
    }
    final otp = await OtpService().sendSignupOtp(
      _emailCtrl.text.trim(),
      purpose: 'Worker Sign Up',
    );
    if (!mounted) return;
    if (otp != null) {
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent to your email!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send OTP. Try again.')));
    }
  }

  Future<void> _verifyOtp() async {
    final valid = await OtpService().verifyOtp(_emailCtrl.text.trim(), _otpCtrl.text.trim());
    if (!mounted) return;
    if (valid) {
      setState(() => _otpVerified = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Email verified!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid or expired OTP')));
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    final passError = Validators.password(_passCtrl.text);
    if (passError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(passError)));
      return;
    }
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(), password: _passCtrl.text,
      );
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'role': 'worker',
        'status': 'pending',
        'name': widget.name,
        'phone': widget.phone,
        'nationalId': widget.nationalId,
        'jobType': widget.jobType,
        'nicFrontUrl': widget.nicFrontUrl,
        'nicBackUrl': widget.nicBackUrl,
        'profilePhotoUrl': widget.profilePhotoUrl,
        'certificationUrls': widget.certificationUrls,
        'address': widget.address,
        'location': GeoPoint(widget.lat, widget.lng),
        'email': _emailCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const WorkerSignupCompleteScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: ${e.toString()}')));
    }
    setState(() => _loading = false);
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
                ScreenHelpers.navBar(context, 'Sign up'),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30), topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(left: 45, right: 45, top: 28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Complete account setup',
                              style: GoogleFonts.poppins(
                                fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Email + OTP section
                            Text('Email and Verify',
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500,
                                color: AppColors.neutral1),
                            ),
                            const SizedBox(height: 8),
                            AppTextField(
                              placeholder: 'Email', controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.email,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    placeholder: 'OTP', controller: _otpCtrl,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: _otpVerified ? null : (_otpSent ? _verifyOtp : _sendOtp),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    decoration: BoxDecoration(
                                      gradient: _otpVerified ? null : AppColors.mainGradient,
                                      color: _otpVerified ? Colors.green : null,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Text(
                                      _otpVerified ? 'Verified ✓' : (_otpSent ? 'Verify' : 'Send OTP'),
                                      style: GoogleFonts.poppins(
                                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(color: Color(0xFFF0F0F0)),
                            const SizedBox(height: 12),
                            // Password section
                            Text('Setup Password',
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500,
                                color: AppColors.neutral1),
                            ),
                            const SizedBox(height: 8),
                            AppTextField(
                              placeholder: 'Setup Password', obscure: true,
                              controller: _passCtrl,
                              validator: Validators.password,
                            ),
                            const SizedBox(height: 10),
                            AppTextField(
                              placeholder: 'Confirm Password', obscure: true,
                              controller: _confirmCtrl,
                              validator: (v) {
                                if (v != _passCtrl.text) return 'Passwords do not match';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            // Terms checkbox
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Transform.scale(
                                  scale: 0.9,
                                  child: Checkbox(
                                    value: _termsAccepted,
                                    activeColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (v) => setState(() {
                                      _termsAccepted = v!;
                                    }),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: RichText(
                                      text: TextSpan(children: [
                                        TextSpan(
                                          text: 'By creating an account your agree to our ',
                                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.neutral1),
                                        ),
                                        TextSpan(
                                          text: 'Term and Conditions',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12, color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ]),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            GradientButton(
                              text: 'Sign up',
                              onPressed: _canSignup ? _signup : null,
                              isLoading: _loading,
                            ),
                            const SizedBox(height: 16),
                            Center(
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