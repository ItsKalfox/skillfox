import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../dashboard/dashboard_screen.dart';

class CustomerSignupCompleteScreen extends StatefulWidget {
  const CustomerSignupCompleteScreen({super.key});
  @override
  State<CustomerSignupCompleteScreen> createState() => _CustomerSignupCompleteScreenState();
}

class _CustomerSignupCompleteScreenState extends State<CustomerSignupCompleteScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-redirect to dashboard after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (_) => false,
      );
    });
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
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    ),
                  ),
                ),
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
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Illustration
                          Container(
                            width: 200, height: 200,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF0F0F6), shape: BoxShape.circle,
                            ),
                            child: const Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(Icons.phone_android, size: 80, color: Color(0xFF5655B9)),
                                Positioned(
                                  bottom: 40, right: 40,
                                  child: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Color(0xFF3629B7),
                                    child: Icon(Icons.check, color: Colors.white, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text('Account Created Successfully',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Welcome! Your account is now ready. You'll be redirected to your dashboard shortly.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.neutral2),
                          ),
                          const SizedBox(height: 24),
                          // Countdown indicator
                          const CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 3,
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