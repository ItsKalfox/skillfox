import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/subscription_service.dart';

class SessionTrackingPage extends StatefulWidget {
  const SessionTrackingPage({
    required this.subscriptionId,
    this.initialSessionId,
    super.key,
  });

  final String subscriptionId;
  final String? initialSessionId;

  @override
  State<SessionTrackingPage> createState() => _SessionTrackingPageState();
}

class _SessionTrackingPageState extends State<SessionTrackingPage> {
  final _service = SubscriptionService();
  String? _selectedSessionId;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _selectedSessionId = widget.initialSessionId;
  }

  @override
  void didUpdateWidget(covariant SessionTrackingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSessionId != null &&
        widget.initialSessionId != oldWidget.initialSessionId) {
      _selectedSessionId = widget.initialSessionId;
    }
  }

  Future<void> _setStatus(String status) async {
    if (_selectedSessionId == null) return;
    setState(() => _updating = true);
    try {
      await _service.setSessionStatus(
        sessionId: _selectedSessionId!,
        status: status,
        progressNote: 'Updated to $status',
      );
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.sessionsStream(widget.subscriptionId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final sessions = snapshot.data!.docs;
        if (sessions.isEmpty) {
          return const Center(child: Text('No sessions available for tracking.'));
        }

        _selectedSessionId ??= sessions.first.id;

        final selectedSession = sessions.firstWhere(
          (doc) => doc.id == _selectedSessionId,
          orElse: () => sessions.first,
        );
        final selectedData = selectedSession.data();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedSession.id,
              decoration: const InputDecoration(labelText: 'Track Session'),
              items:
                  sessions
                      .map(
                        (doc) => DropdownMenuItem(
                          value: doc.id,
                          child: Text('Session #${doc['sessionNumber'] ?? '-'}'),
                        ),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _selectedSessionId = value),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session #${selectedData['sessionNumber'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Status: ${selectedData['status'] ?? '-'}'),
                    Text(
                      'Scheduled: ${_formatTimestamp(selectedData['scheduledAt'] as Timestamp?)}',
                    ),
                    Text('Progress: ${selectedData['progressNote'] ?? '-'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _updating ? null : () => _setStatus('in_progress'),
                  child: const Text('Mark In Progress'),
                ),
                OutlinedButton(
                  onPressed: _updating ? null : () => _setStatus('completed'),
                  child: const Text('Mark Completed'),
                ),
                OutlinedButton(
                  onPressed: _updating ? null : () => _setStatus('upcoming'),
                  child: const Text('Mark Upcoming'),
                ),
              ],
            ),
          ],
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
