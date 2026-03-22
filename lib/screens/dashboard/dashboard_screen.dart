import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../auth/sign_in_screen.dart';
import '../community/upload_post_screen.dart';
import '../worker/home/worker_home_screen.dart';
import '../worker/profile/worker_profile_screen.dart';
import 'worker_community_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // GlobalKey lets us read worker data (uid, username, category) from the
  // WorkerCommunityScreen state so the outer Scaffold's FAB can open
  // UploadPostScreen with the correct parameters.
  final GlobalKey<WorkerCommunityScreenState> _communityKey =
      GlobalKey<WorkerCommunityScreenState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const WorkerHomeScreen(),
          WorkerCommunityScreen(key: _communityKey),
          const _WorkerBookingsTab(),
          const WorkerProfileScreen(),
        ],
      ),
      // FAB lives here on the OUTER Scaffold so it renders correctly above
      // the bottom nav bar (avoids the nested-Scaffold + extendBody issue).
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              elevation: 4,
              backgroundColor: const Color(0xFF4365FF),
              child: const Icon(Icons.add_a_photo_rounded,
                  color: Colors.white, size: 26),
              onPressed: () {
                final state = _communityKey.currentState;
                if (state == null || state.uid == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UploadPostScreen(
                      currentUserId: state.uid!,
                      username: state.username ?? 'Worker',
                      category: state.category ?? 'General',
                    ),
                  ),
                );
              },
            )
          : null,
      bottomNavigationBar: _WorkerBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

// ==========================================
// WORKER BOTTOM NAV BAR (matches customer style)
// ==========================================
class _WorkerBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _WorkerBottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEFEAFF), Color(0xFF8B79FF), Color(0xFF6C59F8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavCircleButton(
                icon: Icons.home_filled,
                active: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavCircleButton(
                icon: Icons.chat_bubble_outline_rounded,
                active: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavCircleButton(
                icon: Icons.calendar_month_outlined,
                active: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavCircleButton(
                icon: Icons.person_outline_rounded,
                active: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavCircleButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _NavCircleButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 22,
          color: active ? Colors.black : const Color(0xFF8F8F8F),
        ),
      ),
    );
  }
}


// ==========================================
// HOME TAB (replaced by WorkerHomeScreen)
// ==========================================
// ==========================================
// PLACEHOLDER TABS
// ==========================================
class _WorkerBookingsTab extends StatelessWidget {
  const _WorkerBookingsTab();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Bookings\n(Coming Soon)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

