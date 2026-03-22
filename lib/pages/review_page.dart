import 'package:flutter/material.dart';

import '../services/job_repository.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({
    super.key,
    required this.jobId,
    required this.workerId,
    required this.repository,
  });

  final String jobId;
  final String workerId;
  final JobRepository repository;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  double _rating = 5;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter feedback.')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.repository.submitReview(
        jobId: widget.jobId,
        userId: 'guest-user',
        workerId: widget.workerId,
        rating: _rating,
        feedback: _feedbackController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Review submitted.')));
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to submit review: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Worker')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How was your service?',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your feedback helps maintain quality and trust on the platform.',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Rating: ${_rating.toStringAsFixed(1)} / 5.0',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Slider(
                    value: _rating,
                    min: 1,
                    max: 5,
                    divisions: 8,
                    label: _rating.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _rating = value;
                      });
                    },
                  ),
                  TextField(
                    controller: _feedbackController,
                    minLines: 4,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Feedback',
                      hintText:
                          'Mention punctuality, quality of work, and communication.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submitReview,
            icon: _isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.publish_outlined),
            label: _isSubmitting
                ? const Text('Submitting...')
                : const Text('Submit Review'),
          ),
        ],
      ),
    );
  }
}
