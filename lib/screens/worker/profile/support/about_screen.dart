import 'package:flutter/material.dart';

class WorkerAboutScreen extends StatelessWidget {
  const WorkerAboutScreen({super.key});

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
                        'About SkillFox',
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
                      // ── Hero card ──────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Logo row
                            Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.12),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.asset(
                                      'assets/images/app_icon.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'SkillFox',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    Text(
                                      'Skill & Service Finder',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.80),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Connecting Sri Lankan users with verified local service professionals in real-time — reliably, transparently, and conveniently.',
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.55,
                                color: Colors.white.withOpacity(0.88),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Version + group badges
                            Row(
                              children: [
                                _HeroBadge(
                                  icon: Icons.tag_rounded,
                                  label: 'Version 1.0',
                                ),
                                const SizedBox(width: 8),
                                _HeroBadge(
                                  icon: Icons.flag_rounded,
                                  label: 'Sri Lanka',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── What is SkillFox ───────────────
                      const _SectionLabel(label: 'WHAT IS SKILLFOX'),
                      const SizedBox(height: 12),
                      _InfoCard(
                        child: const Padding(
                          padding: EdgeInsets.all(18),
                          child: Text(
                            'SkillFox is a location-based mobile platform that bridges the gap between everyday service seekers and skilled professionals across Sri Lanka. Whether you need a plumber, electrician, tutor, mechanic, or caregiver, SkillFox helps you find verified, nearby workers quickly and safely.\n\nInstead of relying on informal channels and word-of-mouth referrals, users can browse worker profiles, compare ratings, see transparent pricing, and book services directly from their phone.',
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.65,
                              color: Color(0xFF444444),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Key features ───────────────────
                      const _SectionLabel(label: 'KEY FEATURES'),
                      const SizedBox(height: 12),
                      _InfoCard(
                        child: Column(
                          children: const [
                            _FeatureTile(
                              icon: Icons.location_on_rounded,
                              iconColor: Color(0xFF4B7DF3),
                              iconBg: Color(0xFFEEF2FF),
                              title: 'Location-Based Discovery',
                              description:
                                  'Find verified workers near you in real-time using Google Maps geolocation.',
                            ),
                            _FeatureDivider(),
                            _FeatureTile(
                              icon: Icons.verified_rounded,
                              iconColor: Color(0xFF2E7D32),
                              iconBg: Color(0xFFE8F5E9),
                              title: 'Verified Profiles',
                              description:
                                  'Every worker goes through a profile verification process to ensure trust and accountability.',
                            ),
                            _FeatureDivider(),
                            _FeatureTile(
                              icon: Icons.star_rounded,
                              iconColor: Color(0xFFF9A825),
                              iconBg: Color(0xFFFFFDE7),
                              title: 'Ratings and Reviews',
                              description:
                                  'Rate workers after each job to help the community make better decisions.',
                            ),
                            _FeatureDivider(),
                            _FeatureTile(
                              icon: Icons.price_check_rounded,
                              iconColor: Color(0xFF7C5CFC),
                              iconBg: Color(0xFFF0EBFF),
                              title: 'Transparent Pricing',
                              description:
                                  'See travel fees and service estimates upfront with no hidden charges or surprises.',
                            ),
                            _FeatureDivider(),
                            _FeatureTile(
                              icon: Icons.tune_rounded,
                              iconColor: Color(0xFF00897B),
                              iconBg: Color(0xFFE0F4F1),
                              title: 'Smart Filters',
                              description:
                                  'Search by service type, rating, distance, price, and availability.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Why SkillFox ───────────────────
                      const _SectionLabel(label: 'WHY SKILLFOX'),
                      const SizedBox(height: 12),
                      _InfoCard(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Solving a real problem in Sri Lanka',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1F2E),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Most on-demand service platforms available today are built for large economies and do not fit the Sri Lankan context. They rely on international payment systems, complex verification processes, and high operating costs.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.6,
                                  color: Color(0xFF555555),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'SkillFox is built specifically for Sri Lanka, affordable, accessible, and designed around the real needs of local service seekers and workers.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.6,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Tech stack ─────────────────────
                      const _SectionLabel(label: 'BUILT WITH'),
                      const SizedBox(height: 12),
                      _InfoCard(
                        child: Column(
                          children: const [
                            _FeatureTile(
                              icon: Icons.phone_android_rounded,
                              iconColor: Color(0xFF4B7DF3),
                              iconBg: Color(0xFFEEF2FF),
                              title: 'Flutter',
                              description:
                                  'Cross-platform mobile app framework for iOS and Android.',
                            ),
                            _FeatureDivider(),
                            _FeatureTile(
                              icon: Icons.local_fire_department_rounded,
                              iconColor: Color(0xFFE65100),
                              iconBg: Color(0xFFFFF3E0),
                              title: 'Firebase',
                              description:
                                  'Backend, authentication, Firestore database, and cloud storage.',
                            ),
                            _FeatureDivider(),
                            _FeatureTile(
                              icon: Icons.map_rounded,
                              iconColor: Color(0xFF2E7D32),
                              iconBg: Color(0xFFE8F5E9),
                              title: 'Google Maps API',
                              description:
                                  'Real-time geolocation, worker proximity, and map-based discovery.',
                            ),
                            _FeatureDivider(),
                            _FeatureTile(
                              icon: Icons.code_rounded,
                              iconColor: Color(0xFF7C5CFC),
                              iconBg: Color(0xFFF0EBFF),
                              title: 'GitHub',
                              description:
                                  'Version control and collaborative team development.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      const SizedBox(height: 4),

                      // ── Footer ─────────────────────────
                      Center(
                        child: Column(
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  'assets/images/app_icon.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'SkillFox',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF9AA3B4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '© 2025 All rights reserved',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: const Color(0xFFBCC4D4),
                              ),
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
//  Helper Widgets
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

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }
}

class _FeatureDivider extends StatelessWidget {
  const _FeatureDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 62,
      endIndent: 16,
      color: Color(0xFFF0F2F8),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeroBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.30), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String description;

  const _FeatureTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1F2E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: Color(0xFF9AA3B4),
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
