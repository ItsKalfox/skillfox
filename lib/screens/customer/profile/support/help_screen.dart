import 'package:flutter/material.dart';

class CustomerHelpScreen extends StatelessWidget {
  const CustomerHelpScreen({super.key});

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

                      // ── Getting started ────────────────
                      const _SectionLabel(label: 'GETTING STARTED'),
                      const SizedBox(height: 12),
                      const _HelpGroup(
                        tiles: [
                          _HelpTileData(
                            icon: Icons.search_rounded,
                            iconColor: Color(0xFF4B7DF3),
                            iconBg: Color(0xFFEEF2FF),
                            title: 'How to find a worker',
                            content:
                                'Open the home screen and browse through the service categories at the top. You can tap on a category to filter workers by skill type. Use the filter chips to narrow results by offers, travel time, or rating. Tap on any worker card to view their full profile and details.',
                          ),
                          _HelpTileData(
                            icon: Icons.tune_rounded,
                            iconColor: Color(0xFF7C5CFC),
                            iconBg: Color(0xFFF0EBFF),
                            title: 'Using filters and categories',
                            content:
                                'Tap a category icon on the home screen to show only workers in that field. The filter chips let you further refine results. "Offers" shows workers with active promotions. "Under 30 min" shows workers who can reach you quickly. "Highest rated" shows only top-rated professionals above 4.8 stars.',
                          ),
                          _HelpTileData(
                            icon: Icons.location_on_rounded,
                            iconColor: Color(0xFF2E7D32),
                            iconBg: Color(0xFFE8F5E9),
                            title: 'Setting your location',
                            content:
                                'Tap the location label at the top of the home screen to open your addresses. You can use your live device location or select a saved address. Workers shown on the home screen are sorted and priced based on your chosen location, so keeping it accurate ensures the best results.',
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),

                      // ── Bookings ───────────────────────
                      const _SectionLabel(label: 'BOOKINGS'),
                      const SizedBox(height: 12),
                      const _HelpGroup(
                        tiles: [
                          _HelpTileData(
                            icon: Icons.calendar_today_rounded,
                            iconColor: Color(0xFF00897B),
                            iconBg: Color(0xFFE0F4F1),
                            title: 'How booking works',
                            content:
                                'Open a worker profile and tap "Book Now". Fill in the details about your service request and submit. The worker will be notified and can accept or decline. Once accepted, you will receive a confirmation and can track the status from your booking history.',
                          ),
                          _HelpTileData(
                            icon: Icons.history_rounded,
                            iconColor: Color(0xFFF9A825),
                            iconBg: Color(0xFFFFFDE7),
                            title: 'Viewing your booking history',
                            content:
                                'Go to the Profile tab and tap "History" to see all your past and upcoming bookings. Each entry shows the worker name, service type, date, and current status. You can tap any booking to view more details.',
                          ),
                          _HelpTileData(
                            icon: Icons.cancel_outlined,
                            iconColor: Color(0xFFE53935),
                            iconBg: Color(0xFFFFEBEB),
                            title: 'Cancelling a booking',
                            content:
                                'You can cancel a booking from your booking history before the worker has started travelling to your location. Open the booking and tap the cancel option. Please note that cancelling frequently may affect your standing on the platform.',
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),

                      // ── Fees and payments ──────────────
                      const _SectionLabel(label: 'FEES AND PAYMENTS'),
                      const SizedBox(height: 12),
                      const _HelpGroup(
                        tiles: [
                          _HelpTileData(
                            icon: Icons.directions_car_outlined,
                            iconColor: Color(0xFF4B7DF3),
                            iconBg: Color(0xFFEEF2FF),
                            title: 'What is a travel fee',
                            content:
                                'The travel fee covers the cost for the worker to travel to your location. It is calculated based on the distance between you and the worker, local traffic conditions, and availability in your area. Workers with active "Free Travel" offers will show a travel fee of LKR 0.',
                          ),
                          _HelpTileData(
                            icon: Icons.search_outlined,
                            iconColor: Color(0xFF7C5CFC),
                            iconBg: Color(0xFFF0EBFF),
                            title: 'What is an inspection fee',
                            content:
                                'Some services require the worker to assess the situation before starting work. For example, a plumber may need to inspect a pipe issue before quoting a repair cost. The inspection fee covers this initial visit and varies depending on the type of service.',
                          ),
                          _HelpTileData(
                            icon: Icons.local_offer_rounded,
                            iconColor: Color(0xFF2E7D32),
                            iconBg: Color(0xFFE8F5E9),
                            title: 'How offers and discounts work',
                            content:
                                'Some workers run limited-time offers visible on the home screen under "Today\'s Offers". These may include free travel, reduced fees, or promotional rates. Offers are set by the worker directly and may change at any time. Always check the worker profile for the latest pricing.',
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),

                      // ── Account ────────────────────────
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
                                'Go to Profile, tap "Manage Account", then "Personal Info". You can update your name, phone number, and profile photo from this screen. Your email address is linked to your account and cannot be changed.',
                          ),
                          _HelpTileData(
                            icon: Icons.lock_outline_rounded,
                            iconColor: Color(0xFF7C5CFC),
                            iconBg: Color(0xFFF0EBFF),
                            title: 'Changing your password',
                            content:
                                'Go to Profile, tap "Manage Account", then "Security". Enter your current password followed by your new password. Your new password must be at least 6 characters long. If you have forgotten your password, you can reset it from the sign-in screen.',
                          ),
                          _HelpTileData(
                            icon: Icons.favorite_outline_rounded,
                            iconColor: Color(0xFFE53935),
                            iconBg: Color(0xFFFFEBEB),
                            title: 'Managing your favourites',
                            content:
                                'Tap the heart icon on any worker card or profile to save them to your favourites. Access your saved workers anytime from Profile by tapping "Favourites". This makes it easy to quickly rebook workers you have used before.',
                          ),
                          _HelpTileData(
                            icon: Icons.home_outlined,
                            iconColor: Color(0xFF00897B),
                            iconBg: Color(0xFFE0F4F1),
                            title: 'Managing your addresses',
                            content:
                                'Tap the location label on the home screen to open your saved addresses. You can add new addresses, edit existing ones, set a default address, and pin locations on a map. Your default address is used automatically each time you open the app.',
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
                              value: 'support@skillfox.lk',
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
