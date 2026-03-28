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
  static const greenDk = Color(0xFF1E8449);
  static const orange = Color(0xFFEA580C);
  static const blue = Color(0xFF2563EB);
  static const star = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const redBg = Color(0xFFFEF2F2);
  static const redBdr = Color(0xFFFECACA);
}

class _Cfg {
  final String label;
  final Color color, bgColor;
  final IconData icon;
  final int stepIndex;
  const _Cfg(this.label, this.color, this.bgColor, this.icon, this.stepIndex);
}

_Cfg _cfg(String status) {
  switch (status) {
    case 'pending':
      return const _Cfg(
        'Waiting',
        _C.accent,
        Color(0xFFEEF2FF),
        Icons.hourglass_top_rounded,
        1,
      );
    case 'accepted':
      return const _Cfg(
        'Accepted',
        _C.orange,
        Color(0xFFFFF7ED),
        Icons.check_circle_outline_rounded,
        2,
      );
    case 'rejected':
      return const _Cfg('Declined', _C.red, _C.redBg, Icons.cancel_outlined, 1);
    case 'inprogress':
      return const _Cfg(
        'Paid',
        _C.blue,
        Color(0xFFEFF6FF),
        Icons.payment_rounded,
        3,
      );
    case 'arrived':
      return const _Cfg(
        'Worker Arrived',
        _C.green,
        Color(0xFFF0FDF4),
        Icons.directions_walk_rounded,
        3,
      );
    case 'completed':
      return const _Cfg(
        'Completed',
        _C.green,
        Color(0xFFECFDF5),
        Icons.verified_rounded,
        4,
      );
    case 'quotation_sent':
      return const _Cfg(
        'Quotation!',
        _C.blue,
        Color(0xFFEFF6FF),
        Icons.receipt_long_rounded,
        4,
      );
    case 'quotation_paid':
      return const _Cfg(
        'Quotation Paid',
        _C.green,
        Color(0xFFECFDF5),
        Icons.check_circle_rounded,
        4,
      );
    case 'quotation_declined':
      return const _Cfg(
        'Qtn Declined',
        _C.red,
        _C.redBg,
        Icons.cancel_outlined,
        4,
      );
    case 'cancelled':
      return const _Cfg(
        'Cancelled',
        _C.muted,
        Color(0xFFF4F6FA),
        Icons.do_not_disturb_rounded,
        0,
      );
    default:
      return const _Cfg(
        'Submitted',
        _C.accent,
        Color(0xFFEEF2FF),
        Icons.radio_button_checked,
        0,
      );
  }
}

const _activeStatuses = [
  'pending',
  'accepted',
  'inprogress',
  'arrived',
  'quotation_sent',
  'quotation_paid',
];
const _historyStatuses = [
  'cancelled',
  'rejected',
  'quotation_declined',
  'completed',
  'job_done',
];

class CustomerBookingsScreen extends StatefulWidget {
  const CustomerBookingsScreen({super.key});

  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _C.bg,
    body: Column(
      children: [
        _header(),
        _tabBar(),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _BookingList(uid: _uid, isActive: true),
              _BookingList(uid: _uid, isActive: false),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _header() => Container(
    color: Colors.white,
    padding: EdgeInsets.only(
      top: MediaQuery.of(context).padding.top + 4,
      bottom: 0,
      left: 16,
      right: 16,
    ),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 32,
            height: 32,
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
        const Text(
          'My Bookings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _C.txt1,
          ),
        ),
      ],
    ),
  );

  Widget _tabBar() => Container(
    color: Colors.white,
    child: TabBar(
      controller: _tab,
      labelColor: _C.accent,
      unselectedLabelColor: _C.muted,
      indicatorColor: _C.accent,
      indicatorWeight: 2,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      tabs: const [
        Tab(text: 'Active'),
        Tab(text: 'History'),
      ],
    ),
  );
}

class _BookingList extends StatefulWidget {
  final String uid;
  final bool isActive;
  const _BookingList({required this.uid, required this.isActive});

  @override
  State<_BookingList> createState() => _BookingListState();
}

class _BookingListState extends State<_BookingList> {
  final List<Map<String, dynamic>> _docs = [];
  final List<StreamSubscription> _subs = [];
  bool _loading = true;

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
    if (widget.uid.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final statuses = widget.isActive ? _activeStatuses : _historyStatuses;
    for (final status in statuses) {
      final sub = FirebaseFirestore.instance
          .collection('requests')
          .where('customerId', isEqualTo: widget.uid)
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

  /// Derive category type — mirrors worker_profile_screen logic.
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

  void _navigate(BuildContext context, Map<String, dynamic> d) {
    final status = d['status'] as String? ?? 'pending';
    final catType = _categoryType(d);

    // quotation_sent — route to correct screen by category
    if (status == 'quotation_sent') {
      switch (catType) {
        case 'B':
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
        case 'C':
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
        default:
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
    }

    // Cat C active subscription
    if (catType == 'C' &&
        (status == 'inprogress' ||
            (d['cSubscriptionStatus'] as String?) == 'active')) {
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

    // Cat B inprogress (paid)
    if (catType == 'B' && status == 'inprogress') {
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

    // Cat B/C completed — go to ReviewScreen
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

    // Fallback: WaitingWorkerScreen (Cat A + Cat B pending)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WaitingWorkerScreen(
          requestId: d['id'] as String,
          worker: Worker(
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
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _C.accent));
    }
    if (_docs.isEmpty) return _EmptyState(isActive: widget.isActive);
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      itemCount: _docs.length,
      itemBuilder: (context, i) {
        final d = _docs[i];
        final status = d['status'] as String? ?? 'pending';
        final isCancelled = status == 'cancelled';
        return _BookingCard(
          data: d,
          onTap: isCancelled ? null : () => _navigate(context, d),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;
  const _BookingCard({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'pending';
    final cfg = _cfg(status);
    final id = data['id'] as String? ?? '';
    final shortId = (id.length >= 8 ? id.substring(0, 8) : id).toUpperCase();
    final category = data['category'] as String? ?? '—';
    final workerName = data['workerName'] as String?;
    final createdAt = data['createdAt'] as Timestamp?;
    final isCancelled = status == 'cancelled';
    final isRejected = status == 'rejected';
    final hasQuotation = status == 'quotation_sent';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasQuotation
                ? _C.blue.withOpacity(0.4)
                : isRejected
                ? _C.redBdr
                : isCancelled
                ? _C.cardBdr.withOpacity(0.4)
                : _C.cardBdr,
            width: hasQuotation ? 1.5 : 0.5,
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
            if (hasQuotation) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_C.gradA, _C.gradB]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.notifications_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'New quotation received! Tap to review.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: (!isCancelled && !isRejected)
                        ? const LinearGradient(colors: [_C.gradA, _C.gradB])
                        : null,
                    color: isRejected
                        ? _C.redBg
                        : isCancelled
                        ? const Color(0xFFF0F2F8)
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

            if (!isCancelled)
              _MiniStepBar(activeStep: cfg.stepIndex, isRejected: isRejected),

            const SizedBox(height: 12),

            Row(
              children: [
                if (workerName != null && !isCancelled) ...[
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [_C.gradA, _C.gradB]),
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
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      workerName,
                      style: const TextStyle(
                        fontSize: 10,
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
                if (!isCancelled) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: _C.muted,
                  ),
                ],
              ],
            ),

            if (status == 'accepted' ||
                status == 'inprogress' ||
                status == 'arrived')
              _WorkerLocationChip(data: data),

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
                child: const Text(
                  'Worker declined this request',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFFB91C1C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            if (hasQuotation) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFBFDBFE),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      size: 12,
                      color: _C.blue,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data['quotationJobDesc'] as String? ??
                            'New quotation from worker',
                        style: const TextStyle(fontSize: 10, color: _C.blue),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (data['quotationTotalCost'] != null)
                      Text(
                        'LKR ${(data['quotationTotalCost'] as num).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _C.blue,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static IconData _catIcon(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('electric')) return Icons.electrical_services_rounded;
    if (c.contains('plumb')) return Icons.plumbing_rounded;
    if (c.contains('clean')) return Icons.cleaning_services_rounded;
    if (c.contains('paint')) return Icons.format_paint_rounded;
    if (c.contains('air') || c.contains('ac')) return Icons.ac_unit_rounded;
    if (c.contains('repair') || c.contains('fix')) return Icons.build_rounded;
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
    return '${mo[dt.month - 1]} ${dt.day}';
  }
}

class _MiniStepBar extends StatelessWidget {
  final int activeStep;
  final bool isRejected;
  const _MiniStepBar({required this.activeStep, required this.isRejected});

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(5, (i) {
      final isDone = i < activeStep;
      final isActive = i == activeStep;
      final isRejStep = isRejected && i == 1;
      return Expanded(
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: (isDone || isActive) && !isRejStep
                    ? const LinearGradient(colors: [_C.gradA, _C.gradB])
                    : null,
                color: isRejStep
                    ? _C.red
                    : (isDone || isActive)
                    ? null
                    : const Color(0xFFE8EAF0),
              ),
              child: Center(
                child: isDone
                    ? const Icon(
                        Icons.check_rounded,
                        size: 8,
                        color: Colors.white,
                      )
                    : isRejStep
                    ? const Icon(
                        Icons.close_rounded,
                        size: 8,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            if (i < 4)
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: isDone && !isRejected
                        ? const LinearGradient(colors: [_C.gradA, _C.gradB])
                        : null,
                    color: (isDone && !isRejected)
                        ? null
                        : const Color(0xFFE2E6F0),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
          ],
        ),
      );
    }),
  );
}

class _WorkerLocationChip extends StatelessWidget {
  final Map<String, dynamic> data;
  const _WorkerLocationChip({required this.data});

  @override
  Widget build(BuildContext context) {
    final workerId = data['workerId'] as String?;
    if (workerId == null) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('workers')
          .doc(workerId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) return const SizedBox.shrink();
        final wd = snap.data!.data() as Map<String, dynamic>;
        final lat = (wd['currentLat'] as num?)?.toDouble();
        final lng = (wd['currentLng'] as num?)?.toDouble();
        if (lat == null || lng == null) return const SizedBox.shrink();
        final custLat = (data['latitude'] as num?)?.toDouble() ?? 0;
        final custLng = (data['longitude'] as num?)?.toDouble() ?? 0;
        final km = _haversine(lat, lng, custLat, custLng);
        final distTxt = (km > 100 || custLat == 0)
            ? 'Worker is nearby'
            : km < 1
            ? '${(km * 1000).round()} m away'
            : '${km.toStringAsFixed(1)} km away';
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 12, color: _C.blue),
                const SizedBox(width: 4),
                Text(
                  'Worker is $distTxt',
                  style: const TextStyle(
                    fontSize: 10,
                    color: _C.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                _PulseDot(),
              ],
            ),
          ),
        );
      },
    );
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _a = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: _C.green.withOpacity(_a.value),
        shape: BoxShape.circle,
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final bool isActive;
  const _EmptyState({required this.isActive});

  @override
  Widget build(BuildContext context) => Center(
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
          child: const Icon(
            Icons.receipt_long_outlined,
            size: 30,
            color: _C.accent,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          isActive ? 'No Active Bookings' : 'No Booking History',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _C.txt1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isActive
              ? 'Active inspection requests\nwill appear here.'
              : 'Completed and past requests\nwill appear here.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: _C.txt2, height: 1.6),
        ),
      ],
    ),
  );
}
