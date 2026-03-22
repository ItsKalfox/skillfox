import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/subscription_service.dart';

class SessionsListPage extends StatelessWidget {
  const SessionsListPage({
    required this.subscriptionId,
    required this.onTrackSession,
    super.key,
  });

  final String subscriptionId;
  final ValueChanged<String> onTrackSession;

  @override
  Widget build(BuildContext context) {
    final service = SubscriptionService();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.sessionsStream(subscriptionId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final sessions = snapshot.data!.docs;
        if (sessions.isEmpty) {
          return const Center(child: Text('No sessions generated yet.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final sessionDoc = sessions[index];
            final session = sessionDoc.data();
            final status = (session['status'] ?? '-').toString();
            final scheduledAt = session['scheduledAt'] as Timestamp?;

            return Card(
              child: ListTile(
                title: Text('Session #${session['sessionNumber'] ?? index + 1}'),
                subtitle: Text(
                  'When: ${_formatTimestamp(scheduledAt)}\nStatus: $status',
                ),
                isThreeLine: true,
                trailing: TextButton(
                  onPressed: () => onTrackSession(sessionDoc.id),
                  child: const Text('Track'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '-';
    final date = ts.toDate();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '${date.year}-$m-$d $h:$min';
  }
}
