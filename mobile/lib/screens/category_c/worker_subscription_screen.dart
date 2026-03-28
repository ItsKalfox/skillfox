// category_c_worker_subscription_screen.dart
// Category C — Subscription / Recurring Jobs (teacher, caregiver)
// Worker sets up their subscription plan: monthly price, session schedule, and description.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class _C {
  static const gradA = Color(0xFF8B5CF6); // violet
  static const gradB = Color(0xFF6C56F0);
  static const accent = Color(0xFF8B5CF6);
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

class CategoryCWorkerSubscriptionScreen extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const CategoryCWorkerSubscriptionScreen({
    super.key,
    required this.requestId,
    required this.requestData,
  });

  @override
  State<CategoryCWorkerSubscriptionScreen> createState() =>
      _CategoryCWorkerSubscriptionScreenState();
}

class _CategoryCWorkerSubscriptionScreenState
    extends State<CategoryCWorkerSubscriptionScreen> {
  final _monthlyPriceCtrl = TextEditingController();
  final _sessionsCtrl = TextEditingController(); // sessions per month
  final _sessionDurCtrl = TextEditingController(); // e.g. "1 hour"
  final _scheduleCtrl = TextEditingController(); // e.g. Mon/Wed/Fri 4pm
  final _descCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _loading = false;

  // billing cycle
  String _billingCycle = 'monthly'; // 'monthly' | 'weekly'

  @override
  void dispose() {
    _monthlyPriceCtrl.dispose();
    _sessionsCtrl.dispose();
    _sessionDurCtrl.dispose();
    _scheduleCtrl.dispose();
    _descCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _price => double.tryParse(_monthlyPriceCtrl.text.trim()) ?? 0;
  int get _sessions => int.tryParse(_sessionsCtrl.text.trim()) ?? 0;
  double get _perSession => _sessions > 0 ? _price / _sessions : 0;

  String _fmt(num n) {
    final s = n.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  Future<void> _sendProposal() async {
    if (_monthlyPriceCtrl.text.trim().isEmpty) {
      _snack('Please enter the price.', isError: true);
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      _snack('Please enter a service description.', isError: true);
      return;
    }
    if (_scheduleCtrl.text.trim().isEmpty) {
      _snack('Please enter the schedule.', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
            'categoryType': 'C',
            'cBillingCycle': _billingCycle,
            'cMonthlyPrice': _price,
            'cSessionsPerCycle': _sessions,
            'cSessionDuration': _sessionDurCtrl.text.trim(),
            'cSchedule': _scheduleCtrl.text.trim(),
            'cServiceDescription': _descCtrl.text.trim(),
            'cNotes': _notesCtrl.text.trim(),
            'cPerSessionPrice': _perSession,
            // shared quotation fields
            'quotationSent': true,
            'quotationStatus': 'pending',
            'status': 'quotation_sent',
            'quotationSentAt': FieldValue.serverTimestamp(),
          });
      if (mounted) {
        _snack('Subscription proposal sent!');
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

  @override
  Widget build(BuildContext context) {
    final customerName =
        widget.requestData['customerName'] as String? ?? 'Customer';
    final category = widget.requestData['category'] as String? ?? 'Service';

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Subscription Proposal',
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
                  _infoBanner(
                    'Set up your recurring service plan. The customer will review and subscribe.',
                    icon: Icons.repeat_rounded,
                    color: _C.blue,
                    bg: const Color(0xFFEFF6FF),
                    border: const Color(0xFFBFDBFE),
                  ),
                  const SizedBox(height: 20),

                  // ── billing cycle toggle
                  _sectionLabel('BILLING CYCLE'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _cycleToggle('Monthly', 'monthly')),
                      const SizedBox(width: 10),
                      Expanded(child: _cycleToggle('Weekly', 'weekly')),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── price
                  _fieldLabel(
                    '${_billingCycle == 'monthly' ? 'Monthly' : 'Weekly'} Price (LKR)',
                  ),
                  const SizedBox(height: 8),
                  _numInput(_monthlyPriceCtrl, hint: '15000'),

                  // ── per-session preview
                  if (_price > 0 && _sessions > 0) ...[
                    const SizedBox(height: 10),
                    _perSessionPreview(),
                  ],

                  const SizedBox(height: 16),

                  // ── sessions per cycle
                  _fieldLabel(
                    'Sessions per ${_billingCycle == 'monthly' ? 'Month' : 'Week'}',
                  ),
                  const SizedBox(height: 8),
                  _numInput(
                    _sessionsCtrl,
                    hint: '8',
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 16),

                  // ── session duration
                  _fieldLabel('Duration per Session'),
                  const SizedBox(height: 8),
                  _textField(_sessionDurCtrl, hint: 'e.g. 1.5 hours'),

                  const SizedBox(height: 16),

                  // ── schedule
                  _fieldLabel('Session Schedule'),
                  const SizedBox(height: 8),
                  _textField(
                    _scheduleCtrl,
                    hint: 'e.g. Mon, Wed, Fri — 4:00 PM',
                  ),

                  const SizedBox(height: 16),

                  // ── description
                  _fieldLabel('Service Description'),
                  const SizedBox(height: 8),
                  _textArea(
                    _descCtrl,
                    hint:
                        'Describe what the recurring service includes (e.g. Mathematics tuition for Grade 10, covering algebra and calculus).',
                    lines: 4,
                  ),

                  const SizedBox(height: 16),

                  _fieldLabel('Additional Notes (Optional)'),
                  const SizedBox(height: 8),
                  _textArea(_notesCtrl, hint: 'Any extra details…', lines: 3),

                  const SizedBox(height: 24),
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
            child: Column(
              children: [
                GestureDetector(
                  onTap: _loading ? null : _sendProposal,
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
                                  _price > 0
                                      ? 'Send Proposal  ·  LKR ${_fmt(_price)}/${_billingCycle == 'monthly' ? 'mo' : 'wk'}'
                                      : 'Send Subscription Proposal',
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

  Widget _perSessionPreview() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [_C.gradA, _C.gradB]),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        const Icon(Icons.calculate_outlined, size: 14, color: Colors.white70),
        const SizedBox(width: 8),
        Text(
          'LKR ${_fmt(_price)} ÷ $_sessions sessions',
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const Spacer(),
        Text(
          'LKR ${_fmt(_perSession)}/session',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );

  Widget _cycleToggle(String label, String value) => GestureDetector(
    onTap: () => setState(() => _billingCycle = value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: _billingCycle == value ? const Color(0xFFF3EEFF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _billingCycle == value ? _C.accent : _C.cardBdr,
          width: _billingCycle == value ? 1.5 : 0.5,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _billingCycle == value ? _C.accent : _C.txt2,
          ),
        ),
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

  Widget _sectionLabel(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: _C.muted,
      letterSpacing: 0.6,
    ),
  );

  Widget _fieldLabel(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: _C.txt1,
    ),
  );

  Widget _numInput(
    TextEditingController ctrl, {
    required String hint,
    void Function(String)? onChanged,
  }) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _C.cardBdr),
    ),
    child: TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged ?? (_) => setState(() {}),
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
