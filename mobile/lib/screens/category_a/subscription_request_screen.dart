import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/worker.dart';
import 'customer_request_screen.dart';

class SubscriptionRequestScreen extends StatefulWidget {
  final Worker worker;
  final List<Map<String, dynamic>> services;

  const SubscriptionRequestScreen({
    super.key,
    required this.worker,
    required this.services,
  });

  @override
  State<SubscriptionRequestScreen> createState() =>
      _SubscriptionRequestScreenState();
}

class _SubscriptionRequestScreenState extends State<SubscriptionRequestScreen> {
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final TextEditingController _notesController = TextEditingController();
  bool _loading = false;

  String _subscriptionModel = 'weekly';
  final Set<String> _selectedDays = <String>{};

  String _studentRefFromId(String customerId) {
    if (customerId.isEmpty) return 'STUDENT-NA';
    final suffix = customerId.length > 6
        ? customerId.substring(customerId.length - 6)
        : customerId;
    return 'STUDENT-${suffix.toUpperCase()}';
  }

  Future<void> _submit() async {
    if (_selectedDays.isEmpty) {
      _showSnack('Please select at least one day.', isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final customerId = user?.uid ?? '';

      String customerName = 'Customer';
      if (customerId.isNotEmpty) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(customerId)
            .get();
        final data = userDoc.data() ?? <String, dynamic>{};
        final firestoreName = (data['name'] ?? '').toString().trim();
        if (firestoreName.isNotEmpty) {
          customerName = firestoreName;
        } else if ((user?.email ?? '').isNotEmpty) {
          customerName = user!.email!;
        }
      }

      final requestDoc = await FirebaseFirestore.instance
          .collection('requests')
          .add({
            'requestType': 'subscription',
            'workerId': widget.worker.id,
            'workerName': widget.worker.name,
            'category': widget.worker.category,
            'customerId': customerId,
            'customerName': customerName,
            'studentId': customerId,
            'studentName': customerName,
            'studentRef': _studentRefFromId(customerId),
            'serviceType': '${widget.worker.category} subscription'.trim(),
            'subscriptionPlan': '${widget.worker.category} subscription'.trim(),
            'subscriptionModel': _subscriptionModel,
            'subscriptionDays': _selectedDays.toList()..sort(),
            'subscriptionPrice': '',
            'subscriptionCycleIndex': 1,
            'subscriptionCyclePaymentStatus': 'pending',
            'subscriptionCycleStartAt': FieldValue.serverTimestamp(),
            'description': _notesController.text.trim(),
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerRequestScreen(
            requestId: requestDoc.id,
            worker: widget.worker,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to submit request: $e', isError: true);
      setState(() => _loading = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFD32F2F)
            : const Color(0xFF2E7D32),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.worker.category.toLowerCase();
    final isTeacher = category == 'teacher';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(isTeacher ? 'Request Classes' : 'Request Care Plan'),
        backgroundColor: const Color(0xFF4B7DF3),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Subscription model'),
            const SizedBox(height: 8),
            Container(
              decoration: _cardDecoration(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'weekly',
                    groupValue: _subscriptionModel,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _subscriptionModel = value);
                    },
                    title: const Text('Weekly'),
                    subtitle: const Text('Recurring every week'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<String>(
                    value: 'monthly',
                    groupValue: _subscriptionModel,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _subscriptionModel = value);
                    },
                    title: const Text('Monthly'),
                    subtitle: const Text('Recurring every month'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionTitle('Preferred days'),
            const SizedBox(height: 8),
            Container(
              decoration: _cardDecoration(),
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _days.map((day) {
                  final selected = _selectedDays.contains(day);
                  return FilterChip(
                    selected: selected,
                    label: Text(day),
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _selectedDays.add(day);
                        } else {
                          _selectedDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            _sectionTitle(
              isTeacher ? 'Learning goals (optional)' : 'Care notes (optional)',
            ),
            const SizedBox(height: 8),
            Container(
              decoration: _cardDecoration(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextField(
                controller: _notesController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Add any specific details here...',
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B7DF3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit Subscription Request',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1F2E),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2E6F0)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
