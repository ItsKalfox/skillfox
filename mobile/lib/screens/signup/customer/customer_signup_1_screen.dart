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
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();

  bool _nameError  = false;
  bool _phoneError = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(()  { if (_nameError  && _nameCtrl.text.isNotEmpty)  setState(() => _nameError  = false); });
    _phoneCtrl.addListener(() { if (_phoneError && _phoneCtrl.text.isNotEmpty) setState(() => _phoneError = false); });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Widget _errorLabel() => Padding(
    padding: const EdgeInsets.only(top: 5, left: 4),
    child: Row(
      children: [
        const Text('* ', style: TextStyle(
          color: Color(0xFFE53935), fontSize: 14, fontWeight: FontWeight.bold)),
        Text('Required', style: GoogleFonts.poppins(
          fontSize: 11, color: const Color(0xFFE53935))),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const double whiteLayerHeight = 160.0; // <-- change this value

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
                        topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 45, right: 45, top: 28,
                        bottom: bottomPadding + whiteLayerHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text('Welcome to us,',
                            style: GoogleFonts.poppins(
                              fontSize: 22, fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                          Text('Hello there, create New account',
                            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.neutral2)),
                          const SizedBox(height: 24),

                          // Illustration
                          Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 120, height: 120,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary4, shape: BoxShape.circle),
                                ),
                                const Icon(Icons.people, size: 64, color: AppColors.primary),
                                ...ScreenHelpers.buildDots(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Full Name
                          AppTextField(
                            placeholder: 'Full Name',
                            controller: _nameCtrl,
                            validator: (v) => (v == null || v.trim().isEmpty) ? '' : null,
                          ),
                          if (_nameError) _errorLabel(),
                          const SizedBox(height: 14),

                          // Phone Number
                          AppTextField(
                            placeholder: 'Phone Number',
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            validator: (v) => (v == null || v.trim().isEmpty) ? '' : null,
                          ),
                          if (_phoneError) _errorLabel(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // White layer
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: bottomPadding + whiteLayerHeight,
            child: Column(
              children: [
                Container(
                  height: 30, // <-- change this value
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [Colors.white, Colors.white.withOpacity(0.0)])),
                ),
                Expanded(child: Container(color: Colors.white)),
              ],
            ),
          ),

          // bottom-line.png
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Image.asset('assets/images/bottom-line.png', fit: BoxFit.fitWidth),
          ),

          // Arrow button + sign-in link
          Positioned(
            bottom: bottomPadding + 100, left: 28, right: 28,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      final nameEmpty  = _nameCtrl.text.trim().isEmpty;
                      final phoneEmpty = _phoneCtrl.text.trim().isEmpty;
                      if (nameEmpty || phoneEmpty) {
                        setState(() {
                          _nameError  = nameEmpty;
                          _phoneError = phoneEmpty;
                        });
                        return;
                      }
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => CustomerSignup2Screen(
                          name:  _nameCtrl.text.trim(),
                          phone: _phoneCtrl.text.trim(),
                        ),
                      ));
                    },
                    child: Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        gradient: AppColors.mainGradient,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 30),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ScreenHelpers.signInLink(context),
              ],
            ),
          ),
        ],
      ),
    );
  }
}