import 'package:flutter/material.dart';

class CustomerAboutScreen extends StatelessWidget {
  const CustomerAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('About SkillFox'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F8FC),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEAECEF)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SkillFox',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF222222),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'SkillFox is a worker-finding mobile application designed to help customers discover nearby workers, compare options, and request services more conveniently.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: Color(0xFF666666),
                ),
              ),
              SizedBox(height: 14),
              Text(
                'This screen is currently a frontend placeholder and can be updated later with your final project description, team credits, version details, and contact information.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
