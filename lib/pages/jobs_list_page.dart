import 'package:flutter/material.dart';

import '../models/job.dart';
import '../services/job_repository.dart';
import 'job_status_page.dart';

class JobsListPage extends StatelessWidget {
  const JobsListPage({
    super.key,
    required this.repository,
  });

  final JobRepository repository;

  String _prettyStatus(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('All Jobs')),
      body: StreamBuilder(
        stream: repository.streamJobs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                'No jobs found yet.',
                style: textTheme.titleMedium,
              ),
            );
          }

          final jobs = docs
              .map(Job.fromSnapshot)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final job = jobs[index];

              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  title: Text(
                    job.service,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.description),
                        const SizedBox(height: 8),
                        Text('Location: ${job.location}'),
                        const SizedBox(height: 4),
                        Text('Price: ${job.price.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        Chip(label: Text(_prettyStatus(job.status))),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => JobStatusPage(
                          jobId: job.id,
                          repository: repository,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
