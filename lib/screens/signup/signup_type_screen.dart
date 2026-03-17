import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import 'worker/worker_signup_1_screen.dart';
import 'customer/customer_signup_1_screen.dart';

class SignupTypeScreen extends StatefulWidget {
  const SignupTypeScreen({super.key});
  @override
  State<SignupTypeScreen> createState() => _SignupTypeScreenState();
}

class _SignupTypeScreenState extends State<SignupTypeScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // ✅ Layer 1 — gradient background
          Container(decoration: const BoxDecoration(gradient: AppColors.mainGradient)),

          // ✅ Layer 2 — main content
          SafeArea(
            child: Column(
              children: [
                // Nav bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                      ),
                      Expanded(
                        child: Text('Sign up',
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
                // White card
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30), topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(40, 28, 40, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text('Welcome to us,',
                            style: GoogleFonts.poppins(
                              fontSize: 24, fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text('Hello there, create New account',
                            style: GoogleFonts.poppins(
                              fontSize: 13, color: AppColors.neutral2),
                          ),
                          const SizedBox(height: 140),
                          // Worker / Customer selector
                          IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _TypeOption(
                                    // ✅ PNG image instead of icon
                                    imagePath: 'assets/images/worker-icon.png',
                                    label: 'Worker',
                                    selected: _selected == 'worker',
                                    onTap: () => setState(() => _selected = 'worker'),
                                  ),
                                ),
                                SizedBox(width: 20),
                                // Divider
                                Container(
                                  width: 1,
                                  color: AppColors.borderColor,
                                  margin: const EdgeInsets.symmetric(vertical: 0),
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: _TypeOption(
                                    // ✅ PNG image instead of icon
                                    imagePath: 'assets/images/customer-icon.png',
                                    label: 'Customer',
                                    selected: _selected == 'customer',
                                    onTap: () => setState(() => _selected = 'customer'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Have an account
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Have an account? ',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13, color: AppColors.neutral2)),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Text('Sign In',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13, fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 120), // ✅ space above bottom line
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ✅ Layer 3 — bottom line above white card but below arrow button
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Image.asset(
              'assets/images/bottom-line.png',
              fit: BoxFit.fitWidth,
            ),
          ),

          // ✅ Layer 4 — arrow button on very top of everything
          Positioned(
            bottom: 200,
            right: 28,
            child: GestureDetector(
              onTap: _selected == null ? null : () {
                if (_selected == 'worker') {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const WorkerSignup1Screen(),
                  ));
                } else {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const CustomerSignup1Screen(),
                  ));
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 70, height: 70,
                decoration: BoxDecoration(
                  gradient: _selected != null ? AppColors.mainGradient : null,
                  color: _selected == null ? AppColors.primary4 : null,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: _selected != null ? Colors.white : AppColors.neutral4,
                  size: 30,
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final String imagePath; // ✅ changed from IconData to String
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.imagePath,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 160, height: 160,
            decoration: BoxDecoration(
              color: AppColors.primary4,
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: AppColors.primary, width: 2.5)
                  : null,
            ),
            // ✅ PNG image inside the circle
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text(label,
            style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}