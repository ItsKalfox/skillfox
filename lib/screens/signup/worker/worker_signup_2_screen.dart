import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skillfox/core/utils/screen_helpers.dart';
import '../../../core/constants/app_colors.dart';
import 'worker_signup_3_screen.dart';

class WorkJob {
  final String title, description, emoji;
  const WorkJob({required this.title, required this.description, required this.emoji});
}

const List<WorkJob> workJobs = [
  WorkJob(title: 'Mechanic', description: 'Repair and maintain vehicles', emoji: '🔧'),
  WorkJob(title: 'Teacher', description: 'Educate and guide students', emoji: '📚'),
  WorkJob(title: 'Plumber', description: 'Fix and install water and drainage systems', emoji: '🪣'),
  WorkJob(title: 'Electrician', description: 'Install and repair electrical and wiring systems', emoji: '⚡'),
  WorkJob(title: 'Cleaner', description: 'Perform thorough cleaning and tidying', emoji: '🧹'),
  WorkJob(title: 'Caregiver', description: 'Assist individuals with daily living and personal care', emoji: '🩺'),
  WorkJob(title: 'Mason', description: 'Build and repair structures with stone, brick or concrete', emoji: '🏗️'),
  WorkJob(title: 'Handyman', description: 'Handle small repairs, maintenance and odd jobs', emoji: '🛠️'),
  WorkJob(title: 'Painter', description: 'Paint walls, ceilings and surfaces', emoji: '🎨'),
  WorkJob(title: 'Gardener', description: 'Maintain lawns, gardens and outdoor spaces', emoji: '🌿'),
  WorkJob(title: 'Driver', description: 'Transport people or goods safely', emoji: '🚗'),
  WorkJob(title: 'IT Support', description: 'Solve technical and computer issues', emoji: '💻'),
];

class WorkerSignup2Screen extends StatefulWidget {
  final String name, phone, nationalId;
  const WorkerSignup2Screen({super.key, required this.name, required this.phone, required this.nationalId});
  @override
  State<WorkerSignup2Screen> createState() => _WorkerSignup2ScreenState();
}

class _WorkerSignup2ScreenState extends State<WorkerSignup2Screen> {
  String? _selected;

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Select Work Type',
                                style: GoogleFonts.poppins(
                                  fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary,
                                ),
                              ),
                              Text('Choose the type of service you provide to get started!',
                                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.neutral2),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            itemCount: workJobs.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
                            itemBuilder: (_, i) {
                              final job = workJobs[i];
                              final selected = _selected == job.title;
                              return GestureDetector(
                                onTap: () => setState(() => _selected = job.title),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.primary
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(job.title,
                                              style: GoogleFonts.poppins(
                                                fontSize: 15, fontWeight: FontWeight.w600,
                                                color: selected ? Colors.white : AppColors.neutral1,
                                              ),
                                            ),
                                            Text(job.description,
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: selected ? Colors.white70 : AppColors.neutral2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(job.emoji, style: const TextStyle(fontSize: 28)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(28, 12, 28, 12),
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: _selected == null ? null : () {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => WorkerSignup3Screen(
                                        name: widget.name, phone: widget.phone,
                                        nationalId: widget.nationalId, jobType: _selected!,
                                      ),
                                    ));
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 56, height: 56,
                                    decoration: BoxDecoration(
                                      gradient: _selected != null ? AppColors.mainGradient : null,
                                      color: _selected == null ? AppColors.primary4 : null,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.arrow_forward,
                                      color: _selected != null ? Colors.white : AppColors.neutral4,
                                      size: 24,
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