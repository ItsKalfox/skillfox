import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/screen_helpers.dart';
import '../../../widgets/app_text_field.dart';
import 'customer_signup_2_screen.dart';

class CustomerSignup1Screen extends StatefulWidget {
  const CustomerSignup1Screen({super.key});
  @override
  State<CustomerSignup1Screen> createState() => _CustomerSignup1ScreenState();
}

class _CustomerSignup1ScreenState extends State<CustomerSignup1Screen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      padding: const EdgeInsets.all(28),
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
                            Text('Hello there, create New account',
                              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.neutral2),
                            ),
                            const SizedBox(height: 24),
                            // Illustration
                            Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 120, height: 120,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary4, shape: BoxShape.circle,
                                    ),
                                  ),
                                  const Icon(Icons.people, size: 64, color: AppColors.primary),
                                  ...ScreenHelpers.buildDots(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            AppTextField(placeholder: 'Full Name', controller: _nameCtrl,
                              validator: (v) => Validators.required(v, 'Full Name')),
                            const SizedBox(height: 14),
                            AppTextField(placeholder: 'Phone Number', controller: _phoneCtrl,
                              keyboardType: TextInputType.phone, validator: Validators.phone),
                            const SizedBox(height: 32),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  if (_formKey.currentState!.validate()) {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => CustomerSignup2Screen(
                                        name: _nameCtrl.text.trim(),
                                        phone: _phoneCtrl.text.trim(),
                                      ),
                                    ));
                                  }
                                },
                                child: Container(
                                  width: 56, height: 56,
                                  decoration: const BoxDecoration(
                                    gradient: AppColors.mainGradient, shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 24),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
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
        ],
      ),
    );
  }
}