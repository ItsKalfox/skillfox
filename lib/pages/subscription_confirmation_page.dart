import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/subscription_service.dart';

class SubscriptionConfirmationPage extends StatelessWidget {
  const SubscriptionConfirmationPage({required this.subscriptionId, super.key});

  final String subscriptionId;

  @override
  Widget build(BuildContext context) {
    final service = SubscriptionService();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: service.subscriptionStream(subscriptionId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data();
        if (data == null) {
          return const Center(child: Text('Subscription not found.'));
        }

        final worker = (data['assignedWorker'] as Map<String, dynamic>?) ?? {};
        final startDate = data['startDate'] as Timestamp?;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Subscription Confirmation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _tile('Service Type', data['serviceType']),
            _tile('Frequency', data['frequency']),
            _tile('Total Sessions', data['sessions']),
            _tile('Preferred Schedule', data['preferredSchedule']),
            _tile('Start Date', _formatTimestamp(startDate)),
            _tile('Status', data['status']),
            _tile(
              'Price Confirmation',
              '${(data['totalPrice'] ?? 0).toString()} total',
            ),
            const Divider(height: 30),
            const Text(
              'Assigned Worker',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _tile('Name', worker['name'] ?? 'Pending assignment'),
            _tile('Contact', worker['phone'] ?? 'Will be updated soon'),
          ],
        );
      },
    );
  }

  Widget _tile(String label, Object? value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text((value ?? '-').toString()),
    );
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '-';
    final date = ts.toDate();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }
}
