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

    await FirebaseFirestore.instance
        .collection('requests')
        .doc(widget.requestId)
        .update({
          'status': 'inprogress',
          'paymentStatus': 'paid',
          'paidAt': FieldValue.serverTimestamp(),
        });

    Navigator.pop(context); // 🔥 go back to waiting screen
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
