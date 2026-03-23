import 'package:flutter/material.dart';

class CustomerPrivacyDataScreen extends StatelessWidget {
  const CustomerPrivacyDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4B7DF3),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
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
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Privacy & Data',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F6FB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5AA4F6), Color(0xFF3A6BE8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4B7DF3).withOpacity(0.28),
                              blurRadius: 18,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.35),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.lock_outline_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your privacy matters',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Learn how SkillFox collects, uses, and protects your personal data.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.white70,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      const _SectionLabel(label: 'DATA WE COLLECT'),
                      const SizedBox(height: 12),
                      const _PrivacyGroup(
                        tiles: [
                          _PrivacyTileData(
                            icon: Icons.person_outline_rounded,
                            iconColor: Color(0xFF4B7DF3),
                            iconBg: Color(0xFFEEF2FF),
                            title: 'Account and profile data',
                            content:
                                'When you create an account, we collect your name, email address, phone number, and profile photo. This information is used to personalise your experience, identify your account securely, and allow workers to recognise who they are serving.',
                          ),
                          _PrivacyTileData(
                            icon: Icons.location_on_outlined,
                            iconColor: Color(0xFF2E7D32),
                            iconBg: Color(0xFFE8F5E9),
                            title: 'Location data',
                            content:
                                'SkillFox uses your device location or your saved addresses to show you nearby workers and calculate accurate travel distances and fees. Location is only accessed when you are actively using the app. We do not track your location in the background.',
                          ),
                          _PrivacyTileData(
                            icon: Icons.receipt_long_outlined,
                            iconColor: Color(0xFF7C5CFC),
                            iconBg: Color(0xFFF0EBFF),
                            title: 'Booking and activity data',
                            content:
                                'We store records of your bookings, viewed worker profiles, applied filters, and favourited workers. This data helps us improve recommendations, resolve disputes, and provide an accurate booking history in your account.',
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),

                      const _SectionLabel(label: 'HOW WE USE YOUR DATA'),
                      const SizedBox(height: 12),
                      const _PrivacyGroup(
                        tiles: [
                          _PrivacyTileData(
                            icon: Icons.home_repair_service_rounded,
                            iconColor: Color(0xFF4B7DF3),
                            iconBg: Color(0xFFEEF2FF),
                            title: 'Providing our service',
                            content:
                                'Your data is primarily used to connect you with skilled workers in your area, process bookings, calculate fees, and deliver notifications about your service requests. Without this data, the core functionality of SkillFox would not be possible.',
                          ),
                          _PrivacyTileData(
                            icon: Icons.star_outline_rounded,
                            iconColor: Color(0xFFF9A825),
                            iconBg: Color(0xFFFFFDE7),
                            title: 'Improving your experience',
                            content:
                                'We use aggregated usage data to understand how people interact with the app, which features are most useful, and where improvements can be made. This analysis is done at a group level and is not used to make decisions about individual users.',
                          ),
                          _PrivacyTileData(
                            icon: Icons.notifications_outlined,
                            iconColor: Color(0xFF00897B),
                            iconBg: Color(0xFFE0F4F1),
                            title: 'Sending you updates',
                            content:
                                'We may send you notifications related to your bookings, account activity, or important platform updates. You can manage your notification preferences from your device settings at any time.',
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),

                      const _SectionLabel(label: 'DATA PROTECTION'),
                      const SizedBox(height: 12),
                      const _PrivacyGroup(
                        tiles: [
                          _PrivacyTileData(
                            icon: Icons.shield_outlined,
                            iconColor: Color(0xFF4B7DF3),
                            iconBg: Color(0xFFEEF2FF),
                            title: 'How we protect your data',
                            content:
                                'All personal data stored on SkillFox is encrypted at rest and in transit. We use secure authentication methods and follow industry best practices for data storage. Access to user data is restricted to authorised team members only.',
                          ),
                          _PrivacyTileData(
                            icon: Icons.share_outlined,
                            iconColor: Color(0xFFE53935),
                            iconBg: Color(0xFFFFEBEB),
                            title: 'Sharing your data',
                            content:
                                'SkillFox does not sell your personal data to third parties. Your information may be shared with the workers you book a service from, limited to what is necessary to complete the service.',
                          ),
                          _PrivacyTileData(
                            icon: Icons.delete_outline_rounded,
                            iconColor: Color(0xFF7C5CFC),
                            iconBg: Color(0xFFF0EBFF),
                            title: 'Deleting your data',
                            content:
                                'You have the right to request deletion of your personal data at any time. To delete your account and all associated data, go to Profile, tap "Manage Account", then select the account deletion option. Once deleted, your data cannot be recovered.',
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),

                      const _SectionLabel(label: 'YOUR RIGHTS'),
                      const SizedBox(height: 12),
                      const _PrivacyGroup(
                        tiles: [
                          _PrivacyTileData(
                            icon: Icons.visibility_outlined,
                            iconColor: Color(0xFF4B7DF3),
                            iconBg: Color(0xFFEEF2FF),
                            title: 'Accessing your data',
                            content:
                                'You can view and update most of your personal information directly from the app under Profile and Manage Account. If you need a full copy of all data we hold about you, you can contact our support team.',
                          ),
                          _PrivacyTileData(
                            icon: Icons.edit_outlined,
                            iconColor: Color(0xFF00897B),
                            iconBg: Color(0xFFE0F4F1),
                            title: 'Correcting your data',
                            content:
                                'If any of your personal information is inaccurate or out of date, you can update it at any time from your account settings. For data that cannot be changed directly in the app, please contact our support team and we will assist you.',
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEAECEF)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Privacy concerns?',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1F2E),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'If you have any questions about how your data is used or wish to exercise your rights, please reach out to us.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: Color(0xFF9AA3B4),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _ContactRow(
                              icon: Icons.mail_outline_rounded,
                              iconColor: const Color(0xFF4B7DF3),
                              iconBg: const Color(0xFFEEF2FF),
                              label: 'Privacy Team',
                              value: 'privacy@skillfox.lk',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _PrivacyTileData {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String content;

  const _PrivacyTileData({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.content,
  });
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF9AA3B4),
        letterSpacing: 1.4,
      ),
    );
  }
}

class _PrivacyGroup extends StatelessWidget {
  final List<_PrivacyTileData> tiles;
  const _PrivacyGroup({required this.tiles});

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
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: tiles.asMap().entries.map((entry) {
          final isLast = entry.key == tiles.length - 1;
          return Column(
            children: [
              _PrivacyTile(data: entry.value),
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

class _PrivacyTile extends StatefulWidget {
  final _PrivacyTileData data;
  const _PrivacyTile({required this.data});

  @override
  State<_PrivacyTile> createState() => _PrivacyTileState();
}

class _PrivacyTileState extends State<_PrivacyTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggle,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.data.iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.data.icon,
                    color: widget.data.iconColor,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    widget.data.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _expanded
                          ? const Color(0xFF4B7DF3)
                          : const Color(0xFF1A1F2E),
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: _expanded
                        ? const Color(0xFF4B7DF3)
                        : const Color(0xFFBCC4D4),
                  ),
                ),
              ],
            ),
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, left: 51),
                child: Text(
                  widget.data.content,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  const _ContactRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 19),
        ),
        const SizedBox(width: 13),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9AA3B4),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1F2E),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
