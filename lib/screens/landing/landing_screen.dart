import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../auth/sign_in_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 70),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: Stack(
            children: [

              // ✅ Bottom line image — pinned to very bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Image.asset(
                  'assets/images/bottom-line.png',
                  fit: BoxFit.fitWidth,
                ),
              ),

              // Orbiting bubbles + logo box
              Positioned(
                top: 150,
                left: 0, right: 0,
                child: Center(
                  child: SizedBox(
                    width: 320,
                    height: 320,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [

                        // Logo box FIRST — renders behind everything
                        Transform.rotate(
                          angle: 45 * pi / 180,
                          child: Container(
                            width: 200, height: 200,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Color(0xFFF2F2F7),
                                  Color(0xFFC5D6FF),
                                  Color(0xFFA7A7FF),
                                  Color(0xFF7C7CFF),
                                ],
                                stops: [0.0, 0.35, 0.65, 1.0],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Transform.rotate(
                                angle: -45 * pi / 180,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 30),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    width: 130,
                                    height: 130,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Bubbles LAST — renders in front of logo box
                        _OrbitingBubble(
                          controller: _controller,
                          orbitRadius: 200,
                          bubbleSize: 200,
                          angleOffset: 0,
                          svgPath: 'assets/images/bubble1.svg',
                          selfRotationMultiplier: 0.5,
                        ),
                        _OrbitingBubble(
                          controller: _controller,
                          orbitRadius: 200,
                          bubbleSize: 200,
                          angleOffset: pi,
                          svgPath: 'assets/images/bubble2.svg',
                          selfRotationMultiplier: -0.5,
                        ),

                      ],
                    ),
                  ),
                ),
              ),

              // Bottom content
              Positioned(
                bottom: 0, left: 24, right: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'SkillFox ',
                            style: GoogleFonts.poppins(
                              fontSize: 24, color: const Color(0xFFE4B7FF),
                            ),
                          ),
                          TextSpan(
                            text: 'Find Your Trusted Pro',
                            style: GoogleFonts.poppins(
                              fontSize: 24, color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Discover trusted experts in your area whether it\'s home services, repairs, or personal care. SkillFox helps you find the right pro, fast.',
                      style: GoogleFonts.poppins(
                        fontSize: 14, color: const Color(0xFFD1D1D6),
                      ),
                    ),
                    const SizedBox(height: 70),
                    Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SignInScreen()),
                          ),
                          child: Container(
                            width: 60, height: 60,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: Color(0xFF3629B7),
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25), // ✅ space above bottom line
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

class _OrbitingBubble extends AnimatedWidget {
  final double orbitRadius;
  final double bubbleSize;
  final double angleOffset;
  final String svgPath;
  final double selfRotationMultiplier;

  const _OrbitingBubble({
    required AnimationController controller,
    required this.orbitRadius,
    required this.bubbleSize,
    required this.angleOffset,
    required this.svgPath,
    required this.selfRotationMultiplier,
  }) : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = listenable as Animation<double>;
    final double angle = animation.value * 2 * pi + angleOffset;

    final double x = orbitRadius * cos(angle);
    final double y = orbitRadius * sin(angle);

    final double selfAngle = animation.value * 2 * pi * selfRotationMultiplier;

    return Transform.translate(
      offset: Offset(x, y),
      child: Transform.rotate(
        angle: selfAngle,
        child: SvgPicture.asset(
          svgPath,
          width: bubbleSize,
          height: bubbleSize,
        ),
      ),
    );
  }
}