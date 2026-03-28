// category_b_worker_quotation_screen.dart
// Category B — One-time Fixed Jobs (cleaning, handyman)
// Worker sets their price (hourly or fixed) and sends a quotation to the customer.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class _C {
  static const gradA = Color(0xFF10B981); // emerald
  static const gradB = Color(0xFF059669);
  static const accent = Color(0xFF10B981);
  static const bg = Color(0xFFF4F6FA);
  static const cardBdr = Color(0xFFE2E6F0);
  static const txt1 = Color(0xFF111111);
  static const txt2 = Color(0xFF888888);
  static const muted = Color(0xFFA0A4B0);
  static const green = Color(0xFF16A34A);
  static const red = Color(0xFFEF4444);
  static const orange = Color(0xFFEA580C);
  static const blue = Color(0xFF2563EB);
}

/// Pricing model the worker can choose
enum _PricingType { hourly, fixed }

class CategoryBWorkerQuotationScreen extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const CategoryBWorkerQuotationScreen({
    super.key,
    required this.requestId,
    required this.requestData,
  });

  @override
  State<CategoryBWorkerQuotationScreen> createState() =>
      _CategoryBWorkerQuotationScreenState();
}

class _CategoryBWorkerQuotationScreenState
    extends State<CategoryBWorkerQuotationScreen> {
  _PricingType _pricingType = _PricingType.hourly;

  final _rateCtrl = TextEditingController(); // LKR per hour OR fixed price
  final _hoursCtrl = TextEditingController(); // only used for hourly
  final _descCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _scheduleCtrl = TextEditingController(); // e.g. "Saturday 9am"

  bool _loading = false;

  @override
  void dispose() {
    _rateCtrl.dispose();
    _hoursCtrl.dispose();
    _descCtrl.dispose();
    _notesCtrl.dispose();
    _scheduleCtrl.dispose();
    super.dispose();
  }

  // ── computed total ──────────────────────────────────────────────────────────
  double get _total {
    final rate = double.tryParse(_rateCtrl.text.trim()) ?? 0;
    final hours = double.tryParse(_hoursCtrl.text.trim()) ?? 0;
    if (_pricingType == _PricingType.fixed) return rate;
    return rate * hours;
  }

  String _fmt(num n) {
    final s = n.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  // ── submit ──────────────────────────────────────────────────────────────────
  Future<void> _sendQuotation() async {
    if (_rateCtrl.text.trim().isEmpty) {
      _snack('Please enter your price.', isError: true);
      return;
    }
    if (_pricingType == _PricingType.hourly && _hoursCtrl.text.trim().isEmpty) {
      _snack('Please enter estimated hours.', isError: true);
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      _snack('Please describe the work.', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final rate = double.parse(_rateCtrl.text.trim());
      final hours = double.tryParse(_hoursCtrl.text.trim()) ?? 0;

      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
            // Category B specific fields
            'categoryType': 'B',
            'bPricingType': _pricingType == _PricingType.hourly
                ? 'hourly'
                : 'fixed',
            'bRate': rate,
            'bEstimatedHours': _pricingType == _PricingType.hourly
                ? hours
                : null,
            'bTotalQuoted': _total,
            'bWorkDescription': _descCtrl.text.trim(),
            'bSchedule': _scheduleCtrl.text.trim(),
            'bNotes': _notesCtrl.text.trim(),
            // shared quotation fields (compatible with existing listener logic)
            'quotationSent': true,
            'quotationStatus': 'pending',
            'status': 'quotation_sent',
            'quotationSentAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        _snack('Quotation sent to customer!');
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
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
    final customerName =
        widget.requestData['customerName'] as String? ?? 'Customer';
    final category = widget.requestData['category'] as String? ?? 'Job';

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          // ── header
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
                        'Send Price Quotation',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'for $customerName · $category',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // info banner
                  _infoBanner(
                    'Set your price and job details below. The customer will review and accept or decline before you proceed.',
                    icon: Icons.info_outline_rounded,
                    color: _C.blue,
                    bg: const Color(0xFFEFF6FF),
                    border: const Color(0xFFBFDBFE),
                  ),
                  const SizedBox(height: 20),

                  // ── pricing type toggle
                  _sectionLabel('PRICING MODEL'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _pricingToggle(
                          label: 'Hourly Rate',
                          icon: Icons.timer_outlined,
                          active: _pricingType == _PricingType.hourly,
                          onTap: () => setState(
                            () => _pricingType = _PricingType.hourly,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _pricingToggle(
                          label: 'Fixed Price',
                          icon: Icons.price_check_rounded,
                          active: _pricingType == _PricingType.fixed,
                          onTap: () =>
                              setState(() => _pricingType = _PricingType.fixed),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── price fields
                  _fieldLabel(
                    _pricingType == _PricingType.hourly
                        ? 'Rate per Hour (LKR)'
                        : 'Fixed Price (LKR)',
                  ),
                  const SizedBox(height: 8),
                  _numInput(
                    _rateCtrl,
                    hint: _pricingType == _PricingType.hourly ? '1500' : '5000',
                  ),

                  if (_pricingType == _PricingType.hourly) ...[
                    const SizedBox(height: 16),
                    _fieldLabel('Estimated Hours'),
                    const SizedBox(height: 8),
                    _numInput(_hoursCtrl, hint: '3'),
                  ],

                  // ── live total display
                  if (_total > 0) ...[
                    const SizedBox(height: 12),
                    _totalBanner(),
                  ],

                  const SizedBox(height: 20),

                  // ── work description
                  _fieldLabel('Work Description'),
                  const SizedBox(height: 8),
                  _textArea(
                    _descCtrl,
                    hint:
                        'Describe exactly what work will be done (e.g. Deep clean 3-bedroom apartment including bathrooms, kitchen, and living areas).',
                    lines: 4,
                  ),

                  const SizedBox(height: 16),

                  // ── preferred schedule
                  _fieldLabel('Preferred Schedule / Date'),
                  const SizedBox(height: 8),
                  _textField(
                    _scheduleCtrl,
                    hint: 'e.g. Saturday 15 June, 9:00 AM',
                  ),

                  const SizedBox(height: 16),

                  // ── additional notes
                  _fieldLabel('Additional Notes (Optional)'),
                  const SizedBox(height: 8),
                  _textArea(
                    _notesCtrl,
                    hint: 'Any extra details for the customer…',
                    lines: 3,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── bottom bar
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
              16,
              14,
              16,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _loading ? null : _sendQuotation,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_C.gradA, _C.gradB],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: _loading
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
                                  Icons.send_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _total > 0
                                      ? 'Send Quotation  ·  LKR ${_fmt(_total)}'
                                      : 'Send Quotation to Customer',
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
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _C.cardBdr, width: 1.5),
                    ),
                    child: const Center(
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _C.txt2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── helpers ─────────────────────────────────────────────────────────────────

  Widget _totalBanner() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [_C.gradA, _C.gradB]),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        const Icon(Icons.calculate_outlined, size: 15, color: Colors.white70),
        const SizedBox(width: 8),
        Text(
          _pricingType == _PricingType.hourly
              ? '${_hoursCtrl.text} hrs × LKR ${_fmt(double.tryParse(_rateCtrl.text) ?? 0)}'
              : 'Fixed price',
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const Spacer(),
        Text(
          'LKR ${_fmt(_total)}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );

  Widget _pricingToggle({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFECFDF5) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? _C.accent : _C.cardBdr,
          width: active ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: active ? _C.accent : _C.muted),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? _C.accent : _C.txt2,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _infoBanner(
    String text, {
    required IconData icon,
    required Color color,
    required Color bg,
    required Color border,
  }) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: border, width: 0.5),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11, color: color, height: 1.5),
          ),
        ),
      ],
    ),
  );

  Widget _sectionLabel(String label) => Text(
    label,
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: _C.muted,
      letterSpacing: 0.6,
    ),
  );

  Widget _fieldLabel(String label) => Text(
    label,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: _C.txt1,
    ),
  );

  Widget _numInput(TextEditingController ctrl, {required String hint}) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.cardBdr),
        ),
        child: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 14, color: _C.txt1),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _C.muted, fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            prefixText: 'LKR  ',
            prefixStyle: const TextStyle(
              color: _C.muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );

  Widget _textField(TextEditingController ctrl, {required String hint}) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.cardBdr),
        ),
        child: TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 14, color: _C.txt1),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _C.muted, fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      );

  Widget _textArea(
    TextEditingController ctrl, {
    required String hint,
    required int lines,
  }) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _C.cardBdr),
    ),
    child: TextField(
      controller: ctrl,
      maxLines: lines,
      style: const TextStyle(fontSize: 13, color: _C.txt1),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _C.muted, fontSize: 13),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(14),
      ),
    ),
  );
}
