import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'personal_info_screen.dart';
import 'privacy_data_screen.dart';
import 'security_screen.dart';

class ManageAccountScreen extends StatelessWidget {
  const ManageAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F6FB),
        body: Center(
          child: Text(
            'No user signed in',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4B7DF3)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load account info: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data?.data();

          final String name = (data?['name'] ?? 'Customer User').toString();
          final String email = (data?['email'] ?? 'No email available')
              .toString();
          final String profilePhotoUrl =
              (data?['profilePhotoUrl'] ?? data?['profileImageUrl'] ?? '')
                  .toString();
          final String initials = name.trim().isNotEmpty
              ? name.trim()[0].toUpperCase()
              : '?';

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 52, 16, 80),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF5AA4F6), Color(0xFF3A6BE8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                    ),
                    const Text(
                      'SkillFox Account',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(color: Color(0xFFF4F6FB)),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 62,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF5AA4F6), Color(0xFF3A6BE8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),

                      Positioned.fill(
                        top: 62,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFF4F6FB),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(30),
                            ),
                          ),
                        ),
                      ),

                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
                        child: Column(
                          children: [
                            Transform.translate(
                              offset: const Offset(0, -52),
                              child: Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF4B7DF3,
                                          ).withOpacity(0.20),
                                          blurRadius: 20,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 48,
                                      backgroundColor: const Color(0xFFE6EAF7),
                                      backgroundImage:
                                          profilePhotoUrl.isNotEmpty
                                          ? NetworkImage(profilePhotoUrl)
                                          : null,
                                      child: profilePhotoUrl.isEmpty
                                          ? Text(
                                              initials,
                                              style: const TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF4B7DF3),
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1A1F2E),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.mail_outline_rounded,
                                        size: 13,
                                        color: Color(0xFF9AA3B4),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        email,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF9AA3B4),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 28),

                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: 4,
                                        bottom: 12,
                                      ),
                                      child: Text(
                                        'ACCOUNT OPTIONS',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF9AA3B4),
                                          letterSpacing: 1.4,
                                        ),
                                      ),
                                    ),
                                  ),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: _AccountOptionCard(
                                          icon: Icons.person_outline_rounded,
                                          iconColor: const Color(0xFF4B7DF3),
                                          iconBg: const Color(0xFFEEF2FF),
                                          title: 'Personal Info',
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const CustomerPersonalInfoScreen(),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _AccountOptionCard(
                                          icon: Icons.shield_outlined,
                                          iconColor: const Color(0xFF7C5CFC),
                                          iconBg: const Color(0xFFF0EBFF),
                                          title: 'Security',
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const CustomerSecurityScreen(),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _AccountOptionCard(
                                          icon: Icons.lock_outline_rounded,
                                          iconColor: const Color(0xFF00897B),
                                          iconBg: const Color(0xFFE0F4F1),
                                          title: 'Privacy & Data',
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const CustomerPrivacyDataScreen(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 24),

                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: 4,
                                        bottom: 12,
                                      ),
                                      child: Text(
                                        'ACCOUNT INFO',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF9AA3B4),
                                          letterSpacing: 1.4,
                                        ),
                                      ),
                                    ),
                                  ),

                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFFEAECEF),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        _InfoTile(
                                          icon: Icons.person_outline_rounded,
                                          label: 'Full Name',
                                          value: name,
                                        ),
                                        const Divider(
                                          height: 1,
                                          indent: 58,
                                          endIndent: 16,
                                          color: Color(0xFFF0F2F8),
                                        ),
                                        _InfoTile(
                                          icon: Icons.mail_outline_rounded,
                                          label: 'Email Address',
                                          value: email,
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEEF2FF),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'Verified',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF4B7DF3),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: 4,
                                        bottom: 12,
                                      ),
                                      child: Text(
                                        'PREFERENCES',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF9AA3B4),
                                          letterSpacing: 1.4,
                                        ),
                                      ),
                                    ),
                                  ),

                                  _DistanceLimitSlider(
                                    userId: user.uid,
                                    initialValue: (data?['searchRadius'] as num?)?.toDouble() ?? 30.0,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AccountOptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final VoidCallback onTap;

  const _AccountOptionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 108,
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 21),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: const Color(0xFF9AA3B4)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9AA3B4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1F2E),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _DistanceLimitSlider extends StatefulWidget {
  final String userId;
  final double initialValue;

  const _DistanceLimitSlider({
    required this.userId,
    required this.initialValue,
  });

  @override
  State<_DistanceLimitSlider> createState() => _DistanceLimitSliderState();
}

class _DistanceLimitSliderState extends State<_DistanceLimitSlider> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  void _updateFirestore(double value) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .set({'searchRadius': value}, SetOptions(merge: true));
  }

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.map_outlined,
                  size: 17,
                  color: Color(0xFF9AA3B4),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Search Distance Limit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1F2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Find workers within ${_currentValue.toInt()} km',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9AA3B4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF4B7DF3),
              inactiveTrackColor: const Color(0xFFEEF2FF),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFF4B7DF3).withOpacity(0.1),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: _currentValue,
              min: 0,
              max: 100,
              divisions: 100,
              label: '${_currentValue.toInt()} km',
              onChanged: (value) {
                setState(() {
                  _currentValue = value;
                });
              },
              onChangeEnd: _updateFirestore,
            ),
          ),
        ],
      ),
    );
  }
}
