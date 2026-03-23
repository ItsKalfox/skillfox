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
  static const orange  = Color(0xFFEA580C);
  static const red     = Color(0xFFEF4444);
}

class PaymentScreen extends StatefulWidget {
  final String requestId;
  final double totalAmount;
  final double inspectionFee;
  final double distanceFee;
  final double serviceFee;

  const PaymentScreen({
    super.key,
    required this.requestId,
    required this.totalAmount,
    required this.inspectionFee,
    required this.distanceFee,
    required this.serviceFee,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _loading = false;

  String _fmt(num n) {
    final s = n.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  Future<void> _completePayment() async {
    setState(() => _loading = true);
    try {
      // ── KEY CHANGE: status = 'inprogress' so worker sees "paid" stage ──
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
        'status':        'inprogress', // triggers stage 1 on worker screen
        'paymentStatus': 'paid',
        'paymentMethod': 'manual',
        'paidAt':        FieldValue.serverTimestamp(),
        'totalPaid':     widget.totalAmount,
      });
      if (mounted) Navigator.pop(context); // back to waiting_worker_screen
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
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

        // ── Header ──────────────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 4, bottom: 12, left: 16, right: 16),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(width: 32, height: 32,
                  decoration: const BoxDecoration(color: Color(0xFFF0F2F8), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Color(0xFF444444))),
            ),
            const SizedBox(width: 12),
            const Text('Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _C.txt1)),
          ]),
        ),

        // ── Body ────────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              const SizedBox(height: 16),

              // Amount circle
              Container(
                width: 140, height: 140,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFF27AE60), _C.greenDk]),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Total Due', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  const Text('LKR', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                  Text(_fmt(widget.totalAmount),
                      style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                ]),
              ),

              const SizedBox(height: 20),

              // Info notice
              Container(
                width: double.infinity, padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFED7AA), width: 0.5)),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: _C.orange), SizedBox(width: 8),
                  Expanded(child: Text('Complete your payment via the agreed method, then press "Confirm Payment" to proceed.',
                      style: TextStyle(fontSize: 10, color: _C.orange, height: 1.5))),
                ]),
              ),

              const SizedBox(height: 16),

              // Bill breakdown
              Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _C.cardBdr, width: 0.5)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.receipt_long_outlined, size: 14, color: _C.green), SizedBox(width: 6),
                    Text('BILL BREAKDOWN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _C.muted, letterSpacing: 0.5)),
                  ]),
                  const SizedBox(height: 14),
                  _pRow('Inspection Fee',   widget.inspectionFee, tag: 'Fixed'),
                  _pRow('Distance Fee',     widget.distanceFee),
                  _pRow('Service Fee (5%)', widget.serviceFee),
                  const Divider(height: 20, color: _C.cardBdr, thickness: 1.5),
                  Row(children: [
                    const Expanded(child: Text('Total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _C.txt1))),
                    Text('LKR ${_fmt(widget.totalAmount)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _C.accent)),
                  ]),
                ]),
              ),

              const SizedBox(height: 16),

              // Payment method placeholder
              Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _C.cardBdr, width: 0.5)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.payment_rounded, size: 14, color: _C.accent), SizedBox(width: 6),
                    Text('PAYMENT METHOD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _C.muted, letterSpacing: 0.5)),
                  ]),
                  const SizedBox(height: 14),
                  Container(padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF8F9FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.cardBdr)),
                    child: const Row(children: [
                      Icon(Icons.construction_rounded, size: 16, color: _C.muted), SizedBox(width: 10),
                      Expanded(child: Text('Payment gateway integration coming soon.\nUse agreed payment method then confirm below.',
                          style: TextStyle(fontSize: 11, color: _C.muted, height: 1.5))),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
        ),

        // ── Confirm Payment button ───────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(context).padding.bottom + 20),
          child: GestureDetector(
            onTap: _loading ? null : _completePayment,
            child: Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF27AE60), _C.greenDk]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Confirm Payment', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    ])),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _pRow(String label, double amount, {String? tag}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Text(label, style: const TextStyle(fontSize: 11, color: _C.txt2)),
          if (tag != null) ...[
            const SizedBox(width: 5),
            Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(4)),
                child: Text(tag, style: const TextStyle(fontSize: 8, color: _C.green, fontWeight: FontWeight.w600))),
          ],
          const Spacer(),
          Text('LKR ${_fmt(amount)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _C.txt1)),
        ]),
      );
}
