// category_c_customer_subscription_screen.dart
// Category C — Customer views, subscribes, and manages their recurring payment.
// Shows upcoming billing date, payment history, and cancel option.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../category_a/review_screen.dart';

class _C {
  static const gradA = Color(0xFF8B5CF6);
  static const gradB = Color(0xFF6C56F0);
  static const accent = Color(0xFF8B5CF6);
  static const bg = Color(0xFFF4F6FA);
  static const cardBdr = Color(0xFFE2E6F0);
  static const txt1 = Color(0xFF111111);
  static const txt2 = Color(0xFF888888);
  static const muted = Color(0xFFA0A4B0);
  static const green = Color(0xFF16A34A);
  static const greenDk = Color(0xFF1E8449);
  static const red = Color(0xFFEF4444);
  static const orange = Color(0xFFEA580C);
  static const blue = Color(0xFF2563EB);
}

class CategoryCCustomerSubscriptionScreen extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const CategoryCCustomerSubscriptionScreen({
    super.key,
    required this.requestId,
    required this.requestData,
  });

  @override
  State<CategoryCCustomerSubscriptionScreen> createState() =>
      _CategoryCCustomerSubscriptionScreenState();
}

class _CategoryCCustomerSubscriptionScreenState
    extends State<CategoryCCustomerSubscriptionScreen> {
  late Map<String, dynamic> _data;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _data = {...widget.requestData, 'id': widget.requestId};
    FirebaseFirestore.instance
        .collection('requests')
        .doc(widget.requestId)
        .snapshots()
        .listen((snap) {
          if (!snap.exists || !mounted) return;
          final d = Map<String, dynamic>.from(snap.data()!);
          d['id'] = snap.id;
          setState(() => _data = d);
        });
  }

  // ── computed ────────────────────────────────────────────────────────────────
  String get _workerName => _data['workerName'] as String? ?? 'Worker';
  String get _category => _data['category'] as String? ?? '';
  double get _price => (_data['cMonthlyPrice'] as num?)?.toDouble() ?? 0;
  String get _billingCycle => _data['cBillingCycle'] as String? ?? 'monthly';
  int get _sessions => (_data['cSessionsPerCycle'] as num?)?.toInt() ?? 0;
  String get _duration => _data['cSessionDuration'] as String? ?? '';
  String get _schedule => _data['cSchedule'] as String? ?? '';
  String get _desc => _data['cServiceDescription'] as String? ?? '';
  String get _notes => _data['cNotes'] as String? ?? '';
  String get _qStatus => _data['quotationStatus'] as String? ?? 'pending';
  String get _subStatus =>
      _data['cSubscriptionStatus'] as String? ?? 'inactive';
  int get _monthsPaid => (_data['cMonthsPaid'] as num?)?.toInt() ?? 0;

  String _fmt(num n) {
    final s = n.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  String get _nextBillingDate {
    final raw = _data['cNextBillingDate'];
    if (raw == null) return '—';
    try {
      return DateFormat(
        'dd MMM yyyy',
      ).format((raw as dynamic).toDate() as DateTime);
    } catch (_) {
      return '—';
    }
  }

  // ── actions ──────────────────────────────────────────────────────────────────
  Future<void> _subscribe() async {
    setState(() => _actionLoading = true);
    try {
      final now = DateTime.now();
      final DateTime nextBilling = _billingCycle == 'weekly'
          ? now.add(const Duration(days: 7))
          : DateTime(now.year, now.month + 1, now.day);

      final amount = _price;
      final commission = (amount * 0.10).roundToDouble();
      final netAmount = amount - commission;

      // Write to payments collection
      await FirebaseFirestore.instance.collection('payments').add({
        'requestId': widget.requestId,
        'amount': amount,
        'commission': commission,
        'netAmount': netAmount,
        'status': 'completed',
        'service': _category,
        'workerId': _data['workerId'] ?? '',
        'workerName': _workerName,
        'customerId': _data['customerId'] ?? '',
        'customerName': _data['customerName'] ?? '',
        'billingCycle': _billingCycle,
        'cycleNumber': 1,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update request status
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
            'quotationStatus': 'accepted',
            'quotationAcceptedAt': FieldValue.serverTimestamp(),
            'cSubscriptionStatus': 'active',
            'cStartDate': FieldValue.serverTimestamp(),
            'cNextBillingDate': Timestamp.fromDate(nextBilling),
            'cMonthsPaid': 1,
            'status': 'inprogress',
            'cPaymentHistory': FieldValue.arrayUnion([
              {
                'amount': _price,
                'paidAt': now.toIso8601String(),
                'cycle': 1,
                'billedFor': DateFormat('MMMM yyyy').format(now),
              },
            ]),
          });
    } catch (e) {
      if (mounted) _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _payNextCycle() async {
    setState(() => _actionLoading = true);
    try {
      final now = DateTime.now();
      final DateTime nextBilling = _billingCycle == 'weekly'
          ? now.add(const Duration(days: 7))
          : DateTime(now.year, now.month + 1, now.day);

      final amount = _price;
      final commission = (amount * 0.10).roundToDouble();
      final netAmount = amount - commission;
      final cycleNum = _monthsPaid + 1;

      // Write to payments collection
      await FirebaseFirestore.instance.collection('payments').add({
        'requestId': widget.requestId,
        'amount': amount,
        'commission': commission,
        'netAmount': netAmount,
        'status': 'completed',
        'service': _category,
        'workerId': _data['workerId'] ?? '',
        'workerName': _workerName,
        'customerId': _data['customerId'] ?? '',
        'customerName': _data['customerName'] ?? '',
        'billingCycle': _billingCycle,
        'cycleNumber': cycleNum,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update request
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
            'cNextBillingDate': Timestamp.fromDate(nextBilling),
            'cMonthsPaid': FieldValue.increment(1),
            'cPaymentHistory': FieldValue.arrayUnion([
              {
                'amount': _price,
                'paidAt': now.toIso8601String(),
                'cycle': cycleNum,
                'billedFor': DateFormat('MMMM yyyy').format(now),
              },
            ]),
          });
    } catch (e) {
      if (mounted) _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _cancelSubscription() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Cancel Subscription',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to cancel this subscription? The worker will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Keep It'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _C.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
            'cSubscriptionStatus': 'cancelled',
            'cCancelledAt': FieldValue.serverTimestamp(),
            'status': 'completed',
          });
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReviewScreen(
              requestId: widget.requestId,
              requestData: _data,
              isWorker: false,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _actionLoading = false);
        _snack('Error: $e', isError: true);
      }
    }
  }

  Future<void> _declineProposal() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Decline Proposal',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Are you sure you want to decline this proposal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _C.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Yes, Decline',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
            'quotationStatus': 'declined',
            'quotationDeclinedAt': FieldValue.serverTimestamp(),
            'status': 'quotation_declined',
          });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _actionLoading = false);
        _snack('Error: $e', isError: true);
      }
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? _C.red : _C.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isActive = _subStatus == 'active';

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_C.gradA, _C.gradB]),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 4,
              bottom: 16,
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
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Subscription Plan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'CATEGORY C',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  // worker + status card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _C.cardBdr, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [_C.gradA, _C.gradB],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _workerName.isNotEmpty
                                  ? _workerName[0].toUpperCase()
                                  : 'W',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _workerName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _C.txt1,
                                ),
                              ),
                              Text(
                                _category,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _C.txt2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _statusChip(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── pricing card (big display)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_C.gradA, _C.gradB],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.repeat_rounded,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _billingCycle == 'weekly'
                                  ? 'WEEKLY SUBSCRIPTION'
                                  : 'MONTHLY SUBSCRIPTION',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                'LKR ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              _fmt(_price),
                              style: const TextStyle(
                                fontSize: 44,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 28),
                              child: Text(
                                '/${_billingCycle == 'weekly' ? 'wk' : 'mo'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_sessions > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            '$_sessions sessions · ${_fmt(_price / _sessions)}/session',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                        if (isActive) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 12,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Next billing: $_nextBillingDate',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── plan details card
                  _detailCard('PLAN DETAILS', [
                    if (_desc.isNotEmpty) _detailBlock('Service', _desc),
                    if (_schedule.isNotEmpty)
                      _detailBlock('Schedule', _schedule),
                    if (_duration.isNotEmpty)
                      _detailBlock('Session Duration', _duration),
                    if (_sessions > 0)
                      _detailBlock(
                        'Sessions / ${_billingCycle == 'weekly' ? 'Week' : 'Month'}',
                        '$_sessions',
                      ),
                    if (_notes.isNotEmpty) _detailBlock('Notes', _notes),
                  ]),
                  const SizedBox(height: 12),

                  // ── active subscription stats
                  if (isActive) ...[
                    _detailCard('SUBSCRIPTION STATUS', [
                      _statRow('Status', 'Active ✓', color: _C.green),
                      _statRow('Total Payments Made', '$_monthsPaid'),
                      _statRow(
                        'Total Paid',
                        'LKR ${_fmt(_price * _monthsPaid)}',
                        color: _C.accent,
                      ),
                      _statRow('Next Billing', _nextBillingDate),
                    ]),
                    const SizedBox(height: 12),
                  ],

                  // ── payment history
                  if ((_data['cPaymentHistory'] as List?)?.isNotEmpty ==
                      true) ...[
                    _buildPaymentHistory(),
                    const SizedBox(height: 12),
                  ],

                  // info banner if pending
                  if (_qStatus == 'pending')
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFED7AA),
                          width: 0.5,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: _C.orange,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Subscribe to confirm this recurring service. First payment is taken immediately.',
                              style: TextStyle(
                                fontSize: 10,
                                color: _C.orange,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
              16,
              14,
              16,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: _bottomContent(),
          ),
        ],
      ),
    );
  }

  Widget _bottomContent() {
    // pending proposal
    if (_qStatus == 'pending') {
      return Column(
        children: [
          GestureDetector(
            onTap: _actionLoading ? null : _subscribe,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_C.gradA, _C.gradB]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: _actionLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.repeat_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Subscribe  ·  LKR ${_fmt(_price)}/${_billingCycle == 'weekly' ? 'wk' : 'mo'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _actionLoading ? null : _declineProposal,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _C.red.withOpacity(0.4), width: 1.5),
              ),
              child: const Center(
                child: Text(
                  'Decline',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _C.red,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // active subscription — show pay next cycle + cancel
    if (_subStatus == 'active') {
      return Column(
        children: [
          GestureDetector(
            onTap: _actionLoading ? null : _payNextCycle,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_C.gradA, _C.gradB]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: _actionLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.payment_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pay Next Cycle  ·  LKR ${_fmt(_price)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _actionLoading ? null : _cancelSubscription,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _C.red.withOpacity(0.4), width: 1.5),
              ),
              child: const Center(
                child: Text(
                  'Cancel Subscription',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _C.red,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // cancelled
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: const Center(
        child: Text(
          'Subscription Cancelled',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _C.red,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentHistory() {
    final history =
        (_data['cPaymentHistory'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    history.sort(
      (a, b) => (b['cycle'] as int? ?? 0).compareTo(a['cycle'] as int? ?? 0),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.cardBdr, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, size: 14, color: _C.accent),
              SizedBox(width: 6),
              Text(
                'PAYMENT HISTORY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _C.muted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...history.take(5).map((p) {
            final amount = (p['amount'] as num?)?.toDouble() ?? 0;
            final billedFor = p['billedFor'] as String? ?? '';
            final cycle = p['cycle'] as int? ?? 0;
            String dateStr = '';
            try {
              dateStr = DateFormat(
                'dd MMM',
              ).format(DateTime.parse(p['paidAt'] as String));
            } catch (_) {}
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EEFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$cycle',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _C.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          billedFor,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _C.txt1,
                          ),
                        ),
                        if (dateStr.isNotEmpty)
                          Text(
                            'Paid $dateStr',
                            style: const TextStyle(
                              fontSize: 10,
                              color: _C.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    'LKR ${_fmt(amount)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _C.green,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── small helpers ─────────────────────────────────────────────────────────
  Widget _statusChip() {
    if (_subStatus == 'active') {
      return _chip('Active', _C.green, const Color(0xFFECFDF5));
    }
    if (_subStatus == 'cancelled') {
      return _chip('Cancelled', _C.red, const Color(0xFFFEF2F2));
    }
    return _chip('Pending', _C.blue, const Color(0xFFEFF6FF));
  }

  Widget _chip(String label, Color text, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: text),
    ),
  );

  Widget _detailCard(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _C.cardBdr, width: 0.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _C.muted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );

  Widget _detailBlock(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: _C.muted)),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 13, color: _C.txt1, height: 1.4),
        ),
      ],
    ),
  );

  Widget _statRow(String label, String value, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: _C.txt2),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color ?? _C.txt1,
          ),
        ),
      ],
    ),
  );
}
