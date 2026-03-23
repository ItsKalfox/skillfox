import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class _C {
  static const gradA   = Color(0xFF469FEF);
  static const gradB   = Color(0xFF6C56F0);
  static const accent  = Color(0xFF6C56F0);
  static const bg      = Color(0xFFF4F6FA);
  static const cardBdr = Color(0xFFE2E6F0);
  static const txt1    = Color(0xFF111111);
  static const txt2    = Color(0xFF888888);
  static const muted   = Color(0xFFA0A4B0);
  static const green   = Color(0xFF16A34A);
  static const greenDk = Color(0xFF1E8449);
  static const red     = Color(0xFFEF4444);
  static const orange  = Color(0xFFEA580C);
}

class QuotationPaymentScreen extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const QuotationPaymentScreen({
    super.key,
    required this.requestId,
    required this.requestData,
  });

  @override
  State<QuotationPaymentScreen> createState() => _QuotationPaymentScreenState();
}

class _QuotationPaymentScreenState extends State<QuotationPaymentScreen> {
  bool _loading = false;
  bool _paid    = false;

  double get _labourCost   => (widget.requestData['quotationLabourCost']   as num?)?.toDouble() ?? 0;
  double get _materialCost => (widget.requestData['quotationMaterialCost'] as num?)?.toDouble() ?? 0;
  double get _totalCost    => (widget.requestData['quotationTotalCost']    as num?)?.toDouble() ?? (_labourCost + _materialCost);
  String get _workerName   => widget.requestData['workerName']             as String? ?? 'Worker';
  String get _category     => widget.requestData['category']               as String? ?? '';
  String get _jobDesc      => widget.requestData['quotationJobDesc']       as String? ?? '';

  String _fmt(num n) {
    final s = n.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  Future<void> _confirmPayment() async {
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
        'quotationPaymentStatus': 'paid',
        'quotationPaidAt':        FieldValue.serverTimestamp(),
        'quotationTotalPaid':     _totalCost,
        'status':                 'quotation_paid',
      });
      if (mounted) setState(() { _loading = false; _paid = true; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: _C.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(children: [

        // ── Gradient Header ──────────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_C.gradA, _C.gradB])),
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 4,
              bottom: 16, left: 16, right: 16),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 14, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Quotation Payment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ),

        // ── Body ────────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _paid ? _buildPaidState() : _buildPaymentState(),
          ),
        ),

        // ── Bottom button ────────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(
              16, 14, 16, MediaQuery.of(context).padding.bottom + 20),
          child: _paid ? _buildPaidBottomBar() : _buildConfirmButton(),
        ),
      ]),
    );
  }

  // ── Before payment ─────────────────────────────────────────────────────────
  Widget _buildPaymentState() => Column(children: [
        const SizedBox(height: 8),

        // Amount circle
        Container(
          width: 150, height: 150,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_C.gradA, _C.gradB]),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Quotation Total',
                style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            const Text('LKR',
                style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
            Text(_fmt(_totalCost),
                style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          ]),
        ),

        const SizedBox(height: 24),

        // Info notice
        Container(
          width: double.infinity, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFED7AA), width: 0.5)),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded, size: 14, color: _C.orange),
            SizedBox(width: 8),
            Expanded(child: Text(
                'Complete payment via the agreed method, then press "Confirm Payment".',
                style: TextStyle(fontSize: 10, color: _C.orange, height: 1.5))),
          ]),
        ),

        const SizedBox(height: 16),

        // Quotation summary card
        Container(
          width: double.infinity, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _C.cardBdr, width: 0.5)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.receipt_long_outlined, size: 14, color: _C.gradA),
              SizedBox(width: 6),
              Text('QUOTATION SUMMARY',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _C.muted, letterSpacing: 0.5)),
            ]),
            const SizedBox(height: 14),
            _pRow('Worker',   _workerName, isText: true),
            _pRow('Category', _category,   isText: true),
            if (_jobDesc.isNotEmpty) _pRow('Job', _jobDesc, isText: true),
            const Divider(height: 20, color: _C.cardBdr, thickness: 1),
            _pRow('Labour Cost',   _fmt(_labourCost)),
            _pRow('Material Cost', _fmt(_materialCost)),
            const Divider(height: 20, color: _C.cardBdr, thickness: 1.5),
            Row(children: [
              const Expanded(child: Text('Total',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _C.txt1))),
              Text('LKR ${_fmt(_totalCost)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _C.accent)),
            ]),
          ]),
        ),
        // NOTE: Payment method card removed as requested
      ]);

  // ── After payment confirmed ────────────────────────────────────────────────
  Widget _buildPaidState() => Column(children: [
        const SizedBox(height: 32),

        // Success icon
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [_C.green, _C.greenDk]),
            boxShadow: [BoxShadow(
                color: _C.green.withOpacity(0.3),
                blurRadius: 20, spreadRadius: 2)],
          ),
          child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 50),
        ),

        const SizedBox(height: 24),

        const Text('Payment Confirmed!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _C.green)),
        const SizedBox(height: 8),
        const Text('Your payment has been confirmed.\nWaiting for the worker to mark the job as done.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _C.txt2, height: 1.6)),

        const SizedBox(height: 24),

        // Payment summary
        Container(
          width: double.infinity, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFBBF7D0), width: 1)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.receipt_long_outlined, size: 14, color: _C.green),
              SizedBox(width: 6),
              Text('PAYMENT SUMMARY',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _C.muted, letterSpacing: 0.5)),
            ]),
            const SizedBox(height: 14),
            _pRow('Worker',   _workerName, isText: true),
            _pRow('Category', _category,   isText: true),
            const Divider(height: 20, color: _C.cardBdr),
            _pRow('Labour Cost',   _fmt(_labourCost)),
            _pRow('Material Cost', _fmt(_materialCost)),
            const Divider(height: 16, color: _C.cardBdr, thickness: 1.5),
            Row(children: [
              const Expanded(child: Text('Total Paid',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _C.txt1))),
              Text('LKR ${_fmt(_totalCost)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _C.green)),
            ]),
          ]),
        ),

        const SizedBox(height: 16),

        // Waiting info bar
        Container(
          width: double.infinity, padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0), width: 0.5)),
          child: const Row(children: [
            Icon(Icons.hourglass_top_rounded, size: 14, color: _C.green),
            SizedBox(width: 10),
            Expanded(child: Text(
                'The worker will mark the job as done once everything is complete.',
                style: TextStyle(fontSize: 11, color: _C.green, height: 1.5))),
          ]),
        ),
      ]);

  Widget _buildConfirmButton() => GestureDetector(
        onTap: _loading ? null : _confirmPayment,
        child: Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_C.gradA, _C.gradB]),
              borderRadius: BorderRadius.circular(14)),
          child: Center(child: _loading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Confirm Payment',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                ])),
        ),
      );

  Widget _buildPaidBottomBar() => Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBBF7D0))),
        child: const Center(child: Text('✓ Payment Confirmed — Waiting for worker',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.green))),
      );

  Widget _pRow(String label, String value, {bool isText = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 100,
              child: Text(label, style: const TextStyle(fontSize: 11, color: _C.txt2))),
          Expanded(child: Text(value,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: isText ? FontWeight.w500 : FontWeight.w600,
                  color: _C.txt1))),
        ]),
      );
}
