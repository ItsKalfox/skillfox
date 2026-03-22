import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillfox/screens/community/community_feed_screen.dart';

class CustomerCommunityFeedScreen extends StatefulWidget {
  const CustomerCommunityFeedScreen({super.key});

  @override
  State<CustomerCommunityFeedScreen> createState() =>
      _CustomerCommunityFeedScreenState();
}

class _CustomerCommunityFeedScreenState
    extends State<CustomerCommunityFeedScreen> {
  String? _uid;
  String? _username;
  bool _loading = true;

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

    final name = (doc.data()?['name'] ?? '').toString().trim();

    setState(() {
      _uid = user.uid;
      _username = name.isNotEmpty ? name : 'Customer';
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
      isWorker: false,
    );
  }
}
