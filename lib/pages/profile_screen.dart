import 'package:flutter/material.dart';
import 'package:skillfox/pages/upload_post_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), 
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(15), 
              border: Border.all(color: Colors.grey.shade200)
            ),
            child: Row(
              children: const [
                CircleAvatar(radius: 35, backgroundColor: Color(0xFF4A90E2), child: Icon(Icons.person, size: 40, color: Colors.white)),
                SizedBox(width: 20),
                Text('User Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            child: ListTile(
              leading: const Icon(Icons.upload_file, color: Color(0xFF4A90E2)),
              title: const Text('Upload new post', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const UploadPostScreen(currentUserId: 'test', username: 'Test', category: 'General'))
              ),
            ),
          ),
        ],
      ),
    );
  }
}