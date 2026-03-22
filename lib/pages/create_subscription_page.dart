import 'package:flutter/material.dart';

import '../services/subscription_service.dart';
import 'subscription_detail_shell_page.dart';

class CreateSubscriptionPage extends StatefulWidget {
  const CreateSubscriptionPage({super.key});

  @override
  State<CreateSubscriptionPage> createState() => _CreateSubscriptionPageState();
}

class _CreateSubscriptionPageState extends State<CreateSubscriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = SubscriptionService();

  final _serviceTypeController = TextEditingController(text: 'Home Cleaning');
  final _durationCountController = TextEditingController(text: '3');
  final _sessionsPerCycleController = TextEditingController(text: '1');
  final _preferredScheduleController = TextEditingController(
    text: 'Saturdays at 10:00 AM',
  );
  final _priceController = TextEditingController(text: '45');

  String _frequency = 'weekly';
  String _paymentMethod = 'card';
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  bool _loading = false;

  @override
  void dispose() {
    _serviceTypeController.dispose();
    _durationCountController.dispose();
    _sessionsPerCycleController.dispose();
    _preferredScheduleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  int get _totalSessions {
    final duration = int.tryParse(_durationCountController.text) ?? 0;
    final sessionsPerCycle = int.tryParse(_sessionsPerCycleController.text) ?? 0;
    return duration * sessionsPerCycle;
  }

  double get _totalPrice {
    final price = double.tryParse(_priceController.text) ?? 0;
    return _totalSessions * price;
  }

  Future<void> _pickStartDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      initialDate: _startDate,
    );
    if (selected != null) {
      setState(() {
        _startDate = selected;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final subscriptionId = await _service.createSubscription(
        serviceType: _serviceTypeController.text.trim(),
        frequency: _frequency,
        durationCount: int.parse(_durationCountController.text),
        sessionsPerCycle: int.parse(_sessionsPerCycleController.text),
        startDate: _startDate,
        preferredSchedule: _preferredScheduleController.text.trim(),
        pricePerSession: double.parse(_priceController.text),
        paymentMethod: _paymentMethod,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => SubscriptionDetailShellPage(
            subscriptionId: subscriptionId,
            initialIndex: 0,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create subscription: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Subscription')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Service Setup',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _serviceTypeController,
                      decoration: const InputDecoration(labelText: 'Service Type'),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _frequency,
                      items: const [
                        DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                        DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _frequency = value);
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Frequency'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _durationCountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _frequency == 'weekly'
                            ? 'Duration (weeks)'
                            : 'Duration (months)',
                      ),
                      validator: (value) {
                        final parsed = int.tryParse(value ?? '');
                        if (parsed == null || parsed <= 0) return 'Enter valid number';
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sessionsPerCycleController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Sessions Per Cycle'),
                      validator: (value) {
                        final parsed = int.tryParse(value ?? '');
                        if (parsed == null || parsed <= 0) return 'Enter valid number';
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _preferredScheduleController,
                      decoration: const InputDecoration(
                        labelText: 'Preferred Schedule (e.g. Tue 9 AM)',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Required' : null,
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
                      'Billing & Start',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Start Date'),
                      subtitle: Text(_formatDate(_startDate)),
                      trailing: TextButton(
                        onPressed: _pickStartDate,
                        child: const Text('Choose'),
                      ),
                    ),
                    TextFormField(
                      controller: _priceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Price Per Session'),
                      validator: (value) {
                        final parsed = double.tryParse(value ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Enter valid amount';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _paymentMethod,
                      items: const [
                        DropdownMenuItem(value: 'card', child: Text('Card')),
                        DropdownMenuItem(
                          value: 'bank_transfer',
                          child: Text('Bank Transfer'),
                        ),
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _paymentMethod = value);
                        }
                      },
                      decoration:
                          const InputDecoration(labelText: 'Payment Method'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pricing Confirmation',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text('Total Sessions: $_totalSessions'),
                    Text('Estimated Total: ${_totalPrice.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loading ? null : _submit,
              icon:
                  _loading
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.check),
              label: const Text('Confirm & Create Subscription'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
