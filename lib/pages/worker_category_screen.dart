import 'package:flutter/material.dart';

class WorkerCategoryScreen extends StatelessWidget {
  const WorkerCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF5AB2FF), 
            Color(0xFF4365FF), 
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, 
        appBar: AppBar(
          backgroundColor: Colors.transparent, 
          elevation: 0,
          title: const Text('Explore', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            child: ListView(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 32.0, bottom: 40.0),
              children: [
                // HEADER TEXT
                const Text(
                  'Select Work Type',
                  style: TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.w900, 
                    color: Color(0xFF2D3A54), 
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a service category to explore content!',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 32),

                // CATEGORY CARDS 
                _buildCategoryCard(context, 'Mechanic', 'Repair and maintain vehicles', Icons.car_repair),
                _buildCategoryCard(context, 'Teacher', 'Educate and guide students', Icons.school),
                _buildCategoryCard(context, 'Plumber', 'Fix and install water and drainage systems', Icons.plumbing),
                _buildCategoryCard(context, 'Electrician', 'Install and repair electrical and wiring systems', Icons.electrical_services),
                _buildCategoryCard(context, 'Cleaner', 'Perform thorough cleaning and tidying', Icons.cleaning_services),
                _buildCategoryCard(context, 'Caregiver', 'Assist individuals with daily living', Icons.directions_walk),
                _buildCategoryCard(context, 'Mason', 'Bricklaying and concrete work', Icons.architecture),
                _buildCategoryCard(context, 'Handyman', 'General home repairs and maintenance', Icons.build),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // REUSABLE CARD WIDGET
  Widget _buildCategoryCard(BuildContext context, String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5), 
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(context, title);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title, 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle, 
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14)
                      ),
                    ],
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F5FA), 
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: const Color(0xFF4A90E2), size: 28),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}