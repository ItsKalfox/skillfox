import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skillfox/core/utils/screen_helpers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../widgets/app_text_field.dart';
import 'worker_signup_2_screen.dart';

class WorkerSignup1Screen extends StatefulWidget {
  const WorkerSignup1Screen({super.key});
  @override
  State<WorkerSignup1Screen> createState() => _WorkerSignup1ScreenState();
}

class _WorkerSignup1ScreenState extends State<WorkerSignup1Screen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _idCtrl.dispose();
    super.dispose();
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
                            const SizedBox(height: 8),
                            Text('Welcome to us,',
                              style: GoogleFonts.poppins(
                                fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary,
                              ),
                            ),
                            Text('Hello there, create New Worker account',
                              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.neutral2),
                            ),
                            const SizedBox(height: 24),
                            // Illustration
                            Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/signup-clipart.png',
                                    width: 220,
                                    height: 220,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            AppTextField(placeholder: 'Full Name', controller: _nameCtrl,
                              validator: (v) => Validators.required(v, 'Full Name')),
                            const SizedBox(height: 22),
                            AppTextField(placeholder: 'Phone Number', controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              validator: Validators.phone),
                            const SizedBox(height: 22),
                            AppTextField(placeholder: 'National ID', controller: _idCtrl,
                              validator: (v) => Validators.required(v, 'National ID')),
                            const SizedBox(height: 40),
                            // Arrow button
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  if (_formKey.currentState!.validate()) {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => WorkerSignup2Screen(
                                        name: _nameCtrl.text.trim(),
                                        phone: _phoneCtrl.text.trim(),
                                        nationalId: _idCtrl.text.trim(),
                                      ),
                                    ));
                                  }
                                },
                                child: Container(
                                  width: 70, height: 70,
                                  decoration: const BoxDecoration(
                                    gradient: AppColors.mainGradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 30),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            ScreenHelpers.signInLink(context),
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