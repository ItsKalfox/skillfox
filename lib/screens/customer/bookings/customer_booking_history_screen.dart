import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../signup/customer/worker_profile.dart';
import '../../../models/worker.dart';

class CustomerBookingHistoryScreen extends StatelessWidget {
  const CustomerBookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF4B7DF3),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────
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
                        'Booking History',
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
                child: uid == null
                    ? const Center(child: Text('Not logged in.'))
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('payments')
                            .where('customerId', isEqualTo: uid)
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF4B7DF3),
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }

                          final docs = snapshot.data?.docs ?? [];

                          if (docs.isEmpty) return const _EmptyState();

                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                            itemCount: docs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final data =
                                  docs[index].data() as Map<String, dynamic>;
                              return _BookingCard(
                                data: data,
                                docId: docs[index].id,
                              );
                            },
                          );
                        },
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
//  Booking Card
// ═══════════════════════════════════════════════
class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _BookingCard({required this.data, required this.docId});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'pending':
        return const Color(0xFFF9A825);
      case 'cancelled':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF9AA3B4);
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFFE8F5E9);
      case 'pending':
        return const Color(0xFFFFFDE7);
      case 'cancelled':
        return const Color(0xFFFFEBEB);
      default:
        return const Color(0xFFF4F6FB);
    }
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return '';
    final dt = (ts as Timestamp).toDate();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _BookingDetailScreen(data: data, docId: docId),
      ),
    );
  }

  void _rebook(BuildContext context) {
    final worker = Worker(
      id: data['workerId'] ?? '',
      name: data['workerName'] ?? 'Worker',
      category: data['service'] ?? '',
      rating: 0,
      ratingCount: 0,
      completedJobsCount: 0,
      distanceKm: 0,
      travelMinutes: 0,
      travelFee: 0,
      hasOffer: false,
      offerType: '',
      offerDetails: '',
      isFeatured: false,
      featuredWeekKey: '',
      isFavorite: false,
      profilePhotoUrl: '',
      address: '',
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WorkerProfileScreen(worker: worker)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? '').toString();
    final service = (data['service'] ?? 'Service').toString();
    final workerName = (data['workerName'] ?? 'Worker').toString();
    final amount = data['amount']?.toString() ?? '0';
    final date = _formatDate(data['createdAt']);

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEAECEF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon bubble
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.home_repair_service_rounded,
                color: Color(0xFF4B7DF3),
                size: 22,
              ),
            ),
            const SizedBox(width: 13),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          service,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1F2E),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusBg(status),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status.isNotEmpty
                              ? status[0].toUpperCase() + status.substring(1)
                              : '',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _statusColor(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 13,
                        color: Color(0xFF9AA3B4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        workerName,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF9AA3B4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: Color(0xFF9AA3B4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9AA3B4),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'LKR $amount',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1F2E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Rebook button
            GestureDetector(
              onTap: () => _rebook(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4B7DF3).withOpacity(0.3),
                  ),
                ),
                child: const Text(
                  'Rebook',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4B7DF3),
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
//  Booking Detail Screen
// ═══════════════════════════════════════════════
class _BookingDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _BookingDetailScreen({required this.data, required this.docId});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'pending':
        return const Color(0xFFF9A825);
      case 'cancelled':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF9AA3B4);
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFFE8F5E9);
      case 'pending':
        return const Color(0xFFFFFDE7);
      case 'cancelled':
        return const Color(0xFFFFEBEB);
      default:
        return const Color(0xFFF4F6FB);
    }
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return 'N/A';
    final dt = (ts as Timestamp).toDate();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  void _rebook(BuildContext context) {
    final worker = Worker(
      id: data['workerId'] ?? '',
      name: data['workerName'] ?? 'Worker',
      category: data['service'] ?? '',
      rating: 0,
      ratingCount: 0,
      completedJobsCount: 0,
      distanceKm: 0,
      travelMinutes: 0,
      travelFee: 0,
      hasOffer: false,
      offerType: '',
      offerDetails: '',
      isFeatured: false,
      featuredWeekKey: '',
      isFavorite: false,
      profilePhotoUrl: '',
      address: '',
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WorkerProfileScreen(worker: worker)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? '').toString();
    final service = (data['service'] ?? 'Service').toString();
    final workerName = (data['workerName'] ?? 'N/A').toString();
    final customerName = (data['customerName'] ?? 'N/A').toString();
    final amount = data['amount']?.toString() ?? '0';
    final commission = data['commission']?.toString() ?? '0';
    final netAmount = data['netAmount']?.toString() ?? '0';
    final date = _formatDate(data['createdAt']);

    return Scaffold(
      backgroundColor: const Color(0xFF4B7DF3),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ──────────────────────────────
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
                        'Booking Details',
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

            // ── Body ────────────────────────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F6FB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status hero
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
                                Icons.home_repair_service_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusBg(status),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      status.isNotEmpty
                                          ? status[0].toUpperCase() +
                                                status.substring(1)
                                          : '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _statusColor(status),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // ── People ───────────────────────
                      const _SectionLabel(label: 'PEOPLE'),
                      const SizedBox(height: 10),
                      _InfoCard(
                        children: [
                          _DetailRow(
                            icon: Icons.person_outline_rounded,
                            iconColor: const Color(0xFF4B7DF3),
                            iconBg: const Color(0xFFEEF2FF),
                            label: 'Worker',
                            value: workerName,
                          ),
                          const _Divider(),
                          _DetailRow(
                            icon: Icons.person_rounded,
                            iconColor: const Color(0xFF7C5CFC),
                            iconBg: const Color(0xFFF0EBFF),
                            label: 'Customer',
                            value: customerName,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // ── Payment ──────────────────────
                      const _SectionLabel(label: 'PAYMENT'),
                      const SizedBox(height: 10),
                      _InfoCard(
                        children: [
                          _DetailRow(
                            icon: Icons.payments_outlined,
                            iconColor: const Color(0xFF2E7D32),
                            iconBg: const Color(0xFFE8F5E9),
                            label: 'Total Amount',
                            value: 'LKR $amount',
                          ),
                          const _Divider(),
                          _DetailRow(
                            icon: Icons.percent_rounded,
                            iconColor: const Color(0xFFF9A825),
                            iconBg: const Color(0xFFFFFDE7),
                            label: 'Commission',
                            value: 'LKR $commission',
                          ),
                          const _Divider(),
                          _DetailRow(
                            icon: Icons.account_balance_wallet_outlined,
                            iconColor: const Color(0xFF4B7DF3),
                            iconBg: const Color(0xFFEEF2FF),
                            label: 'Net Amount',
                            value: 'LKR $netAmount',
                            valueStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF4B7DF3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // ── Details ──────────────────────
                      const _SectionLabel(label: 'DETAILS'),
                      const SizedBox(height: 10),
                      _InfoCard(
                        children: [
                          _DetailRow(
                            icon: Icons.calendar_today_outlined,
                            iconColor: const Color(0xFF00897B),
                            iconBg: const Color(0xFFE0F4F1),
                            label: 'Date',
                            value: date,
                          ),
                          const _Divider(),
                          _DetailRow(
                            icon: Icons.receipt_outlined,
                            iconColor: const Color(0xFF9AA3B4),
                            iconBg: const Color(0xFFF4F6FB),
                            label: 'Booking ID',
                            value: docId,
                            valueStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF9AA3B4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── Book Again button ────────────
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => _rebook(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4B7DF3),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.replay_rounded, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Book Again',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
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
//  Shared helpers
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
  final List<Widget> children;
  const _InfoCard({required this.children});

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
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 13),
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
                  style:
                      valueStyle ??
                      const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1F2E),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 52, color: Color(0xFFCBD0DC)),
          SizedBox(height: 14),
          Text(
            'No bookings yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9AA3B4),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Your booking history will appear here',
            style: TextStyle(fontSize: 13, color: Color(0xFFBCC4D4)),
          ),
        ],
      ),
    );
  }
}
