import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/job.dart';
import '../services/job_repository.dart';
import 'job_completion_page.dart';

class JobStatusPage extends StatelessWidget {
  const JobStatusPage({
    super.key,
    required this.jobId,
    required this.repository,
  });

  final String jobId;
  final JobRepository repository;

  static const List<String> _statuses = <String>[
    'pending',
    'confirmed',
    'accepted',
    'on_the_way',
    'in_progress',
    'worker_marked_complete',
    'completed',
    'cancelled',
  ];

  int _indexForStatus(String status) {
    final index = _statuses.indexOf(status);
    return index == -1 ? 0 : index;
  }

  String _pretty(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  Color _statusColor(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;
    if (status == 'cancelled') {
      return scheme.error;
    }
    if (status == 'completed') {
      return const Color(0xFF0A8F5A);
    }
    return scheme.primary;
  }

  Future<void> _copyWorkerPhone(BuildContext context, String phone) async {
    await Clipboard.setData(ClipboardData(text: phone));
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Worker phone copied.')));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Job Status / In Progress')),
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
          final currentIndex = _indexForStatus(job.status);
          final color = _statusColor(context, job.status);

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
                          Chip(
                            avatar: Icon(
                              Icons.sync,
                              size: 16,
                              color: color,
                            ),
                            label: Text(_pretty(job.status)),
                          ),
                        ],
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
                        'Live Progress',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._statuses.map((status) {
                        final statusIndex = _indexForStatus(status);
                        final reached = statusIndex <= currentIndex;
                        final isCurrent = status == job.status;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            reached
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: reached ? const Color(0xFF0A8F5A) : null,
                          ),
                          title: Text(
                            _pretty(status),
                            style: TextStyle(
                              fontWeight:
                                  isCurrent ? FontWeight.w700 : FontWeight.w500,
                              color: isCurrent ? color : null,
                            ),
                          ),
                        );
                      }),
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
                        'Worker Contact',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Name: ${job.workerName ?? 'Pending assignment'}'),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              if (job.workerPhone?.isNotEmpty == true)
                OutlinedButton.icon(
                  onPressed: () => _copyWorkerPhone(context, job.workerPhone!),
                  icon: const Icon(Icons.phone),
                  label: Text('Contact Worker (${job.workerPhone})'),
                )
              else
                const Text('Contact option will appear once a worker is assigned.'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => JobCompletionPage(
                        jobId: jobId,
                        repository: repository,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.task_alt_outlined),
                label: const Text('Open Completion Page'),
              ),
            ],
          );
        },
      ),
    );
  }
}
