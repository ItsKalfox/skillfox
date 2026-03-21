import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart' as app_auth;
import '../../auth/sign_in_screen.dart';
import '../bookings/customer_booking_history_screen.dart';
import '../profile/manage_account/manage_account_screen.dart';
import '../profile/support/about_screen.dart';
import '../profile/support/help_screen.dart';
import '../profile/favourites/favorites_screen.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
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
          backgroundColor: Color(0xFFF7F8FC),
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
        backgroundColor: const Color(0xFFF7F8FC),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .snapshots(),
          builder: (context, snapshot) {
            final firestoreData = snapshot.data?.data();

            final String name =
                (firestoreData?['name']?.toString().trim().isNotEmpty ?? false)
                ? firestoreData!['name'].toString().trim()
                : (providerUser?['name']?.toString().trim().isNotEmpty ?? false)
                ? providerUser!['name'].toString().trim()
                : (firebaseUser.displayName?.trim().isNotEmpty ?? false)
                ? firebaseUser.displayName!.trim()
                : 'Customer User';

            final String email =
                (firestoreData?['email']?.toString().trim().isNotEmpty ?? false)
                ? firestoreData!['email'].toString().trim()
                : (providerUser?['email']?.toString().trim().isNotEmpty ??
                      false)
                ? providerUser!['email'].toString().trim()
                : (firebaseUser.email?.trim().isNotEmpty ?? false)
                ? firebaseUser.email!.trim()
                : 'No email available';

            final String profilePhotoUrl =
                (firestoreData?['profileImageUrl']?.toString().trim() ?? '')
                    .isNotEmpty
                ? firestoreData!['profileImageUrl'].toString().trim()
                : (providerUser?['profilePhotoUrl'] ?? '').toString();

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
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
                                  color: Color(0xFF222222),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8A8A8A),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFE6EAF7),
                          backgroundImage: profilePhotoUrl.isNotEmpty
                              ? NetworkImage(profilePhotoUrl)
                              : null,
                          child: profilePhotoUrl.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 28,
                                  color: Color(0xFF5B6475),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _ProfileActionCard(
                          icon: Icons.favorite_border_rounded,
                          label: 'Favourites',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CustomerFavoritesScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ProfileActionCard(
                          icon: Icons.receipt_long_rounded,
                          label: 'History',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const CustomerBookingHistoryScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: [
                          _SettingsTile(
                            label: 'Help',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CustomerHelpScreen(),
                                ),
                              );
                            },
                          ),
                          _SettingsTile(
                            label: 'Manage SkillFox account',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ManageAccountScreen(),
                                ),
                              );
                            },
                          ),
                          _SettingsTile(
                            label: 'About',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CustomerAboutScreen(),
                                ),
                              );
                            },
                          ),
                          _SettingsTile(
                            label: 'Log out',
                            labelColor: Colors.red,
                            showArrow: false,
                            onTap: () => _logout(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F1F6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: const Color(0xFF222222)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF222222),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color labelColor;
  final bool showArrow;

  const _SettingsTile({
    required this.label,
    required this.onTap,
    this.labelColor = const Color(0xFF222222),
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w600, color: labelColor),
      ),
      trailing: showArrow
          ? const Icon(Icons.chevron_right_rounded, color: Color(0xFF666666))
          : null,
      onTap: onTap,
    );
  }
}
