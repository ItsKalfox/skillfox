import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../models/worker.dart';
import '../../category_a/waiting_worker_screen.dart';
import '../../category_a/customer_quotation_view_screen.dart';
import '../../category_a/review_screen.dart';
import '../../category_b/customer_quotation_screen.dart';
import '../../category_c/customer_subscription_screen.dart';

// ── Colour palette (matches customer_bookings_screen) ────────────────────────
class _C {
  static const gradA = Color(0xFF469FEF);
  static const gradB = Color(0xFF6C56F0);
  static const accent = Color(0xFF6C56F0);
  static const bg = Color(0xFFF4F6FA);
  static const cardBdr = Color(0xFFE2E6F0);
  static const txt1 = Color(0xFF111111);
  static const txt2 = Color(0xFF888888);
  static const muted = Color(0xFFA0A4B0);
  static const green = Color(0xFF16A34A);
  static const orange = Color(0xFFEA580C);
  static const blue = Color(0xFF2563EB);
  static const red = Color(0xFFEF4444);
  static const redBg = Color(0xFFFEF2F2);
  static const redBdr = Color(0xFFFECACA);
}

// ── Status chip config ────────────────────────────────────────────────────────
class _Cfg {
  final String label;
  final Color color, bgColor;
  final IconData icon;
  const _Cfg(this.label, this.color, this.bgColor, this.icon);
}

_Cfg _cfg(String status) {
  switch (status) {
    case 'completed':
      return const _Cfg(
        'Completed',
        _C.green,
        Color(0xFFECFDF5),
        Icons.verified_rounded,
      );
    case 'job_done':
      return const _Cfg(
        'Job Done',
        _C.green,
        Color(0xFFECFDF5),
        Icons.verified_rounded,
      );
    case 'cancelled':
      return const _Cfg(
        'Cancelled',
        _C.muted,
        Color(0xFFF4F6FA),
        Icons.do_not_disturb_rounded,
      );
    case 'rejected':
      return const _Cfg('Declined', _C.red, _C.redBg, Icons.cancel_outlined);
    case 'quotation_declined':
      return const _Cfg(
        'Qtn Declined',
        _C.red,
        _C.redBg,
        Icons.cancel_outlined,
      );
    default:
      return const _Cfg(
        'Done',
        _C.muted,
        Color(0xFFF4F6FA),
        Icons.check_rounded,
      );
  }
}

const _historyStatuses = [
  'completed',
  'job_done',
  'cancelled',
  'rejected',
  'quotation_declined',
];

// ── Screen ────────────────────────────────────────────────────────────────────
class CustomerBookingHistoryScreen extends StatefulWidget {
  const CustomerBookingHistoryScreen({super.key});

  @override
  State<CustomerBookingHistoryScreen> createState() =>
      _CustomerBookingHistoryScreenState();
}

class _CustomerBookingHistoryScreenState
    extends State<CustomerBookingHistoryScreen> {
  final List<Map<String, dynamic>> _docs = [];
  final List<StreamSubscription> _subs = [];
  bool _loading = true;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── filter state ─────────────────────────────────────────────────
  String _filterStatus =
      'all'; // 'all' | 'completed' | 'cancelled' | 'rejected'
  String _filterCategory = 'all'; // 'all' | 'A' | 'B' | 'C'

  static const _statusFilters = [
    {'id': 'all', 'label': 'All'},
    {'id': 'completed', 'label': 'Completed'},
    {'id': 'cancelled', 'label': 'Cancelled'},
    {'id': 'rejected', 'label': 'Declined'},
  ];

  static const _catFilters = [
    {'id': 'all', 'label': 'All Types'},
    {'id': 'A', 'label': 'Inspection'},
    {'id': 'B', 'label': 'One-time'},
    {'id': 'C', 'label': 'Subscription'},
  ];

  @override
  void initState() {
    super.initState();
    _subscribeAll();
  }

  @override
  void dispose() {
    for (final s in _subs) s.cancel();
    super.dispose();
  }

  void _subscribeAll() {
    if (_uid.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    for (final status in _historyStatuses) {
      final sub = FirebaseFirestore.instance
          .collection('requests')
          .where('customerId', isEqualTo: _uid)
          .where('status', isEqualTo: status)
          .snapshots()
          .listen((snap) {
            if (!mounted) return;
            setState(() {
              _docs.removeWhere((d) => d['status'] == status);
              for (final doc in snap.docs) {
                final d = Map<String, dynamic>.from(doc.data());
                d['id'] = doc.id;
                _docs.add(d);
              }
              _docs.sort((a, b) {
                final ta =
                    (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                final tb =
                    (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                return tb.compareTo(ta);
              });
              _loading = false;
            });
          });
      _subs.add(sub);
    }
  }

  // ── category type helper ──────────────────────────────────────────
  String _categoryType(Map<String, dynamic> d) {
    final stored = (d['categoryType'] as String?)?.trim().toUpperCase();
    if (stored == 'A' || stored == 'B' || stored == 'C') return stored!;
    const catC = {
      'teacher',
      'tutor',
      'caregiver',
      'care giver',
      'baby sitter',
      'babysitter',
      'nurse',
      'nanny',
    };
    const catB = {
      'cleaner',
      'cleaning',
      'handyman',
      'painter',
      'carpenter',
      'gardener',
      'pest control',
    };
    final lower = (d['category'] as String? ?? '').toLowerCase().trim();
    if (catC.contains(lower)) return 'C';
    if (catB.contains(lower)) return 'B';
    return 'A';
  }

  // ── filtered list ─────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filtered {
    return _docs.where((d) {
      final status = d['status'] as String? ?? '';
      final catType = _categoryType(d);

      // status filter — 'completed' also matches 'job_done'
      if (_filterStatus != 'all') {
        if (_filterStatus == 'completed') {
          if (status != 'completed' && status != 'job_done') return false;
        } else {
          if (status != _filterStatus) return false;
        }
      }

      // category filter
      if (_filterCategory != 'all' && catType != _filterCategory) return false;

      return true;
    }).toList();
  }

  // ── navigation ────────────────────────────────────────────────────
  void _navigate(BuildContext context, Map<String, dynamic> d) {
    final status = d['status'] as String? ?? '';
    final catType = _categoryType(d);

    // Completed Cat B/C → ReviewScreen (in case they haven't reviewed yet)
    if ((catType == 'B' || catType == 'C') &&
        (status == 'job_done' || status == 'completed')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewScreen(
            requestId: d['id'] as String,
            requestData: d,
            isWorker: false,
          ),
        ),
      );
      return;
    }

    // Completed Cat A → WaitingWorkerScreen (handles review button at stage 9)
    if (catType == 'A' && status == 'completed') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WaitingWorkerScreen(
            requestId: d['id'] as String,
            worker: _workerFromData(d),
          ),
        ),
      );
      return;
    }

    // Quotation declined Cat A → CustomerQuotationViewScreen (read-only)
    if (status == 'quotation_declined' && catType == 'A') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerQuotationViewScreen(
            requestId: d['id'] as String,
            requestData: d,
          ),
        ),
      );
      return;
    }

    // Quotation declined Cat B → CategoryBCustomerQuotationScreen (read-only)
    if (status == 'quotation_declined' && catType == 'B') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryBCustomerQuotationScreen(
            requestId: d['id'] as String,
            requestData: d,
          ),
        ),
      );
      return;
    }

    // Quotation declined Cat C → CategoryCCustomerSubscriptionScreen (read-only)
    if (status == 'quotation_declined' && catType == 'C') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryCCustomerSubscriptionScreen(
            requestId: d['id'] as String,
            requestData: d,
          ),
        ),
      );
      return;
    }

    // Cancelled / rejected → WaitingWorkerScreen (shows declined state)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WaitingWorkerScreen(
          requestId: d['id'] as String,
          worker: _workerFromData(d),
        ),
      ),
    );
  }

  Worker _workerFromData(Map<String, dynamic> d) => Worker(
    id: d['workerId'] ?? '',
    name: d['workerName'] ?? '',
    category: d['category'] ?? '',
    rating: (d['workerRating'] ?? 0).toDouble(),
    ratingCount: 0,
    completedJobsCount: 0,
    distanceKm: 0,
    travelMinutes: 0,
    travelFee: 0,
    hasOffer: false,
    offerType: '',
    isFeatured: false,
    featuredWeekKey: '',
    isFavorite: false,
    profilePhotoUrl: '',
    address: d['address'] ?? '',
    offerDetails: '',
  );

  // ── UI ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          _buildHeader(context),
          _buildFilters(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Container(
    color: Colors.white,
    padding: EdgeInsets.only(
      top: MediaQuery.of(context).padding.top + 4,
      bottom: 14,
      left: 16,
      right: 16,
    ),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFF0F2F8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 14,
              color: Color(0xFF444444),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Booking History',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _C.txt1,
            ),
          ),
        ),
        // Total count badge
        if (!_loading)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_filtered.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _C.accent,
              ),
            ),
          ),
      ],
    ),
  );

  Widget _buildFilters() => Container(
    color: Colors.white,
    child: Column(
      children: [
        const Divider(height: 1, color: _C.cardBdr),
        const SizedBox(height: 8),

        // Status filter row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: _statusFilters.map((f) {
              final active = _filterStatus == f['id'];
              return GestureDetector(
                onTap: () => setState(() => _filterStatus = f['id']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: active
                        ? const LinearGradient(colors: [_C.gradA, _C.gradB])
                        : null,
                    color: active ? null : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active ? Colors.transparent : _C.cardBdr,
                    ),
                  ),
                  child: Text(
                    f['label']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : _C.txt2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 8),

        // Category type filter row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: _catFilters.map((f) {
              final active = _filterCategory == f['id'];
              Color activeBg;
              switch (f['id']) {
                case 'B':
                  activeBg = const Color(0xFF10B981);
                  break;
                case 'C':
                  activeBg = const Color(0xFF8B5CF6);
                  break;
                default:
                  activeBg = _C.accent;
              }
              return GestureDetector(
                onTap: () => setState(() => _filterCategory = f['id']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: active ? activeBg : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active ? Colors.transparent : _C.cardBdr,
                    ),
                  ),
                  child: Text(
                    f['label']!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : _C.txt2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
      ],
    ),
  );

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _C.accent));
    }
    final items = _filtered;
    if (items.isEmpty) return _buildEmpty();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final d = items[i];
        final status = d['status'] as String? ?? '';
        // cancelled has no tappable detail
        final tappable = status != 'cancelled';
        return _HistoryCard(
          data: d,
          onTap: tappable ? () => _navigate(context, d) : null,
          categoryType: _categoryType(d),
        );
      },
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Color(0xFFEEF2FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.history_rounded, size: 32, color: _C.accent),
        ),
        const SizedBox(height: 14),
        const Text(
          'No History Found',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _C.txt1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _filterStatus == 'all' && _filterCategory == 'all'
              ? 'Your completed and past bookings\nwill appear here.'
              : 'No bookings match the selected filters.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: _C.txt2, height: 1.6),
        ),
      ],
    ),
  );
}

// ── History Card ──────────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;
  final String categoryType;

  const _HistoryCard({
    required this.data,
    required this.categoryType,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? '';
    final cfg = _cfg(status);
    final id = data['id'] as String? ?? '';
    final shortId = (id.length >= 8 ? id.substring(0, 8) : id).toUpperCase();
    final category = data['category'] as String? ?? '—';
    final workerName = data['workerName'] as String?;
    final createdAt = data['createdAt'] as Timestamp?;
    final isCompleted = status == 'completed' || status == 'job_done';
    final isCancelled = status == 'cancelled';
    final isRejected = status == 'rejected' || status == 'quotation_declined';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFFBBF7D0)
                : isRejected
                ? _C.redBdr
                : _C.cardBdr.withOpacity(0.5),
            width: 0.5,
          ),
          boxShadow: isCancelled
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: icon + id + category pill + status chip
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isCancelled || isRejected
                        ? (isRejected ? _C.redBg : const Color(0xFFF0F2F8))
                        : null,
                    gradient: (!isCancelled && !isRejected)
                        ? LinearGradient(colors: _catColors(categoryType))
                        : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _catIcon(category),
                    size: 14,
                    color: (isCancelled || isRejected)
                        ? (isRejected ? _C.red : _C.muted)
                        : Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#$shortId',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCancelled ? _C.muted : _C.txt1,
                        ),
                      ),
                      Text(
                        category,
                        style: const TextStyle(fontSize: 10, color: _C.txt2),
                      ),
                    ],
                  ),
                ),
                // Category type pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: _catPillBg(categoryType),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _catPillLabel(categoryType),
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: _catPillFg(categoryType),
                    ),
                  ),
                ),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cfg.bgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cfg.icon, size: 10, color: cfg.color),
                      const SizedBox(width: 4),
                      Text(
                        cfg.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: cfg.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: _C.cardBdr),
            const SizedBox(height: 10),

            // ── Bottom row: worker avatar + name + date + chevron
            Row(
              children: [
                if (workerName != null) ...[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _catColors(categoryType),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        workerName.isNotEmpty
                            ? workerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      workerName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _C.txt1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  const Expanded(
                    child: Text(
                      'No worker assigned',
                      style: TextStyle(fontSize: 10, color: _C.muted),
                    ),
                  ),
                if (createdAt != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    _shortDate(createdAt),
                    style: const TextStyle(fontSize: 10, color: _C.muted),
                  ),
                ],
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: _C.muted,
                  ),
                ],
              ],
            ),

            // ── Rejection banner
            if (isRejected) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _C.redBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status == 'quotation_declined'
                      ? 'Quotation was declined'
                      : 'Worker declined this request',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFB91C1C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            // ── Completed summary (amount paid)
            if (isCompleted) ...[
              const SizedBox(height: 8),
              _buildCompletedSummary(),
            ],

            // ── Leave a review prompt (if not yet reviewed)
            if (isCompleted && (data['customerReview'] == null)) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _catColors(
                      categoryType,
                    ).map((c) => c.withOpacity(0.08)).toList(),
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _catPillFg(categoryType).withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: _catPillFg(categoryType),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Tap to leave a review',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _catPillFg(categoryType),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: _catPillFg(categoryType),
                    ),
                  ],
                ),
              ),
            ],

            // ── Already reviewed badge
            if (isCompleted && data['customerReview'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 11, color: _C.green),
                    const SizedBox(width: 4),
                    const Text(
                      'Reviewed',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _C.green,
                      ),
                    ),
                    if ((data['customerRating'] as int?) != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '· ${data['customerRating']}★',
                        style: const TextStyle(
                          fontSize: 10,
                          color: _C.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedSummary() {
    // Try to find any stored total — works across Cat A, B, C
    final total =
        (data['totalPaid'] as num?) ??
        (data['bTotalPaid'] as num?) ??
        (data['quotationTotalPaid'] as num?) ??
        (data['cMonthlyPrice'] as num?);

    if (total == null) return const SizedBox.shrink();

    final label = (data['categoryType'] as String?) == 'C'
        ? 'Monthly Rate'
        : 'Total Paid';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 12, color: _C.green),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 10, color: _C.green)),
          const Spacer(),
          Text(
            'LKR ${_fmt(total)}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _C.green,
            ),
          ),
        ],
      ),
    );
  }

  // ── helpers ────────────────────────────────────────────────────────
  static String _fmt(num n) {
    final s = n.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  static List<Color> _catColors(String type) {
    if (type == 'B') return [const Color(0xFF10B981), const Color(0xFF059669)];
    if (type == 'C') return [const Color(0xFF8B5CF6), const Color(0xFF6C56F0)];
    return [const Color(0xFF469FEF), const Color(0xFF6C56F0)];
  }

  static Color _catPillBg(String type) {
    if (type == 'B') return const Color(0xFFECFDF5);
    if (type == 'C') return const Color(0xFFF3EEFF);
    return const Color(0xFFEFF6FF);
  }

  static Color _catPillFg(String type) {
    if (type == 'B') return const Color(0xFF059669);
    if (type == 'C') return const Color(0xFF7C3AED);
    return const Color(0xFF2563EB);
  }

  static String _catPillLabel(String type) {
    if (type == 'B') return 'ONE-TIME';
    if (type == 'C') return 'SUBSCRIPTION';
    return 'INSPECTION';
  }

  static IconData _catIcon(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('electric')) return Icons.electrical_services_rounded;
    if (c.contains('plumb')) return Icons.plumbing_rounded;
    if (c.contains('clean')) return Icons.cleaning_services_rounded;
    if (c.contains('paint')) return Icons.format_paint_rounded;
    if (c.contains('air') || c.contains('ac')) return Icons.ac_unit_rounded;
    if (c.contains('teach') || c.contains('tutor')) return Icons.school_rounded;
    if (c.contains('care') || c.contains('nanny'))
      return Icons.favorite_rounded;
    return Icons.handyman_rounded;
  }

  static String _shortDate(Timestamp ts) {
    final dt = ts.toDate().toLocal();
    const mo = [
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
    return '${mo[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
