import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/subscription_service.dart';

class ManageSubscriptionPage extends StatefulWidget {
  const ManageSubscriptionPage({required this.subscriptionId, super.key});

  final String subscriptionId;

  @override
  State<ManageSubscriptionPage> createState() => _ManageSubscriptionPageState();
}

class _ManageSubscriptionPageState extends State<ManageSubscriptionPage> {
  final _service = SubscriptionService();
  bool _working = false;

  Future<void> _updateSubscriptionStatus(String status) async {
    setState(() => _working = true);
    try {
      await _service.updateSubscriptionStatus(
        subscriptionId: widget.subscriptionId,
        status: status,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Subscription set to $status')));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _skipSession() async {
    final upcoming = await FirebaseFirestore.instance
        .collection('sessions')
        .where('subscriptionId', isEqualTo: widget.subscriptionId)
        .where('status', isEqualTo: 'upcoming')
        .orderBy('scheduledAt')
        .limit(1)
        .get();

    if (upcoming.docs.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No upcoming session found to skip.')),
      );
      return;
    }

    await _service.setSessionStatus(
      sessionId: upcoming.docs.first.id,
      status: 'skipped',
      progressNote: 'Skipped by customer',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Next session skipped.')));
  }

  Future<void> _rescheduleNextSession() async {
    final selectedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now().add(const Duration(days: 3)),
    );

    if (selectedDate == null) return;

    final upcoming = await FirebaseFirestore.instance
        .collection('sessions')
        .where('subscriptionId', isEqualTo: widget.subscriptionId)
        .where('status', isEqualTo: 'upcoming')
        .orderBy('scheduledAt')
        .limit(1)
        .get();

    if (upcoming.docs.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No upcoming session found to reschedule.')),
      );
      return;
    }

    await _service.rescheduleSession(
      sessionId: upcoming.docs.first.id,
      newDate: selectedDate,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Next session rescheduled.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _service.subscriptionStream(widget.subscriptionId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!.data() ?? {};
        final status = (data['status'] ?? 'unknown').toString();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Current Subscription Status'),
              subtitle: Text(status),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed:
                      _working ? null : () => _updateSubscriptionStatus('paused'),
                  child: const Text('Pause'),
                ),
                FilledButton(
                  onPressed:
                      _working ? null : () => _updateSubscriptionStatus('active'),
                  child: const Text('Resume'),
                ),
                FilledButton.tonal(
                  onPressed:
                      _working ? null : () => _updateSubscriptionStatus('canceled'),
                  child: const Text('Cancel'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Session Operations',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _working ? null : _skipSession,
              child: const Text('Skip Next Session'),
            ),
            OutlinedButton(
              onPressed: _working ? null : _rescheduleNextSession,
              child: const Text('Reschedule Next Session'),
            ),
          ],
        );
      },
    );
  }
}
