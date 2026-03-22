import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/subscription_service.dart';

class WorkProgressPage extends StatelessWidget {
  const WorkProgressPage({required this.subscriptionId, super.key});

  final String subscriptionId;

  @override
  Widget build(BuildContext context) {
    final service = SubscriptionService();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: service.subscriptionStream(subscriptionId),
      builder: (context, subSnapshot) {
        if (subSnapshot.hasError) {
          return Center(child: Text('Error: ${subSnapshot.error}'));
        }
        if (!subSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final subscription = subSnapshot.data!.data();
        if (subscription == null) {
          return const Center(child: Text('Subscription not found.'));
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: service.sessionsStream(subscriptionId),
          builder: (context, sessionsSnapshot) {
            if (!sessionsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final sessions = sessionsSnapshot.data!.docs;
            final totalSessions = sessions.length;
            final completedSessions = sessions
                .where((doc) => (doc.data()['status'] ?? '') == 'completed')
                .length;
            final progress = totalSessions == 0
                ? 0.0
                : completedSessions / totalSessions;

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: service.invoicesStream(subscriptionId),
              builder: (context, invoicesSnapshot) {
                if (!invoicesSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final invoices = invoicesSnapshot.data!.docs;
                final paidCount = invoices
                    .where((doc) => (doc.data()['status'] ?? '') == 'paid')
                    .length;
                final refundedCount = invoices
                    .where((doc) => (doc.data()['refundStatus'] ?? '') == 'refunded')
                    .length;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Full Work Progression',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text('Service: ${subscription['serviceType'] ?? '-'}'),
                            Text('Plan status: ${subscription['status'] ?? '-'}'),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(value: progress),
                            const SizedBox(height: 8),
                            Text(
                              'Session completion: $completedSessions / $totalSessions (${(progress * 100).toStringAsFixed(0)}%)',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment + Escrow Snapshot',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),
                            Text('Invoices: ${invoices.length}'),
                            Text('Paid: $paidCount'),
                            Text('Refunded: $refundedCount'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Progress Timeline',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    ...sessions.map(
                      (doc) {
                        final s = doc.data();
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.task_alt),
                          title: Text('Session #${s['sessionNumber'] ?? '-'}'),
                          subtitle: Text(
                            'Status: ${s['status'] ?? '-'} • ${_formatTimestamp(s['scheduledAt'] as Timestamp?)}',
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ...invoices.map(
                      (doc) {
                        final i = doc.data();
                        final escrow = (i['escrowStatus'] ?? '-').toString();
                        final paymentState = (i['paymentState'] ?? '-').toString();
                        final refund = (i['refundStatus'] ?? 'none').toString();
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.payments_outlined),
                          title: Text('Invoice cycle #${i['billingCycle'] ?? '-'}'),
                          subtitle: Text(
                            'Payment: $paymentState • Escrow: $escrow • Refund: $refund',
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  static String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '-';
    final date = ts.toDate();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }
}
