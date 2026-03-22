import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/subscription_service.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({required this.subscriptionId, super.key});

  final String subscriptionId;

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final _service = SubscriptionService();
  bool _generating = false;

  Future<void> _requestRefundDialog(String invoiceId) async {
    final amountController = TextEditingController();
    final reasonController = TextEditingController(text: 'Service issue');

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Request Refund'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (approved != true) return;
    final amount = double.tryParse(amountController.text) ?? 0;
    if (amount <= 0) return;

    await _service.requestRefund(
      invoiceId: invoiceId,
      amount: amount,
      reason: reasonController.text.trim(),
    );
  }

  Future<void> _generateNextInvoice() async {
    setState(() => _generating = true);
    try {
      final subscriptionDoc = await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(widget.subscriptionId)
          .get();
      final subscription = subscriptionDoc.data();
      if (subscription == null) return;

      final frequency = (subscription['frequency'] ?? 'weekly').toString();
      final paymentMethod = (subscription['paymentMethod'] ?? 'card').toString();
        final sessionsPerCycle =
          (subscription['sessionsPerCycle'] as num?)?.toInt() ?? 1;
      final pricePerSession =
          (subscription['pricePerSession'] as num?)?.toDouble() ?? 0;

      final existingInvoices = await FirebaseFirestore.instance
          .collection('invoices')
          .where('subscriptionId', isEqualTo: widget.subscriptionId)
          .orderBy('billingCycle', descending: true)
          .limit(1)
          .get();

      final lastCycle =
          existingInvoices.docs.isEmpty
              ? 0
            :
              (existingInvoices.docs.first.data()['billingCycle'] as num?)
                ?.toInt() ??
              0;

      final dueDate =
          frequency == 'monthly'
              ? DateTime.now().add(const Duration(days: 30))
              : DateTime.now().add(const Duration(days: 7));

      await _service.generateInvoice(
        subscriptionId: widget.subscriptionId,
        amount: sessionsPerCycle * pricePerSession,
        dueDate: dueDate,
        paymentMethod: paymentMethod,
        billingCycle: lastCycle + 1,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Next billing cycle invoice generated.')),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Invoices & Payment History',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FilledButton(
                onPressed: _generating ? null : _generateNextInvoice,
                child: const Text('Generate Invoice'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _service.invoicesStream(widget.subscriptionId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final invoices = snapshot.data!.docs;
              if (invoices.isEmpty) {
                return const Center(child: Text('No invoices found yet.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: invoices.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final invoice = invoices[index].data();
                  final status = (invoice['status'] ?? 'due').toString();

                  return Card(
                    child: ListTile(
                      title: Text(
                        'Cycle #${invoice['billingCycle'] ?? '-'} - ${invoice['amount'] ?? 0}',
                      ),
                      subtitle: Text(
                        'Due: ${_formatTimestamp(invoice['dueDate'] as Timestamp?)}\n'
                        'Method: ${invoice['paymentMethod'] ?? '-'}\n'
                        'Status: $status\n'
                        'Payment state: ${invoice['paymentState'] ?? 'pending'}\n'
                        'Escrow: ${invoice['escrowStatus'] ?? 'not_funded'}\n'
                        'Refund: ${invoice['refundStatus'] ?? 'none'}',
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          ),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _service.invoicesStream(widget.subscriptionId),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const SizedBox.shrink();
            }

            final latest = snapshot.data!.docs.first;
            final invoice = latest.data();
            final invoiceId = latest.id;

            return Container(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _service.markInvoicePaid(invoiceId),
                    child: const Text('Mark Paid'),
                  ),
                  OutlinedButton(
                    onPressed: () => _service.releaseEscrow(invoiceId),
                    child: const Text('Release Escrow'),
                  ),
                  OutlinedButton(
                    onPressed: () => _requestRefundDialog(invoiceId),
                    child: const Text('Request Refund'),
                  ),
                  OutlinedButton(
                    onPressed: () => _service.completeRefund(invoiceId),
                    child: const Text('Complete Refund'),
                  ),
                  OutlinedButton(
                    onPressed: () => _service.updateInvoicePaymentState(
                      invoiceId: invoiceId,
                      paymentState: 'authorized',
                    ),
                    child: const Text('Set Authorized'),
                  ),
                  if ((invoice['paymentState'] ?? '') == 'authorized')
                    OutlinedButton(
                      onPressed: () => _service.updateInvoicePaymentState(
                        invoiceId: invoiceId,
                        paymentState: 'captured',
                      ),
                      child: const Text('Capture Payment'),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '-';
    final date = ts.toDate();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }
}
