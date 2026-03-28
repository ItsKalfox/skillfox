// category_b_customer_quotation_screen.dart
// Category B — Customer sees the worker's price quotation, accepts and pays.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../category_a/review_screen.dart';

class _C {
  static const gradA = Color(0xFF10B981);
  static const gradB = Color(0xFF059669);
  static const accent = Color(0xFF10B981);
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

class CategoryBCustomerQuotationScreen extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const CategoryBCustomerQuotationScreen({
    super.key,
    required this.requestId,
    required this.requestData,
  });

  @override
  State<CategoryBCustomerQuotationScreen> createState() =>
      _CategoryBCustomerQuotationScreenState();
}

class _CategoryBCustomerQuotationScreenState
    extends State<CategoryBCustomerQuotationScreen> {
  late Map<String, dynamic> _data;
  bool _actionLoading = false;
  bool _paid = false;

  @override
  void initState() {
    super.initState();
    _data = {...widget.requestData, 'id': widget.requestId};
    // real-time listener so status updates arrive immediately
    FirebaseFirestore.instance
        .collection('requests')
        .doc(widget.requestId)
        .snapshots()
        .listen((snap) {
          if (!snap.exists || !mounted) return;
          final d = Map<String, dynamic>.from(snap.data()!);
          d['id'] = snap.id;
          setState(() {
            _data = d;
            if ((d['bPaymentStatus'] as String?) == 'paid') _paid = true;
          });
        });
  }

  // ── computed fields ──────────────────────────────────────────────────────────
  String get _pricingType => _data['bPricingType'] as String? ?? 'fixed';
  double get _rate => (_data['bRate'] as num?)?.toDouble() ?? 0;
  double get _hours => (_data['bEstimatedHours'] as num?)?.toDouble() ?? 0;
  double get _total => (_data['bTotalQuoted'] as num?)?.toDouble() ?? 0;
  String get _workDesc => _data['bWorkDescription'] as String? ?? '';
  String get _schedule => _data['bSchedule'] as String? ?? '';
  String get _notes => _data['bNotes'] as String? ?? '';
  String get _workerName => _data['workerName'] as String? ?? 'Worker';
  String get _category => _data['category'] as String? ?? '';
  String get _quotationStatus =>
      _data['quotationStatus'] as String? ?? 'pending';

  String _fmt(num n) {
    final s = n.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  // ── actions ──────────────────────────────────────────────────────────────────
  Future<void> _acceptAndPay() async {
    setState(() => _actionLoading = true);
    try {
      final amount = _total;
      final commission = (amount * 0.10).roundToDouble();
      final netAmount = amount - commission;

      // Write to payments collection
      await FirebaseFirestore.instance.collection('payments').add({
        'requestId': widget.requestId,
        'amount': amount,
        'commission': commission,
        'netAmount': netAmount,
        'status': 'completed',
        'service': _workerName,
        'workerId': _data['workerId'] ?? '',
        'workerName': _data['workerName'] ?? '',
        'customerId': _data['customerId'] ?? '',
        'customerName': _data['customerName'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update request status
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
            'quotationStatus': 'accepted',
            'quotationAcceptedAt': FieldValue.serverTimestamp(),
            'bPaymentStatus': 'paid',
            'bPaidAt': FieldValue.serverTimestamp(),
            'bTotalPaid': _total,
            'status': 'inprogress',
          });
      if (mounted)
        setState(() {
          _paid = true;
          _actionLoading = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() => _actionLoading = false);
        _snack('Error: $e', isError: true);
      }
    }
  }

  Future<void> _declineQuotation() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Decline Quotation',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Are you sure you want to decline this price?'),
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
      if (!mounted) return;
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
                const Text(
                  'Price Quotation',
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
                    'CATEGORY B',
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
              child: _paid ? _buildPaidState() : _buildQuotationDetails(),
            ),
          ),

          // bottom bar
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
              16,
              14,
              16,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: _paid
                ? _paidBottomBar()
                : (_quotationStatus == 'pending'
                      ? _actionButtons()
                      : _declinedBar()),
          ),
        ],
      ),
    );
  }

  // ── quotation detail view ────────────────────────────────────────────────────
  Widget _buildQuotationDetails() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 8),

      // worker card
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
                gradient: LinearGradient(colors: [_C.gradA, _C.gradB]),
              ),
              child: Center(
                child: Text(
                  _workerName.isNotEmpty ? _workerName[0].toUpperCase() : 'W',
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
                    style: const TextStyle(fontSize: 12, color: _C.txt2),
                  ),
                ],
              ),
            ),
            _statusChip(_quotationStatus),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // pricing summary card
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
            const Row(
              children: [
                Icon(Icons.receipt_long_outlined, size: 14, color: _C.green),
                SizedBox(width: 6),
                Text(
                  'PRICING BREAKDOWN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _C.muted,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_pricingType == 'hourly') ...[
              _pRow('Rate per Hour', 'LKR ${_fmt(_rate)}/hr'),
              _pRow('Estimated Hours', '${_hours.toStringAsFixed(1)} hrs'),
              const Divider(height: 16, color: _C.cardBdr),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    _pricingType == 'hourly' ? 'Total Estimate' : 'Fixed Price',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _C.txt1,
                    ),
                  ),
                ),
                Text(
                  'LKR ${_fmt(_total)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _C.accent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // work details card
      _detailCard('WORK DETAILS', [
        if (_workDesc.isNotEmpty) _detailBlock('Work Description', _workDesc),
        if (_schedule.isNotEmpty) _detailBlock('Scheduled For', _schedule),
        if (_notes.isNotEmpty) _detailBlock('Additional Notes', _notes),
      ]),
      const SizedBox(height: 12),

      if (_quotationStatus == 'pending')
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFED7AA), width: 0.5),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: _C.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Accepting this quotation will immediately confirm payment. Please review before proceeding.',
                  style: TextStyle(fontSize: 10, color: _C.orange, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: 80),
    ],
  );

  // ── paid confirmation view ───────────────────────────────────────────────────
  Widget _buildPaidState() => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const SizedBox(height: 32),
      Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [_C.green, _C.greenDk]),
          boxShadow: [
            BoxShadow(
              color: _C.green.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.check_circle_rounded,
          color: Colors.white,
          size: 50,
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'Payment Confirmed!',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _C.green,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Your payment to $_workerName is confirmed.\nThe worker will be on their way!',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: _C.txt2, height: 1.6),
      ),
      const SizedBox(height: 24),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt_long_outlined, size: 14, color: _C.green),
                SizedBox(width: 6),
                Text(
                  'PAYMENT RECEIPT',
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
            _pRow('Worker', _workerName),
            _pRow(
              'Job Type',
              _pricingType == 'hourly' ? 'Hourly Rate' : 'Fixed Price',
            ),
            if (_pricingType == 'hourly') ...[
              _pRow('Rate', 'LKR ${_fmt(_rate)}/hr'),
              _pRow('Hours', '${_hours.toStringAsFixed(1)} hrs'),
            ],
            const Divider(height: 16, color: _C.cardBdr, thickness: 1.5),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total Paid',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _C.txt1,
                    ),
                  ),
                ),
                Text(
                  'LKR ${_fmt(_total)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _C.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBBF7D0), width: 0.5),
        ),
        child: const Row(
          children: [
            Icon(Icons.hourglass_top_rounded, size: 14, color: _C.green),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'The worker will mark the job as done when finished.',
                style: TextStyle(fontSize: 11, color: _C.green, height: 1.5),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
    ],
  );

  // ── bottom bar widgets ───────────────────────────────────────────────────────
  Widget _actionButtons() => Column(
    children: [
      GestureDetector(
        onTap: _actionLoading ? null : _acceptAndPay,
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
                        Icons.check_circle_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Accept & Pay  ·  LKR ${_fmt(_total)}',
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
        onTap: _actionLoading ? null : _declineQuotation,
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

  Widget _paidBottomBar() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: BoxDecoration(
      color: const Color(0xFFECFDF5),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFBBF7D0)),
    ),
    child: const Center(
      child: Text(
        '✓ Paid — Waiting for worker to complete job',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _C.green,
        ),
      ),
    ),
  );

  Widget _declinedBar() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFFECACA)),
    ),
    child: const Center(
      child: Text(
        '✗ Quotation Declined',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _C.red,
        ),
      ),
    ),
  );

  // ── reusable widgets ─────────────────────────────────────────────────────────
  Widget _statusChip(String status) {
    Color bg;
    Color text;
    String label;
    switch (status) {
      case 'accepted':
        bg = const Color(0xFFECFDF5);
        text = _C.green;
        label = 'Accepted';
        break;
      case 'declined':
        bg = const Color(0xFFFEF2F2);
        text = _C.red;
        label = 'Declined';
        break;
      default:
        bg = const Color(0xFFEFF6FF);
        text = _C.blue;
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }

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
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: _C.muted)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13, color: _C.txt1, height: 1.5),
        ),
      ],
    ),
  );

  Widget _pRow(String label, String value) => Padding(
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
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _C.txt1,
          ),
        ),
      ],
    ),
  );
}
