import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillfox/screens/community/community_feed_screen.dart';

class WorkerCommunityScreen extends StatefulWidget {
  const WorkerCommunityScreen({super.key});

  @override
  State<WorkerCommunityScreen> createState() => WorkerCommunityScreenState();
}

// Public State so DashboardScreen can access uid/username/category
// via GlobalKey<WorkerCommunityScreenState>.
class WorkerCommunityScreenState extends State<WorkerCommunityScreen> {
  String? _uid;
  String? _username;
  String? _category;
  bool _loading = true;

  // Exposed for the outer Scaffold's FAB
  String? get uid => _uid;
  String? get username => _username;
  String? get category => _category;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data() ?? {};
    final name = (data['name'] ?? '').toString().trim();
    final category = (data['category'] ?? '').toString().trim();

    setState(() {
      _uid = user.uid;
      _username = name.isNotEmpty ? name : 'Worker';
      _category = category.isNotEmpty ? category : 'General';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in.')),
      );
    }

    return CommunityFeedScreen(
      currentUserId: _uid!,
      currentUsername: _username!,
      isWorker: true,
      userCategory: _category,
    );
  }
}
