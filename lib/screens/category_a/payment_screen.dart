

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentScreen extends StatelessWidget {
  final String requestId;

  const PaymentScreen({
    super.key,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .doc(requestId)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          double amount = (data['inspectionFee'] ?? 0).toDouble();
          double distance = (data['distanceKm'] ?? 0).toDouble();

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                const SizedBox(height: 20),

                Text(
                  "Payment Summary",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                row("Distance", "${distance.toStringAsFixed(2)} km"),
                row("Total Amount", "Rs. ${amount.toStringAsFixed(2)}"),

                const Spacer(),

                ElevatedButton(
                  onPressed: () async {
  final doc = await FirebaseFirestore.instance
      .collection('requests')
      .doc(requestId)
      .get();

  final data = doc.data()!;

  double amount = (data['inspectionFee'] ?? 0).toDouble();
  double distance = (data['distanceKm'] ?? 0).toDouble();

  // 🔥 fallback safety
  if (amount == 0) {
    amount = 500;
  }

  await FirebaseFirestore.instance
      .collection('requests')
      .doc(requestId)
      .update({
    "status": "paid",
    "inspectionFee": amount,
    "distanceKm": distance,
  });

  Navigator.pop(context);
},
                  child: const Text("Confirm Payment"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}