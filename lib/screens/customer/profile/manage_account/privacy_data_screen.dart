import 'package:flutter/material.dart';

class CustomerPrivacyDataScreen extends StatelessWidget {
  const CustomerPrivacyDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Privacy & Data'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F8FC),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: Column(
          children: const [
            _InfoBlock(
              title: 'How SkillFox uses your data',
              content:
                  'SkillFox uses your account information, booking activity, and location details to help you find nearby workers, manage bookings, and improve your overall experience in the app.',
            ),
            SizedBox(height: 12),
            _InfoBlock(
              title: 'Profile and account data',
              content:
                  'Your profile details such as name, email address, phone number and profile photo are used to personalize your account and make communication easier.',
            ),
            SizedBox(height: 12),
            _InfoBlock(
              title: 'Location data',
              content:
                  'Your location may be used to estimate travel distance, nearby workers, and travel-related fees. This helps SkillFox provide more accurate service results.',
            ),
            SizedBox(height: 12),
            _InfoBlock(
              title: 'Privacy note',
              content:
                  'This screen is currently a frontend placeholder. Your teammate handling backend and policy integration can connect the final privacy logic here later.',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String title;
  final String content;

  const _InfoBlock({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}
