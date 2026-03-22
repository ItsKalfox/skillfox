import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuotationScreen extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const QuotationScreen({
    super.key,
    required this.requestId,
    required this.requestData,
  });

  @override
  State<QuotationScreen> createState() => _QuotationScreenState();
}

class _QuotationScreenState extends State<QuotationScreen> {
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _sendQuotation() async {
    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
        'quotationPrice': double.tryParse(_priceCtrl.text) ?? 0,
        'quotationDesc': _descCtrl.text,
        'quotationSent': true,
      });

      Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Quotation')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            controller: _priceCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Price (LKR)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loading ? null : _sendQuotation,
            child: _loading
                ? const CircularProgressIndicator()
                : const Text('Send Quotation'),
          )
        ]),
      ),
    );
  }
}