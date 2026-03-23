import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'payment/quotation_payment_screen.dart'; 
import 'review_screen.dart';

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
  static const blue    = Color(0xFF2563EB);
  static const orange  = Color(0xFFEA580C);
}

class CustomerQuotationViewScreen extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const CustomerQuotationViewScreen({
    super.key,
    required this.requestId,
    required this.requestData,
  });

  @override
  State<CustomerQuotationViewScreen> createState() => _CustomerQuotationViewScreenState();
}

class _CustomerQuotationViewScreenState extends State<CustomerQuotationViewScreen> {
  Map<String, dynamic> _data = {};
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _data = {...widget.requestData, 'id': widget.requestId};
    // Listen for real-time updates
    FirebaseFirestore.instance.collection('requests').doc(widget.requestId).snapshots().listen((snap) {
      if (!snap.exists || !mounted) return;
      final d = Map<String, dynamic>.from(snap.data()!);
      d['id'] = snap.id;
      setState(() => _data = d);
    });
  }

  String _fmt(num n) {
    final s = n.toStringAsFixed(0); final b = StringBuffer();
    for (int i = 0; i < s.length; i++) { if (i > 0 && (s.length - i) % 3 == 0) b.write(','); b.write(s[i]); }
    return b.toString();
  }

  Future<void> _acceptQuotation() async {
    setState(() => _actionLoading = true);
    try {
      await FirebaseFirestore.instance.collection('requests').doc(widget.requestId).update({
        'quotationStatus': 'accepted',
        'quotationAcceptedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      // Navigate to quotation payment screen
      Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => QuotationPaymentScreen(
            requestId:   widget.requestId,
            requestData: _data,
          )));
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _declineQuotation() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('Decline Quotation', style: TextStyle(fontWeight: FontWeight.w700)),
      content: const Text('Are you sure you want to decline this quotation?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _C.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Decline', style: TextStyle(color: Colors.white))),
      ],
    ));
    if (ok != true || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      await FirebaseFirestore.instance.collection('requests').doc(widget.requestId).update({
        'quotationStatus': 'declined',
        'quotationDeclinedAt': FieldValue.serverTimestamp(),
        'status': 'quotation_declined',
      });
      if (!mounted) return;
      // Navigate to review screen
      Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => ReviewScreen(
            requestId:   widget.requestId,
            requestData: _data,
            isWorker:    false,
          )));
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? _C.red : _C.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final jobDesc        = _data['quotationJobDesc']        as String? ?? '';
    final labourCost     = (_data['quotationLabourCost']    as num?)?.toDouble() ?? 0;
    final materialCost   = (_data['quotationMaterialCost']  as num?)?.toDouble() ?? 0;
    final totalCost      = (_data['quotationTotalCost']     as num?)?.toDouble() ?? (labourCost + materialCost);
    final completionTime = _data['quotationCompletionTime'] as String? ?? '';
    final notes          = _data['quotationNotes']          as String? ?? '';
    final workerName     = _data['workerName']              as String? ?? 'Worker';
    final category       = _data['category']                as String? ?? '';
    final quotationStatus = _data['quotationStatus']        as String? ?? 'pending';
    final sentAt         = _data['quotationSentAt'];

    String sentAtStr = '';
    if (sentAt != null) {
      try { sentAtStr = DateFormat('dd MMM yyyy, hh:mm a').format((sentAt as dynamic).toDate()); } catch (_) {}
    }

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(children: [

        // ── Gradient Header ──────────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [_C.gradA, _C.gradB])),
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 4, bottom: 16, left: 16, right: 16),
          child: Row(children: [
            GestureDetector(onTap: () => Navigator.pop(context),
                child: Container(width: 32, height: 32,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.white))),
            const SizedBox(width: 12),
            const Text('Quotation Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Text('CUSTOMER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5))),
          ]),
        ),

        // ── Body ────────────────────────────────────────────────────────────
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Worker info card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _C.cardBdr, width: 0.5)),
              child: Row(children: [
                Container(width: 44, height: 44,
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [_C.gradA, _C.gradB])),
                    child: Center(child: Text(workerName.isNotEmpty ? workerName[0].toUpperCase() : 'W',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(workerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.txt1)),
                  Text(category,   style: const TextStyle(fontSize: 11, color: _C.txt2)),
                  if (sentAtStr.isNotEmpty) Text('Sent: $sentAtStr', style: const TextStyle(fontSize: 10, color: _C.muted)),
                ])),
                _statusChip(quotationStatus),
              ]),
            ),

            const SizedBox(height: 16),

            // Quotation details card
            _detailCard('QUOTATION DETAILS', [
              if (jobDesc.isNotEmpty) _detailRow('Job Description', jobDesc, multiLine: true),
              if (completionTime.isNotEmpty) _detailRow('Est. Completion', completionTime),
              if (notes.isNotEmpty) _detailRow('Additional Notes', notes, multiLine: true),
            ]),

            const SizedBox(height: 12),

            // Cost breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _C.cardBdr, width: 0.5)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.receipt_long_outlined, size: 14, color: _C.green), SizedBox(width: 6),
                  Text('COST BREAKDOWN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _C.muted, letterSpacing: 0.5)),
                ]),
                const SizedBox(height: 12),
                _costRow('Labour Cost',   labourCost),
                _costRow('Material Cost', materialCost),
                const Divider(height: 20, color: _C.cardBdr, thickness: 1.5),
                Row(children: [
                  const Expanded(child: Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _C.txt1))),
                  Text('LKR ${_fmt(totalCost)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _C.accent)),
                ]),
              ]),
            ),

            const SizedBox(height: 12),

            // Info box
            if (quotationStatus == 'pending')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBFDBFE), width: 0.5)),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: _C.blue), SizedBox(width: 8),
                  Expanded(child: Text('Review the quotation carefully. Accept to proceed with payment or decline if you disagree.',
                      style: TextStyle(fontSize: 10, color: _C.blue, height: 1.5))),
                ]),
              ),

            const SizedBox(height: 80),
          ]),
        )),

        // ── Action buttons ───────────────────────────────────────────────────
        if (quotationStatus == 'pending')
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(context).padding.bottom + 16),
            child: Column(children: [
              // Accept
              GestureDetector(
                onTap: _actionLoading ? null : _acceptQuotation,
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [_C.gradA, _C.gradB]), borderRadius: BorderRadius.circular(14)),
                  child: Center(child: _actionLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('Accept  —  LKR ${_fmt(totalCost)}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                        ])),
                ),
              ),

              const SizedBox(height: 10),

              // Decline
              GestureDetector(
                onTap: _actionLoading ? null : _declineQuotation,
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _C.red.withOpacity(0.4), width: 1.5)),
                  child: const Center(child: Text('Decline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _C.red))),
                ),
              ),
            ]),
          ),

        // Already accepted/declined state
        if (quotationStatus != 'pending')
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(context).padding.bottom + 16),
            child: Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: quotationStatus == 'accepted' ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: quotationStatus == 'accepted' ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
              ),
              child: Center(child: Text(
                quotationStatus == 'accepted' ? '✓ Quotation Accepted' : '✗ Quotation Declined',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: quotationStatus == 'accepted' ? _C.green : _C.red),
              )),
            ),
          ),
      ]),
    );
  }

  Widget _statusChip(String status) {
    Color bg; Color text; String label;
    switch (status) {
      case 'accepted': bg = const Color(0xFFECFDF5); text = _C.green;  label = 'Accepted'; break;
      case 'declined': bg = const Color(0xFFFEF2F2); text = _C.red;    label = 'Declined'; break;
      default:         bg = const Color(0xFFEFF6FF); text = _C.blue;   label = 'Pending';
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: text)));
  }

  Widget _detailCard(String title, List<Widget> rows) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _C.cardBdr, width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _C.muted, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          ...rows,
        ]),
      );

  Widget _detailRow(String label, String value, {bool multiLine = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: multiLine
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(fontSize: 10, color: _C.muted)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 12, color: _C.txt1, height: 1.5)),
              ])
            : Row(children: [
                Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: _C.txt2))),
                Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _C.txt1)),
              ]),
      );

  Widget _costRow(String label, double amount) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: _C.txt2))),
          Text('LKR ${_fmt(amount)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _C.txt1)),
        ]),
      );
}
