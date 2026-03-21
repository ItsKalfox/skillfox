import 'package:flutter/material.dart';
import '../../../models/worker.dart';

class WorkerProfileScreen extends StatelessWidget {
  final Worker worker;

  const WorkerProfileScreen({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: CustomScrollView(
        slivers: [
          // ── App Bar with profile photo ──
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0xFF4B7DF3),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF5AA4F6), Color(0xFF4B7DF3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      backgroundImage: worker.profilePhotoUrl.isNotEmpty
                          ? NetworkImage(worker.profilePhotoUrl)
                          : null,
                      child: worker.profilePhotoUrl.isEmpty
                          ? const Icon(Icons.person,
                              size: 52, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      worker.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      worker.category,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEAECEF)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          icon: Icons.star_rounded,
                          iconColor: Colors.amber,
                          value: worker.rating.toStringAsFixed(1),
                          label: '${worker.ratingCount} reviews',
                        ),
                        _Divider(),
                        _StatItem(
                          icon: Icons.check_circle_outline_rounded,
                          iconColor: const Color(0xFF4CAF50),
                          value: '${worker.completedJobsCount}',
                          label: 'Jobs done',
                        ),
                        _Divider(),
                        _StatItem(
                          icon: Icons.location_on_outlined,
                          iconColor: const Color(0xFF4B7DF3),
                          value:
                              '${worker.distanceKm.toStringAsFixed(1)} km',
                          label: 'Away',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Travel info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEAECEF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Travel Info',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF222222),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.access_time_rounded,
                          label: 'Estimated arrival',
                          value: '${worker.travelMinutes} min',
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.directions_car_outlined,
                          label: 'Travel fee',
                          value: worker.hasOffer &&
                                  worker.offerType == 'free_travel'
                              ? 'LKR 0 (Free Travel)'
                              : 'LKR ${worker.travelFee.toStringAsFixed(0)}',
                          valueColor: worker.hasOffer &&
                                  worker.offerType == 'free_travel'
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF222222),
                        ),
                        if (worker.address != null &&
                            worker.address!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.home_outlined,
                            label: 'Based in',
                            value: worker.address!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Offer badge (if applicable)
                  if (worker.hasOffer)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEEEE),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer_rounded,
                              color: Colors.redAccent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              worker.offerType == 'free_travel'
                                  ? 'This worker is offering FREE travel to your location!'
                                  : 'This worker has a special offer available.',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Book Now button ──
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEAECEF))),
        ),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: () {
              // TODO: implement booking flow
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking coming soon!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4B7DF3),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Book Now',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helper widgets ──────────────────────────────────────

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF222222),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: const Color(0xFFEAECEF),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF8A8A8A)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF8A8A8A)),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF222222),
          ),
        ),
      ],
    );
  }
}
