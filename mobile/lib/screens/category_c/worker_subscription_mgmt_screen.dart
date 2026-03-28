// category_c_worker_subscription_mgmt_screen.dart
// Category C — Worker manages their active subscription(s).
// Tracks sessions delivered, marks each session complete, and sees payment history.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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

class CategoryCWorkerSubscriptionMgmtScreen extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const CategoryCWorkerSubscriptionMgmtScreen({
    super.key,
    required this.requestId,
    required this.requestData,
  });

  @override
  State<CategoryCWorkerSubscriptionMgmtScreen> createState() =>
      _CategoryCWorkerSubscriptionMgmtScreenState();
}

class _CategoryCWorkerSubscriptionMgmtScreenState
    extends State<CategoryCWorkerSubscriptionMgmtScreen> {
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

  String get _customerName => _data['customerName'] as String? ?? 'Customer';
  String get _category => _data['category'] as String? ?? '';
  double get _price => (_data['cMonthlyPrice'] as num?)?.toDouble() ?? 0;
  String get _billingCycle => _data['cBillingCycle'] as String? ?? 'monthly';
  int get _sessionsTotal => (_data['cSessionsPerCycle'] as num?)?.toInt() ?? 0;
  int get _sessionsDone =>
      (_data['cSessionsDoneThisCycle'] as num?)?.toInt() ?? 0;
  int get _monthsPaid => (_data['cMonthsPaid'] as num?)?.toInt() ?? 0;
  String get _schedule => _data['cSchedule'] as String? ?? '';
  String get _subStatus =>
      _data['cSubscriptionStatus'] as String? ?? 'inactive';

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

  double get _progressFraction => _sessionsTotal > 0
      ? (_sessionsDone / _sessionsTotal).clamp(0.0, 1.0)
      : 0.0;

  String _fmt(num n) {
    final s = n.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  Future<void> _markSessionDone() async {
    setState(() => _actionLoading = true);
    try {
      final newDone = _sessionsDone + 1;
      final Map<String, dynamic> updates = {
        'cSessionsDoneThisCycle': newDone,
        'cLastSessionAt': FieldValue.serverTimestamp(),
        'cSessionLog': FieldValue.arrayUnion([
          {'doneAt': DateTime.now().toIso8601String(), 'session': newDone},
        ]),
      };
      // If this cycle is complete, reset counter for next cycle
      if (_sessionsTotal > 0 && newDone >= _sessionsTotal) {
        updates['cSessionsDoneThisCycle'] = 0;
        updates['cCyclesCompleted'] = FieldValue.increment(1);
      }
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update(updates);
    } catch (e) {
      if (mounted) _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _endSubscription() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'End Subscription',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Mark this subscription as complete? This will end the service.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'End Service',
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
            'cSubscriptionStatus': 'ended',
            'status': 'completed',
            'cEndedAt': FieldValue.serverTimestamp(),
          });
      if (mounted) {
        // Worker just pops back — the customer will see the status change
        // and get the "Leave a Review" button on their screen.
        Navigator.pop(context);
      }
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

  @override
  Widget build(BuildContext context) {
    final isCancelled = _subStatus == 'cancelled' || _subStatus == 'ended';

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          // header
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Manage Subscription',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$_customerName · $_category',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                _subStatusBadge(),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                children: [
                  // earnings summary
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_C.gradA, _C.gradB],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TOTAL EARNED',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white60,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'LKR ${_fmt(_price * _monthsPaid)}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_monthsPaid payment${_monthsPaid == 1 ? '' : 's'} received',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'LKR',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                _fmt(_price),
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '/${_billingCycle == 'weekly' ? 'wk' : 'mo'}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // session progress card
                  if (_sessionsTotal > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _C.cardBdr, width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.event_available_rounded,
                                size: 14,
                                color: _C.accent,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'SESSIONS THIS CYCLE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _C.muted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$_sessionsDone / $_sessionsTotal',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _C.accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: _progressFraction,
                              minHeight: 10,
                              backgroundColor: const Color(0xFFF3EEFF),
                              valueColor: const AlwaysStoppedAnimation(
                                _C.accent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_sessionsTotal > 0)
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: List.generate(_sessionsTotal, (i) {
                                final done = i < _sessionsDone;
                                return Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: done
                                        ? _C.accent
                                        : const Color(0xFFF3EEFF),
                                    border: Border.all(
                                      color: done ? _C.accent : _C.cardBdr,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: done
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 13,
                                          color: Colors.white,
                                        )
                                      : Center(
                                          child: Text(
                                            '${i + 1}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: _C.muted,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                );
                              }),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // subscription info
                  _infoCard([
                    _dRow(
                      Icons.person_outline_rounded,
                      'Customer',
                      _customerName,
                    ),
                    _dRow(
                      Icons.repeat_rounded,
                      'Billing',
                      '${_billingCycle == 'weekly' ? 'Weekly' : 'Monthly'} · LKR ${_fmt(_price)}',
                    ),
                    if (_schedule.isNotEmpty)
                      _dRow(Icons.schedule_rounded, 'Schedule', _schedule),
                    _dRow(
                      Icons.calendar_today_outlined,
                      'Next Billing',
                      _nextBillingDate,
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // payment history
                  if ((_data['cPaymentHistory'] as List?)?.isNotEmpty == true)
                    _buildPaymentHistory(),
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
              MediaQuery.of(context).padding.bottom + 20,
            ),
            child: isCancelled
                ? _infoBar(
                    icon: Icons.info_outline_rounded,
                    text: 'This subscription has been cancelled or ended.',
                    color: _C.red,
                    bg: const Color(0xFFFEF2F2),
                    border: const Color(0xFFFECACA),
                  )
                : _actionBar(),
          ),
        ],
      ),
    );
  }

  Widget _actionBar() => Column(
    children: [
      GestureDetector(
        onTap: _actionLoading ? null : _markSessionDone,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _actionLoading ? 0.6 : 1.0,
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
                          Icons.event_available_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _sessionsTotal > 0
                              ? 'Mark Session Done  (${_sessionsDone + 1}/$_sessionsTotal)'
                              : 'Mark Session Done',
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
      ),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: _actionLoading ? null : _endSubscription,
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
              'End Subscription',
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
                            'Received $dateStr',
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

  Widget _subStatusBadge() {
    Color color;
    String label;
    switch (_subStatus) {
      case 'active':
        color = const Color(0xFF10B981);
        label = 'Active';
        break;
      case 'cancelled':
        color = _C.red;
        label = 'Cancelled';
        break;
      case 'ended':
        color = _C.muted;
        label = 'Ended';
        break;
      default:
        color = _C.orange;
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _C.cardBdr, width: 0.5),
    ),
    child: Column(children: children),
  );

  Widget _dRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 14, color: _C.muted),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 11, color: _C.txt2)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _C.txt1,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _infoBar({
    required IconData icon,
    required String text,
    required Color color,
    required Color bg,
    required Color border,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: border, width: 0.5),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
}
