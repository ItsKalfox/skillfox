import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart' as app_auth;
import '../../auth/sign_in_screen.dart';
import '../bookings/worker_booking_history_screen.dart';
import '../profile/manage_account/manage_account_screen.dart';
import '../profile/support/about_screen.dart';
import '../profile/support/help_screen.dart';
import '../profile/earnings/earnings.dart';
import '../profile/offers/worker_offer_screen.dart';

class WorkerProfileScreen extends StatelessWidget {
  const WorkerProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log out?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to log out of your account?',
          style: TextStyle(color: Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF666666)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Log out',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    await context.read<app_auth.AuthProvider>().signOut();

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final providerUser = context.watch<app_auth.AuthProvider>().userData;
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      return const SafeArea(
        child: Scaffold(
          backgroundColor: Color(0xFFF4F6FB),
          body: Center(
            child: Text(
              'No user signed in',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FB),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data();

            final String name =
                (data?['name']?.toString().trim().isNotEmpty ?? false)
                ? data!['name'].toString().trim()
                : (providerUser?['name']?.toString().trim().isNotEmpty ?? false)
                ? providerUser!['name'].toString().trim()
                : (firebaseUser.displayName?.trim().isNotEmpty ?? false)
                ? firebaseUser.displayName!.trim()
                : 'Customer User';

            final String email =
                (data?['email']?.toString().trim().isNotEmpty ?? false)
                ? data!['email'].toString().trim()
                : (providerUser?['email']?.toString().trim().isNotEmpty ??
                      false)
                ? providerUser!['email'].toString().trim()
                : (firebaseUser.email?.trim().isNotEmpty ?? false)
                ? firebaseUser.email!.trim()
                : 'No email available';

            final String photoUrl =
                (data?['profileImageUrl']?.toString().trim() ?? '').isNotEmpty
                ? data!['profileImageUrl'].toString().trim()
                : (providerUser?['profilePhotoUrl'] ?? '').toString();

            final String coverPhotoUrl =
                (data?['coverPhotoUrl']?.toString().trim() ?? '');

            // First letter for avatar fallback
            final String initials = name.isNotEmpty
                ? name.trim()[0].toUpperCase()
                : '?';

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title ──────────────────────────────
                  const Text(
                    'My Profile',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1F2E),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _ProfileHeroCard(
                    name: name,
                    email: email,
                    photoUrl: photoUrl,
                    initials: initials,
                  ),
                  const SizedBox(height: 16),

                  // ── Quick Actions ──────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.attach_money_rounded,
                          iconColor: const Color(0xFF22C55E),
                          iconBg: const Color(0xFFEAFBF0),
                          label: 'Earnings',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Earnings()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Settings Section ───────────────────
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'SETTINGS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9AA3B4),
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),

                  _SettingsGroup(
                    tiles: [
                      _SettingsTileData(
                        icon: Icons.help_outline_rounded,
                        iconColor: const Color(0xFF4B7DF3),
                        iconBg: const Color(0xFFEEF2FF),
                        label: 'Help & Support',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkerHelpScreen(),
                          ),
                        ),
                      ),
                      _SettingsTileData(
                        icon: Icons.local_offer_outlined,
                        iconColor: const Color(0xFFF59E0B),
                        iconBg: const Color(0xFFFEF3C7),
                        label: 'Special Offers',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkerOfferScreen(),
                          ),
                        ),
                      ),
                      _SettingsTileData(
                        icon: Icons.manage_accounts_outlined,
                        iconColor: const Color(0xFF7C5CFC),
                        iconBg: const Color(0xFFF0EBFF),
                        label: 'Manage Account',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManageAccountScreen(),
                          ),
                        ),
                      ),
                      _SettingsTileData(
                        icon: Icons.info_outline_rounded,
                        iconColor: const Color(0xFF00897B),
                        iconBg: const Color(0xFFE0F4F1),
                        label: 'About SkillFox',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkerAboutScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Logout ─────────────────────────────
                  _LogoutButton(onTap: () => _logout(context)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Profile Hero Card
// ═══════════════════════════════════════════════
class _ProfileHeroCard extends StatelessWidget {
  final String name;
  final String email;
  final String photoUrl;
  final String initials;

  const _ProfileHeroCard({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5AA4F6), Color(0xFF3A6BE8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4B7DF3).withOpacity(0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 2.5,
              ),
            ),
            child: CircleAvatar(
              radius: 34,
              backgroundColor: Colors.white.withOpacity(0.25),
              backgroundImage: photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: photoUrl.isEmpty
                  ? Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),

          // Name + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withOpacity(0.78),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Verified badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1,
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_rounded, color: Colors.white, size: 13),
                SizedBox(width: 4),
                Text(
                  'Verified',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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

// ═══════════════════════════════════════════════
//  Quick Action Card
// ═══════════════════════════════════════════════
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEAECEF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1F2E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Settings Group
// ═══════════════════════════════════════════════
class _SettingsTileData {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final VoidCallback onTap;

  const _SettingsTileData({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.onTap,
  });
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsTileData> tiles;

  const _SettingsGroup({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: tiles.asMap().entries.map((entry) {
          final idx = entry.key;
          final tile = entry.value;
          final isLast = idx == tiles.length - 1;

          return Column(
            children: [
              _SettingsRow(tile: tile),
              if (!isLast)
                const Divider(
                  height: 1,
                  indent: 62,
                  endIndent: 16,
                  color: Color(0xFFF0F2F8),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final _SettingsTileData tile;

  const _SettingsRow({required this.tile});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: tile.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tile.iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(tile.icon, color: tile.iconColor, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                tile.label,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1F2E),
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFFBCC4D4),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Logout Button
// ═══════════════════════════════════════════════
class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFE0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFE53935), size: 19),
            SizedBox(width: 10),
            Text(
              'Log Out',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE53935),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
