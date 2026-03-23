import 'package:flutter/material.dart';

class WorkerHelpScreen extends StatelessWidget {
  const WorkerHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4B7DF3),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Blue Header ──────────────────────────────
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
                        'Help & Support',
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

            // ── Body ────────────────────────────────────
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
                      // ── Hero banner ────────────────────
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
                                Icons.support_agent_rounded,
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
                                    'How can we help?',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Find answers to the most common questions below.',
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

                      // ── Getting Started ────────────────
                      const _SectionLabel(label: 'GETTING STARTED'),
                      const SizedBox(height: 12),
                      const _HelpGroup(
                        tiles: [
                          _HelpTileData(
                            icon: Icons.person_add_alt_1_rounded,
                            iconColor: Color(0xFF4B7DF3),
                            iconBg: Color(0xFFEEF2FF),
                            title: 'Setting up your worker profile',
                            content:
                                'After registering, go to your Profile tab and complete all required fields including your name, category, profile photo, and location. A complete profile increases your chances of being discovered by customers. Make sure your service category is set correctly so you appear in the right search results.',
                          ),
                          _HelpTileData(
                            icon: Icons.toggle_on_rounded,
                            iconColor: Color(0xFF22C55E),
                            iconBg: Color(0xFFEAFBF0),
                            title: 'Going online and offline',
                            content:
                                'Use the availability toggle on your home screen to set yourself as Active or Offline. When you are Active, customers in your area can find you and send service requests. When Offline, you will not receive any new requests. Remember to go Offline when you are not available to avoid missed requests.',
                          ),
                          _HelpTileData(
                            icon: Icons.location_on_rounded,
                            iconColor: Color(0xFF2E7D32),
                            iconBg: Color(0xFFE8F5E9),
                            title: 'Keeping your location updated',
                            content:
                                'The app automatically updates your location when you open it. Make sure location permissions are granted in your phone settings for the best experience. Customers are shown workers nearby, so an accurate location ensures you appear for the right requests in your area.',
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),

                      // ── Managing Requests ──────────────
                      const _SectionLabel(label: 'MANAGING REQUESTS'),
                      const SizedBox(height: 12),
                      const _HelpGroup(
                        tiles: [
                          _HelpTileData(
                            icon: Icons.notifications_active_rounded,
                            iconColor: Color(0xFF4B7DF3),
                            iconBg: Color(0xFFEEF2FF),
                            title: 'Receiving service requests',
                            content:
                                'When a customer sends you a request, it will appear on your home screen under Nearby Requests. You will also receive a notification. Tap the request card to view the customer details, their location on a map, and the service they need before deciding to accept or decline.',
                          ),
                          _HelpTileData(
                            icon: Icons.check_circle_outline_rounded,
                            iconColor: Color(0xFF22C55E),
                            iconBg: Color(0xFFEAFBF0),
                            title: 'Accepting a request',
                            content:
                                'Open the request card and tap Accept. Once accepted, the customer will be notified and the job will appear in your active bookings. Make sure you are ready to travel to the customer location before accepting. Accepting and then not showing up may affect your rating.',
                          ),
                          _HelpTileData(
                            icon: Icons.cancel_outlined,
                            iconColor: Color(0xFFE53935),
                            iconBg: Color(0xFFFFEBEB),
                            title: 'Declining a request',
                            content:
                                'If you are unable to take a job, tap Decline on the request card. The request will be removed from your list. Declining occasionally is normal, but declining too frequently may reduce how often your profile appears to customers in your area.',
                          ),
                          _HelpTileData(
                            icon: Icons.history_rounded,
                            iconColor: Color(0xFFF9A825),
                            iconBg: Color(0xFFFFFDE7),
                            title: 'Viewing your job history',
                            content:
                                'Go to the Profile tab and tap History to see all your completed, accepted, and declined jobs. Each entry shows the customer name, service type, date, and outcome. You can tap any entry to view its full details.',
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),

                      // ── Earnings & Fees ────────────────
                      const _SectionLabel(label: 'EARNINGS AND FEES'),
                      const SizedBox(height: 12),
                      const _HelpGroup(
                        tiles: [
                          _HelpTileData(
                            icon: Icons.directions_car_outlined,
                            iconColor: Color(0xFF4B7DF3),
                            iconBg: Color(0xFFEEF2FF),
                            title: 'How travel fees work',
                            content:
                                'The travel fee is charged to the customer to cover your travel cost to their location. It is calculated based on the distance between you and the customer. You can set whether you offer free travel or charge a fee from your profile settings. Offering free travel may attract more bookings.',
                          ),
                          _HelpTileData(
                            icon: Icons.search_outlined,
                            iconColor: Color(0xFF7C5CFC),
                            iconBg: Color(0xFFF0EBFF),
                            title: 'What is an inspection fee',
                            content:
                                'An inspection fee can be set for jobs that require you to assess the situation before quoting a full service cost. For example, diagnosing an electrical fault before carrying out the repair. You can configure this in your profile under pricing settings.',
                          ),
                          _HelpTileData(
                            icon: Icons.local_offer_rounded,
                            iconColor: Color(0xFF2E7D32),
                            iconBg: Color(0xFFE8F5E9),
                            title: 'Running offers and promotions',
                            content:
                                'You can create limited-time offers from your profile to attract more customers. Offers such as free travel or reduced fees are shown to customers on the home screen under Today\'s Offers. Offers can be enabled or disabled at any time from your profile settings.',
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),

                      // ── Your Account ───────────────────
                      const _SectionLabel(label: 'YOUR ACCOUNT'),
                      const SizedBox(height: 12),
                      const _HelpGroup(
                        tiles: [
                          _HelpTileData(
                            icon: Icons.person_outline_rounded,
                            iconColor: Color(0xFF4B7DF3),
                            iconBg: Color(0xFFEEF2FF),
                            title: 'Updating your personal info',
                            content:
                                'Go to Profile, tap Manage Account, then Personal Info. You can update your name, phone number, profile photo, and cover photo. Your service category can also be updated here. Keep your profile accurate and professional to build trust with customers.',
                          ),
                          _HelpTileData(
                            icon: Icons.lock_outline_rounded,
                            iconColor: Color(0xFF7C5CFC),
                            iconBg: Color(0xFFF0EBFF),
                            title: 'Changing your password',
                            content:
                                'Go to Profile, tap Manage Account, then Security. Enter your current password followed by your new password. Your new password must be at least 6 characters long. If you have forgotten your password, you can reset it from the sign-in screen.',
                          ),
                          _HelpTileData(
                            icon: Icons.star_outline_rounded,
                            iconColor: Color(0xFFF9A825),
                            iconBg: Color(0xFFFFFDE7),
                            title: 'Understanding your rating',
                            content:
                                'Your rating is calculated from reviews left by customers after completed jobs. It is shown on your profile and on search results. A higher rating increases your visibility and makes customers more likely to choose you. Always aim to provide a punctual, professional, and friendly service.',
                          ),
                          _HelpTileData(
                            icon: Icons.verified_user_outlined,
                            iconColor: Color(0xFF00897B),
                            iconBg: Color(0xFFE0F4F1),
                            title: 'Account verification',
                            content:
                                'To become a verified worker on the platform, you may be asked to submit supporting documents such as a national ID, professional certification, or trade licence depending on your service category. Verified workers receive a badge on their profile which increases customer trust.',
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),

                      // ── Contact card ───────────────────
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
                              'Still need help?',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1F2E),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'If you could not find the answer you were looking for, our support team is happy to assist you.',
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
                              label: 'Email Support',
                              value: 'workers@skillfox.lk',
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

// ═══════════════════════════════════════════════
//  Data model for help tile
// ═══════════════════════════════════════════════
class _HelpTileData {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String content;

  const _HelpTileData({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.content,
  });
}

// ═══════════════════════════════════════════════
//  Section Label
// ═══════════════════════════════════════════════
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

// ═══════════════════════════════════════════════
//  Help Group (card container with expand tiles)
// ═══════════════════════════════════════════════
class _HelpGroup extends StatelessWidget {
  final List<_HelpTileData> tiles;
  const _HelpGroup({required this.tiles});

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
              _HelpTile(data: entry.value),
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

// ═══════════════════════════════════════════════
//  Expandable Help Tile
// ═══════════════════════════════════════════════
class _HelpTile extends StatefulWidget {
  final _HelpTileData data;
  const _HelpTile({required this.data});

  @override
  State<_HelpTile> createState() => _HelpTileState();
}

class _HelpTileState extends State<_HelpTile>
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
    if (_expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
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

// ═══════════════════════════════════════════════
//  Contact Row
// ═══════════════════════════════════════════════
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
