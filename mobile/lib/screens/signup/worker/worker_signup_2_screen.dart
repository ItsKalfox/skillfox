import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skillfox/core/utils/screen_helpers.dart';
import '../../../core/constants/app_colors.dart';
import 'worker_signup_3_screen.dart';

class WorkJob {
  final String title, description, imagePath;
  const WorkJob({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

const List<WorkJob> workJobs = [
  WorkJob(title: 'Mechanic',    description: 'Repair and maintain vehicles',                           imagePath: 'assets/images/mechanic.png'),
  WorkJob(title: 'Teacher',     description: 'Educate and guide students',                             imagePath: 'assets/images/teacher.png'),
  WorkJob(title: 'Plumber',     description: 'Fix and install water and drainage systems',             imagePath: 'assets/images/plumber.png'),
  WorkJob(title: 'Electrician', description: 'Install and repair electrical and wiring systems',       imagePath: 'assets/images/electrician.png'),
  WorkJob(title: 'Cleaner',     description: 'Perform thorough cleaning and tidying',                  imagePath: 'assets/images/cleaner.png'),
  WorkJob(title: 'Caregiver',   description: 'Assist individuals with daily living and personal care', imagePath: 'assets/images/caregiver.png'),
  WorkJob(title: 'Mason',       description: 'Build and repair structures with stone, brick or concrete', imagePath: 'assets/images/mason.png'),
  WorkJob(title: 'Handyman',    description: 'Handle small repairs, maintenance and odd jobs',         imagePath: 'assets/images/handyman.png'),
];

class WorkerSignup2Screen extends StatefulWidget {
  final String name, phone, nationalId;
  const WorkerSignup2Screen({
    super.key,
    required this.name,
    required this.phone,
    required this.nationalId,
  });
  @override
  State<WorkerSignup2Screen> createState() => _WorkerSignup2ScreenState();
}

class _WorkerSignup2ScreenState extends State<WorkerSignup2Screen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // ── ADJUST THIS: total height of the white layer (button + sign-in + spacing) ──
    const double whiteLayerHeight = 160; // <-- change this value

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background gradient
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
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(40, 28, 40, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Select Work Type',
                                style: GoogleFonts.poppins(
                                  fontSize: 22, fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text('Choose the type of service you provide to get started!',
                                style: GoogleFonts.poppins(
                                  fontSize: 12, color: AppColors.neutral2),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),

                        // Scrollable job cards
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.fromLTRB(
                              40, 0, 40, bottomPadding + whiteLayerHeight),
                            itemCount: workJobs.length,
                            itemBuilder: (_, i) {
                              final job = workJobs[i];
                              final selected = _selected == job.title;
                              return GestureDetector(
                                onTap: () => setState(() => _selected = job.title),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.only(bottom: 18),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 16),
                                  decoration: BoxDecoration(
                                    gradient: selected ? AppColors.mainGradient : null,
                                    color: selected ? null : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(
                                          selected ? 0.25 : 0.07),
                                        blurRadius: selected ? 16 : 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(job.title,
                                              style: GoogleFonts.poppins(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: selected ? Colors.white : AppColors.neutral1,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(job.description,
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: selected ? Colors.white70 : AppColors.neutral2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Image.asset(
                                        job.imagePath,
                                        width: 60, height: 60,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 60, height: 60,
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? Colors.white.withOpacity(0.2)
                                                : AppColors.primary4,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── White layer — sits above the list, below the button ──
          // ── ADJUST whiteLayerHeight at the top to resize this ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: bottomPadding + whiteLayerHeight,
            child: Column(
              children: [
                // Fade edge at the top of the white layer
                // ── ADJUST this height to make the fade taller or shorter ──
                Container(
                  height: 30, // <-- change this value
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.white,
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
                Expanded(child: Container(color: Colors.white)),
              ],
            ),
          ),

          // ── bottom-line.png on top of white layer ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Image.asset(
              'assets/images/bottom-line.png',
              fit: BoxFit.fitWidth,
            ),
          ),

          // ── Arrow button + sign-in link on top of everything ──
          Positioned(
            bottom: bottomPadding + 100,
            left: 28, right: 28,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _selected == null ? null : () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => WorkerSignup3Screen(
                          name: widget.name,
                          phone: widget.phone,
                          nationalId: widget.nationalId,
                          jobType: _selected!,
                        ),
                      ));
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        gradient: _selected != null ? AppColors.mainGradient : null,
                        color: _selected == null ? AppColors.primary4 : null,
                        shape: BoxShape.circle,
                        boxShadow: _selected != null
                            ? [BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              )]
                            : null,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: _selected != null ? Colors.white : AppColors.neutral4,
                        size: 30,
                      ),
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