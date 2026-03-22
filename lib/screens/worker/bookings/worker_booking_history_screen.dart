import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/request_payment_service.dart';

class WorkerBookingHistoryScreen extends StatefulWidget {
  const WorkerBookingHistoryScreen({super.key});

  @override
  State<WorkerBookingHistoryScreen> createState() =>
      _WorkerBookingHistoryScreenState();
}

class _WorkerBookingHistoryScreenState extends State<WorkerBookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final User? _user = FirebaseAuth.instance.currentUser;

  // ── Earnings History ──
  List<Map<String, dynamic>> _earnings = [];
  bool _earningsLoading = true;
  String _earningsError = '';

  // ── Completed Tasks ──
  List<Map<String, dynamic>> _tasks = [];
  bool _tasksLoading = true;
  String _tasksError = '';
  final RequestPaymentService _paymentService = RequestPaymentService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchEarnings();
    _fetchCompletedTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Fetch Earnings ──
  Future<void> _fetchEarnings() async {
    setState(() {
      _earningsLoading = true;
      _earningsError = '';
    });
    try {
      final uid = _user?.uid;
      if (uid == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('earnings')
          .orderBy('createdAt', descending: true)
          .get();

      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'requestId': null,
          'source': 'legacy_earning',
          'taskName': data['taskName'] ?? 'Task',
          'amount': (data['amount'] ?? 0).toDouble(),
          'date': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'paymentStatus': (data['paymentStatus'] as String?) ?? 'unknown',
          'refundStatus': (data['refundStatus'] as String?) ?? 'none',
        };
      }).toList();

      // Include payment events from service requests as earnings history.
      final requestSnapshot = await FirebaseFirestore.instance
          .collection('service_requests')
          .where('workerId', isEqualTo: uid)
          .get();

      final requestEarnings = requestSnapshot.docs
          .map((doc) {
            final data = doc.data();
            final paymentStatus = (data['paymentStatus'] as String?) ?? 'unpaid';
            if (paymentStatus != 'released' &&
                paymentStatus != 'held' &&
                paymentStatus != 'refunded') {
              return null;
            }

            final paymentAmount = (data['paymentAmount'] as num?)?.toDouble() ??
                (data['price'] as num?)?.toDouble() ??
                0;
            if (paymentAmount <= 0) {
              return null;
            }

            final date =
                (data['paymentReleasedAt'] as Timestamp?)?.toDate() ??
                    (data['paymentHeldAt'] as Timestamp?)?.toDate() ??
                    (data['updatedAt'] as Timestamp?)?.toDate() ??
                    (data['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now();

            return {
              'id': doc.id,
              'requestId': doc.id,
              'source': 'service_request',
              'taskName': data['serviceType'] ?? data['service'] ?? 'Service Request',
              'amount': paymentStatus == 'refunded' ? -paymentAmount : paymentAmount,
              'date': date,
              'status': paymentStatus,
              'paymentStatus': paymentStatus,
              'refundStatus': (data['refundStatus'] as String?) ?? 'none',
            };
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      list.addAll(requestEarnings);
      list.sort(
        (a, b) =>
            (b['date'] as DateTime).compareTo(a['date'] as DateTime),
      );

      setState(() {
        _earnings = list;
        _earningsLoading = false;
      });
    } catch (e) {
      setState(() {
        _earningsError = 'Failed to load earnings.';
        _earningsLoading = false;
      });
    }
  }

  // ── Fetch Completed Tasks ──
  Future<void> _fetchCompletedTasks() async {
    setState(() {
      _tasksLoading = true;
      _tasksError = '';
    });
    try {
      final uid = _user?.uid;
      if (uid == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('service_requests')
          .where('workerId', isEqualTo: uid)
          .get();

      const pastStatuses = {
        'finished',
        'completed',
        'cancelled',
        'unavailable',
      };

      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        final status = (data['status'] as String?) ?? 'pending';
        if (!pastStatuses.contains(status)) {
          return null;
        }

        return {
          'id': doc.id,
          'taskName':
              data['serviceType'] ?? data['service'] ?? data['taskName'] ?? 'Task',
          'status': status,
          'amount': (data['paymentAmount'] as num?)?.toDouble() ??
              (data['price'] as num?)?.toDouble() ??
              (data['amount'] as num?)?.toDouble() ??
              0,
          'location': data['location'] ?? data['address'] ?? '',
          'description': data['description'] ?? '',
          'paymentStatus': (data['paymentStatus'] as String?) ?? 'unpaid',
          'refundStatus': (data['refundStatus'] as String?) ?? 'none',
          'date': (data['updatedAt'] as Timestamp?)?.toDate() ??
              (data['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.now(),
        };
      }).whereType<Map<String, dynamic>>().toList();

      list.sort(
        (a, b) =>
            (b['date'] as DateTime).compareTo(a['date'] as DateTime),
      );

      setState(() {
        _tasks = list;
        _tasksLoading = false;
      });
    } catch (e) {
      setState(() {
        _tasksError = 'Failed to load tasks.';
        _tasksLoading = false;
      });
    }
  }

  Future<void> _onRefundTap(Map<String, dynamic> task) async {
    final paymentStatus = (task['paymentStatus'] as String?) ?? 'unpaid';
    final refundStatus = (task['refundStatus'] as String?) ?? 'none';

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Refund Options',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                if (paymentStatus == 'held' &&
                    (refundStatus == 'none' || refundStatus.isEmpty))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.reply_outlined),
                    title: const Text('Request Refund'),
                    onTap: () => Navigator.pop(ctx, 'request'),
                  ),
                if (refundStatus == 'requested')
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.published_with_changes_outlined),
                    title: const Text('Process Refund'),
                    onTap: () => Navigator.pop(ctx, 'process'),
                  ),
                if (refundStatus == 'refunded')
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Refund already completed'),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (action == null) return;

    try {
      if (action == 'request') {
        await _paymentService.requestRefund(
          requestId: task['id'] as String,
          reason: 'Requested by worker from history',
        );
      } else if (action == 'process') {
        await _paymentService.processRefund(requestId: task['id'] as String);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'request' ? 'Refund requested.' : 'Refund processed.',
          ),
        ),
      );
      await _fetchCompletedTasks();
      await _fetchEarnings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Refund update failed: $e')),
      );
    }
  }

  String _refundActionLabel(String paymentStatus, String refundStatus) {
    if (refundStatus == 'requested') {
      return 'Process Refund';
    }
    if (refundStatus == 'refunded') {
      return 'Refunded';
    }
    if (paymentStatus == 'held' || paymentStatus == 'released') {
      return 'Request Refund';
    }
    return 'Refund Unavailable';
  }

  Future<void> _openEarningDetails(Map<String, dynamic> tx) async {
    final requestId = tx['requestId'] as String?;
    final paymentStatus = (tx['paymentStatus'] as String?) ?? 'unknown';
    final refundStatus = (tx['refundStatus'] as String?) ?? 'none';
    final actionLabel = _refundActionLabel(paymentStatus, refundStatus);

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['taskName'] as String? ?? 'Activity',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Amount: Rs ${(tx['amount'] as double).toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF9080B8)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Payment: $paymentStatus',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF9080B8)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Refund: $refundStatus',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF9080B8)),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: actionLabel == 'Refunded' ||
                            actionLabel == 'Refund Unavailable'
                        ? null
                        : () {
                            Navigator.pop(ctx, actionLabel);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C4DCC),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(actionLabel),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;

    if (requestId == null || requestId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refund is unavailable for this record.')),
      );
      return;
    }

    try {
      if (selected == 'Request Refund') {
        await _paymentService.requestRefund(
          requestId: requestId,
          reason: 'Requested by worker from earnings history',
        );
      } else if (selected == 'Process Refund') {
        await _paymentService.processRefund(requestId: requestId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            selected == 'Request Refund' ? 'Refund requested.' : 'Refund processed.',
          ),
        ),
      );
      await _fetchEarnings();
      await _fetchCompletedTasks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Refund update failed: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEDE5FF)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: Color(0xFF2D1B5E),
            ),
          ),
        ),
        title: const Text(
          'History',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF222222),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EAFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C4DCC).withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: const Color(0xFF2D1B5E),
                unselectedLabelColor: const Color(0xFF9080B8),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Earnings History'),
                  Tab(text: 'Completed Works'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Earnings History ──
          _earningsLoading
              ? const _LoadingView()
              : _earningsError.isNotEmpty
              ? _ErrorView(message: _earningsError, onRetry: _fetchEarnings)
              : _earnings.isEmpty
              ? const _EmptyView(
                  icon: '💰',
                  message: 'No earnings history yet',
                  sub: 'Your payment records will appear here',
                )
              : RefreshIndicator(
                  color: const Color(0xFF7C4DCC),
                  onRefresh: _fetchEarnings,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      // Summary banner
                      _EarningsSummaryBanner(earnings: _earnings),
                      const SizedBox(height: 16),
                      // List
                      ..._earnings.asMap().entries.map((entry) {
                        final i = entry.key;
                        final tx = entry.value;
                        // Date separator
                        final showSeparator =
                            i == 0 ||
                            !_isSameMonth(
                              (_earnings[i - 1]['date'] as DateTime),
                              tx['date'] as DateTime,
                            );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showSeparator)
                              _MonthSeparator(date: tx['date'] as DateTime),
                            _EarningsItem(
                              tx: tx,
                              formatDate: _formatDate,
                              onTap: () => _openEarningDetails(tx),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),

          // ── Tab 2: Completed Works ──
          _tasksLoading
              ? const _LoadingView()
              : _tasksError.isNotEmpty
              ? _ErrorView(message: _tasksError, onRetry: _fetchCompletedTasks)
              : _tasks.isEmpty
              ? const _EmptyView(
                  icon: '✅',
                  message: 'No completed works yet',
                  sub: 'Your finished tasks will appear here',
                )
              : RefreshIndicator(
                  color: const Color(0xFF7C4DCC),
                  onRefresh: _fetchCompletedTasks,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      // Summary banner
                      _TasksSummaryBanner(tasks: _tasks),
                      const SizedBox(height: 16),
                      ..._tasks.asMap().entries.map((entry) {
                        final i = entry.key;
                        final task = entry.value;
                        final showSeparator =
                            i == 0 ||
                            !_isSameMonth(
                              (_tasks[i - 1]['date'] as DateTime),
                              task['date'] as DateTime,
                            );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showSeparator)
                              _MonthSeparator(date: task['date'] as DateTime),
                            _TaskItem(
                              task: task,
                              formatDate: _formatDate,
                              onRefundTap: () => _onRefundTap(task),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
}

// ─────────────────────────────────────────
// Earnings Summary Banner
// ─────────────────────────────────────────
class _EarningsSummaryBanner extends StatelessWidget {
  final List<Map<String, dynamic>> earnings;
  const _EarningsSummaryBanner({required this.earnings});

  @override
  Widget build(BuildContext context) {
    final total = earnings.fold<double>(
      0,
      (sum, e) => sum + (e['amount'] as double),
    );
    final now = DateTime.now();
    final thisMonth = earnings
        .where((e) {
          final d = e['date'] as DateTime;
          return d.year == now.year && d.month == now.month;
        })
        .fold<double>(0, (sum, e) => sum + (e['amount'] as double));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A2D8F), Color(0xFF7C4DCC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C4DCC).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Earned',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs ${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 44,
            color: Colors.white24,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This Month',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs ${thisMonth.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                const Text(
                  'Txns',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
                Text(
                  '${earnings.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
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

// ─────────────────────────────────────────
// Tasks Summary Banner
// ─────────────────────────────────────────
class _TasksSummaryBanner extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;
  const _TasksSummaryBanner({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final totalPay = tasks.fold<double>(
      0,
      (sum, t) => sum + (t['amount'] as double),
    );
    final now = DateTime.now();
    final thisMonth = tasks.where((t) {
      final d = t['date'] as DateTime;
      return d.year == now.year && d.month == now.month;
    }).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A7A4A), Color(0xFF3ECF6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3ECF6A).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Works',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tasks.length} Tasks',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 44,
            color: Colors.white24,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This Month',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$thisMonth Tasks',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                const Text(
                  'Earned',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
                Text(
                  totalPay >= 1000
                      ? 'Rs ${(totalPay / 1000).toStringAsFixed(1)}K'
                      : 'Rs ${totalPay.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
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

// ─────────────────────────────────────────
// Month Separator
// ─────────────────────────────────────────
class _MonthSeparator extends StatelessWidget {
  final DateTime date;
  const _MonthSeparator({required this.date});

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Text(
            '${_months[date.month - 1]} ${date.year}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9080B8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: const Color(0xFFEDE5FF))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Earnings Item
// ─────────────────────────────────────────
class _EarningsItem extends StatelessWidget {
  final Map<String, dynamic> tx;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;

  const _EarningsItem({
    required this.tx,
    required this.formatDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = tx['date'] as DateTime;
    final amount = tx['amount'] as double;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F5FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDE5FF)),
        ),
        child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFD4F7E1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('💰', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['taskName'] as String,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D1B5E),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 11,
                      color: Color(0xFF9080B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatDate(date),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF9080B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+Rs ${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3ECF6A),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4F7E1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Paid',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A8A44),
                  ),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Task Item
// ─────────────────────────────────────────
class _TaskItem extends StatelessWidget {
  final Map<String, dynamic> task;
  final String Function(DateTime) formatDate;
  final VoidCallback onRefundTap;

  const _TaskItem({
    required this.task,
    required this.formatDate,
    required this.onRefundTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = task['date'] as DateTime;
    final amount = task['amount'] as double;
    final location = task['location'] as String;
    final description = task['description'] as String;
    final status = (task['status'] as String?) ?? 'completed';
    final paymentStatus = (task['paymentStatus'] as String?) ?? 'unpaid';
    final refundStatus = (task['refundStatus'] as String?) ?? 'none';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDE5FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE5FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('✅', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['taskName'] as String,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D1B5E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 11,
                          color: Color(0xFF9080B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatDate(date),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF9080B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (amount > 0)
                    Text(
                      'Rs ${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D1B5E),
                      ),
                    ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE5FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7C4DCC),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Payment: $paymentStatus',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9080B8),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Refund: $refundStatus',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9080B8),
                ),
              ),
              const Spacer(),
              if ((paymentStatus == 'held' &&
                      (refundStatus == 'none' || refundStatus.isEmpty)) ||
                  refundStatus == 'requested')
                TextButton.icon(
                  onPressed: onRefundTap,
                  icon: const Icon(Icons.reply, size: 14),
                  label: Text(
                    refundStatus == 'requested' ? 'Process' : 'Refund',
                    style: const TextStyle(fontSize: 11),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF7C4DCC),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          // Location row
          if (location.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: const Color(0xFFEDE5FF)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 13,
                  color: Color(0xFF9080B8),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9080B8),
                    ),
                  ),
                ),
              ],
            ),
          ],
          // Description row
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.notes_outlined,
                  size: 13,
                  color: Color(0xFF9080B8),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9080B8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Loading View
// ─────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF7C4DCC)),
    );
  }
}

// ─────────────────────────────────────────
// Error View
// ─────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: Color(0xFF9080B8)),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE5FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7C4DCC),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Empty View
// ─────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  final String icon;
  final String message;
  final String sub;
  const _EmptyView({
    required this.icon,
    required this.message,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 14),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D1B5E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9080B8)),
          ),
        ],
      ),
    );
  }
}
