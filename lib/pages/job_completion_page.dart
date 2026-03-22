import 'package:flutter/material.dart';

import '../models/job.dart';
import '../services/job_repository.dart';
import 'review_page.dart';

class JobCompletionPage extends StatelessWidget {
  const JobCompletionPage({
    super.key,
    required this.jobId,
    required this.repository,
  });

  final String jobId;
  final JobRepository repository;

  Future<void> _markByWorker(BuildContext context) async {
    try {
      await repository.updateStatus(
        jobId,
        'worker_marked_complete',
        extra: {'workerCompletedAt': DateTime.now().toUtc()},
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Worker marked job complete.')));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to update: $error')));
    }
  }

  Future<void> _confirmByUser(BuildContext context) async {
    try {
      await repository.updateStatus(
        jobId,
        'completed',
        extra: {'userCompletedAt': DateTime.now().toUtc()},
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Job completion confirmed.')));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to update: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Job Completion')),
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
          final canWorkerMark =
              job.status != 'completed' && job.status != 'cancelled';
          final canUserConfirm =
              job.status == 'worker_marked_complete' || job.status == 'in_progress';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completion Workflow',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Worker marks task complete.\n2. User verifies and confirms completion.\n3. User submits review.',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.flag_circle_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Current status: ${job.status.replaceAll('_', ' ')}',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: canWorkerMark ? () => _markByWorker(context) : null,
                icon: const Icon(Icons.engineering_outlined),
                label: const Text('Worker: Mark Complete'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: canUserConfirm ? () => _confirmByUser(context) : null,
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('User: Confirm Completion'),
              ),
              const SizedBox(height: 12),
              if (job.status == 'completed')
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ReviewPage(
                          jobId: job.id,
                          workerId: job.workerId ?? 'unknown-worker',
                          repository: repository,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('Leave Review'),
                ),
            ],
          );
        },
      ),
    );
  }
}
