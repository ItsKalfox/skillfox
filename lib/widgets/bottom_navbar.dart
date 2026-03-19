import 'package:flutter/material.dart';
import 'package:skillfox/pages/profile_screen.dart';
import 'package:skillfox/pages/community_feed_screen.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8A2BE2), Color(0xFF4A90E2)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.white), 
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CommunityFeedScreen(currentUserId: 'test',currentUsername: 'Test User', isWorker: true)))
            ),
            IconButton(icon: const Icon(Icons.explore, color: Colors.white), onPressed: () {}),
            Expanded(
              child: Container(
                height: 35,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                  ),
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.bookmark, color: Colors.white), onPressed: () {}),
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white), 
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))
            ),
          ],
        ),
      ),
    );
  }
}