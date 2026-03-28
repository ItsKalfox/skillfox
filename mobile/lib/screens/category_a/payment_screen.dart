import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentScreen extends StatefulWidget {
  final String requestId;
  final double totalAmount;
  final double inspectionFee;
  final double distanceFee;
  final double serviceFee;

  const PaymentScreen({
    super.key,
    required this.requestId,
    required this.totalAmount,
    required this.inspectionFee,
    required this.distanceFee,
    required this.serviceFee,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool loading = false;

  String format(num n) {
    return n.toStringAsFixed(0);
  }

  Future<void> completePayment() async {
    setState(() => loading = true);

    try {
      final requestSnap = await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .get();
      final d = requestSnap.data() ?? {};

      final amount = widget.totalAmount;
      final commission = (amount * 0.10).roundToDouble();
      final netAmount = amount - commission;

      // Write to payments collection
      await FirebaseFirestore.instance.collection('payments').add({
        'requestId': widget.requestId,
        'amount': amount,
        'commission': commission,
        'netAmount': netAmount,
        'status': 'completed',
        'service': d['category'] ?? '',
        'workerId': d['workerId'] ?? '',
        'workerName': d['workerName'] ?? '',
        'customerId': d['customerId'] ?? '',
        'customerName': d['customerName'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update request status
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
            'status': 'inprogress',
            'paymentStatus': 'paid',
            'paidAt': FieldValue.serverTimestamp(),
            'totalPaid': amount,
          });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: \$e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Total: LKR ${format(widget.totalAmount)}"),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : completePayment,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Payment Done"),
            ),
          ],
        ),
      ),
    );
  }
}
