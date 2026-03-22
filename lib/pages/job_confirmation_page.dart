import 'package:flutter/material.dart';

import '../models/job.dart';
import '../services/job_repository.dart';
import 'job_status_page.dart';

class JobConfirmationPage extends StatelessWidget {
  const JobConfirmationPage({
    super.key,
    required this.jobId,
    required this.repository,
  });

  final String jobId;
  final JobRepository repository;

  String _prettyStatus(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  String _formatDateTime(DateTime dateTime) {
    final date =
        '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$date at $hour:$minute $period';
  }

  Future<void> _setStatus(
    BuildContext context,
    String status,
    String successMessage,
  ) async {
    try {
      await repository.updateStatus(jobId, status);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Update failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Job Confirmation')),
      body: StreamBuilder(
        stream: repository.streamJob(jobId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snapshot.data;
          if (doc == null || !doc.exists) {
            return const Center(child: Text('Job not found.'));
          }

          final job = Job.fromSnapshot(doc);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              job.service,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Chip(label: Text(_prettyStatus(job.status))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(job.description),
                      const SizedBox(height: 12),
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.schedule_outlined),
                        title: const Text('Scheduled'),
                        subtitle: Text(_formatDateTime(job.scheduledAt)),
                      ),
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.location_on_outlined),
                        title: const Text('Location'),
                        subtitle: Text(job.location),
                      ),
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.payments_outlined),
                        title: const Text('Price'),
                        subtitle: Text(job.price.toStringAsFixed(2)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned Worker',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Name: ${job.workerName ?? 'Pending assignment'}'),
                      const SizedBox(height: 6),
                      Text(
                        'Contact: ${job.workerPhone?.isNotEmpty == true ? job.workerPhone : 'N/A'}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: job.status == 'cancelled'
                    ? null
                    : () => _setStatus(context, 'confirmed', 'Job confirmed.'),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Confirm Job'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: job.status == 'completed'
                    ? null
                    : () => _setStatus(context, 'cancelled', 'Job cancelled.'),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Job'),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => JobStatusPage(
                        jobId: jobId,
                        repository: repository,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.timeline_outlined),
                label: const Text('Go To Live Job Status'),
              ),
            ],
          );
        },
      ),
    );
  }
}
