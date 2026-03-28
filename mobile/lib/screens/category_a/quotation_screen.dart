import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class _C {
  static const gradA = Color(0xFF469FEF);
  static const gradB = Color(0xFF6C56F0);
  static const bg = Color(0xFFF4F6FA);
  static const cardBdr = Color(0xFFE2E6F0);
  static const txt1 = Color(0xFF111111);
  static const txt2 = Color(0xFF888888);
  static const muted = Color(0xFFA0A4B0);
  static const green = Color(0xFF16A34A);
  static const red = Color(0xFFEF4444);
  static const orange = Color(0xFFEA580C);
}

class QuotationScreen extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const QuotationScreen({
    super.key,
    required this.requestId,
    required this.requestData,
  });

  @override
  State<QuotationScreen> createState() => _QuotationScreenState();
}

class _QuotationScreenState extends State<QuotationScreen> {
  final _jobDescCtrl = TextEditingController();
  final _labourCostCtrl = TextEditingController();
  final _materialCostCtrl = TextEditingController();
  final _completionTimeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  File? _evidencePhoto;
  bool _loading = false;

  @override
  void dispose() {
    _jobDescCtrl.dispose();
    _labourCostCtrl.dispose();
    _materialCostCtrl.dispose();
    _completionTimeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _totalCost {
    final labour = double.tryParse(_labourCostCtrl.text.trim()) ?? 0;
    final material = double.tryParse(_materialCostCtrl.text.trim()) ?? 0;
    return labour + material;
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

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _evidencePhoto = File(picked.path));
  }

  Future<void> _sendQuotation() async {
    if (_jobDescCtrl.text.trim().isEmpty) {
      _showSnack('Please enter job description.', isError: true);
      return;
    }
    if (_labourCostCtrl.text.trim().isEmpty) {
      _showSnack('Please enter labour cost.', isError: true);
      return;
    }

    final labour = double.tryParse(_labourCostCtrl.text.trim()) ?? 0;
    final material = double.tryParse(_materialCostCtrl.text.trim()) ?? 0;
    if (labour <= 0) {
      _showSnack('Please enter a valid labour cost.', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
            'quotationJobDesc': _jobDescCtrl.text.trim(),
            'quotationLabourCost': labour,
            'quotationMaterialCost': material,
            'quotationTotalCost': labour + material,
            'quotationCompletionTime': _completionTimeCtrl.text.trim(),
            'quotationNotes': _notesCtrl.text.trim(),
            'categoryType': 'A',
            'quotationSent': true,
            'quotationStatus': 'pending',
            'status': 'quotation_sent',
            'quotationSentAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        _showSnack('Quotation sent to customer!');
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
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
                        'Send Quotation',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'for ${widget.requestData['customerName'] ?? 'Customer'} · ${widget.requestData['category'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                    'CAT A',
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
                  // Customer's original request description as context for the worker
                  if ((widget.requestData['description'] as String? ?? '')
                      .isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _C.cardBdr, width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 13,
                                color: _C.gradB,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'CUSTOMER REQUEST',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _C.muted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.requestData['description'] as String? ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _C.txt1,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFFED7AA),
                        width: 0.5,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: _C.orange,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Fill in the quotation details. This will be sent to the customer for approval before proceeding.',
                            style: TextStyle(
                              fontSize: 11,
                              color: _C.orange,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  _fieldLabel('Job Description / Work Done'),
                  const SizedBox(height: 8),
                  _textArea(
                    _jobDescCtrl,
                    'Replaced leaking pipe joint under kitchen sink.\nCleaned drainage. Checked all visible connections.',
                    4,
                  ),

                  const SizedBox(height: 16),

                  _fieldLabel('Labour Cost (LKR)'),
                  const SizedBox(height: 8),
                  _textInput(
                    _labourCostCtrl,
                    '2500',
                    TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 16),

                  _fieldLabel('Material Cost (LKR)'),
                  const SizedBox(height: 8),
                  _textInput(
                    _materialCostCtrl,
                    '1800',
                    TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),

                  if (_totalCost > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_C.gradA, _C.gradB],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Total Cost:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'LKR ${_fmt(_totalCost)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  _fieldLabel('Estimated Completion Time'),
                  const SizedBox(height: 8),
                  _textInput(
                    _completionTimeCtrl,
                    '2 hours',
                    TextInputType.text,
                  ),

                  const SizedBox(height: 16),

                  _fieldLabel('Attach Photo / Evidence'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _C.cardBdr,
                          style: BorderStyle.solid,
                          width: 1.5,
                        ),
                      ),
                      child: _evidencePhoto != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _evidencePhoto!,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              children: [
                                Icon(
                                  Icons.camera_alt_outlined,
                                  size: 32,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Tap to upload ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _C.gradA,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'a photo of the work area',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'JPG, PNG up to 10MB',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _fieldLabel('Additional Notes'),
                  const SizedBox(height: 8),
                  _textArea(
                    _notesCtrl,
                    'Any additional notes for the customer...',
                    3,
                  ),

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
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.send_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Send Quotation to Customer',
                                  style: TextStyle(
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

  Widget _fieldLabel(String label) => Text(
    label,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: _C.txt1,
    ),
  );

  Widget _textInput(
    TextEditingController ctrl,
    String hint,
    TextInputType type, {
    void Function(String)? onChanged,
  }) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _C.cardBdr),
    ),
    child: TextField(
      controller: ctrl,
      keyboardType: type,
      onChanged: onChanged,
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

  Widget _textArea(TextEditingController ctrl, String hint, int lines) =>
      Container(
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
