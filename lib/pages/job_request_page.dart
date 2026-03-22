import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/job_repository.dart';
import 'job_confirmation_page.dart';
import 'jobs_list_page.dart';

class JobRequestPage extends StatefulWidget {
  const JobRequestPage({super.key, required this.repository});

  final JobRepository repository;

  @override
  State<JobRequestPage> createState() => _JobRequestPageState();
}

class _JobRequestPageState extends State<JobRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController(text: '50');

  final List<String> _services = const <String>[
    'Plumbing',
    'Electrical',
    'Cleaning',
    'Painting',
    'Appliance Repair',
  ];

  DateTime? _selectedDateTime;
  String? _selectedService;
  bool _isSubmitting = false;
  List<XFile> _images = const [];

  String _formatDateTime(DateTime dateTime) {
    final date =
        '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$date at $hour:$minute $period';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: now,
      initialDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final selected = await picker.pickMultiImage(imageQuality: 80);
    if (!mounted) {
      return;
    }

    setState(() {
      _images = selected;
    });
  }

  Future<void> _submitJob() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final jobId = await widget.repository.createJob(
        userId: 'guest-user',
        service: _selectedService!,
        description: _descriptionController.text.trim(),
        scheduledAt: _selectedDateTime!,
        location: _locationController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        images: _images,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => JobConfirmationPage(
            jobId: jobId,
            repository: widget.repository,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create job: $error')),
      );
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Job Request'),
        actions: [
          IconButton(
            tooltip: 'All jobs',
            icon: const Icon(Icons.list_alt_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => JobsListPage(
                    repository: widget.repository,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Book a Trusted Worker',
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Share your request details and we will guide it through confirmation, tracking, and completion.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.schedule, size: 18),
                    label: Text(
                      _selectedDateTime == null
                          ? 'No schedule selected'
                          : _formatDateTime(_selectedDateTime!),
                    ),
                  ),
                  Chip(
                    avatar: const Icon(Icons.photo_library_outlined, size: 18),
                    label: Text('${_images.length} image(s) attached'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request Details',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedService,
                        decoration: const InputDecoration(
                          labelText: 'Service Category',
                        ),
                        items: _services
                            .map(
                              (service) => DropdownMenuItem<String>(
                                value: service,
                                child: Text(service),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedService = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Select a service';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Job Description',
                          hintText:
                              'Describe the issue and any special instructions.',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 10) {
                            return 'Enter at least 10 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Service Location',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a location';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Estimated Budget',
                          prefixText: '\$ ',
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _pickDateTime,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          _selectedDateTime == null
                              ? 'Choose Date and Time'
                              : _formatDateTime(_selectedDateTime!),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: Text(
                          _images.isEmpty
                              ? 'Upload Optional Reference Images'
                              : 'Update Attached Images (${_images.length})',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitJob,
                icon: _isSubmitting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(
                  _isSubmitting ? 'Submitting Request...' : 'Submit Job Request',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
