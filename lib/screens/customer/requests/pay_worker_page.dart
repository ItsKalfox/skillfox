import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/request_payment_service.dart';
import 'payment_success_page.dart';

class PayWorkerPage extends StatefulWidget {
  const PayWorkerPage({
    super.key,
    required this.requestId,
    required this.workerName,
    required this.workerCategory,
    required this.workerPhotoUrl,
    required this.total,
    this.markAsWorking = true,
  });

  final String requestId;
  final String workerName;
  final String workerCategory;
  final String workerPhotoUrl;
  final double total;
  final bool markAsWorking;

  @override
  State<PayWorkerPage> createState() => _PayWorkerPageState();
}

class _PayWorkerPageState extends State<PayWorkerPage> {
  final RequestPaymentService _paymentService = RequestPaymentService();
  bool _isPaying = false;

  String _formatLkr(double amount) => 'LKR ${amount.toStringAsFixed(0)}';

  Future<void> _payNow() async {
    setState(() {
      _isPaying = true;
    });

    try {
      await _paymentService.holdPayment(
        requestId: widget.requestId,
        amount: widget.total,
        paymentMethod: 'mastercard_9999',
        markAsWorking: widget.markAsWorking,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentSuccessPage(
            requestId: widget.requestId,
            workerName: widget.workerName,
            workerCategory: widget.workerCategory,
            workerPhotoUrl: widget.workerPhotoUrl,
            amount: widget.total,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPaying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1B1B1D)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Pay the Worker',
          style: TextStyle(
            color: Color(0xFF1B1B1D),
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            SizedBox(
              height: 220,
              child: Image.asset('assets/images/signup-clipart.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFD7D7DE),
                  backgroundImage: widget.workerPhotoUrl.trim().isNotEmpty
                      ? NetworkImage(widget.workerPhotoUrl)
                      : null,
                  child: widget.workerPhotoUrl.trim().isEmpty
                      ? const Icon(Icons.person, color: Color(0xFF666670))
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.workerName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        '(${widget.workerCategory})',
                        style: const TextStyle(color: Color(0xFF7A7A80), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 3),
                const Text('4.5', style: TextStyle(color: Color(0xFF707078))),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: const Color(0xFFD0D0D5)),
            const SizedBox(height: 14),
            const Text(
              'Services Included',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            const _LineItem('Engine diagnostic', 'LKR 5,000'),
            const _LineItem('Brake pad replacement', 'LKR 14,000'),
            const _LineItem('Labor charge', 'LKR 6,000'),
            const _LineItem('Oil Change', 'LKR 9,000'),
            const _LineItem('Battery Replacement', 'LKR 13,500'),
            const _LineItem('Labor charge', 'LKR 6,000'),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(
                  _formatLkr(widget.total),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFD7D7DE),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: const Row(
                children: [
                  Icon(Icons.credit_card, color: Color(0xFF2B2B31)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Mastercard  **** 9999'),
                  ),
                  Icon(Icons.chevron_right, color: Color(0xFF1B1B1D)),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.mainGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isPaying ? null : _payNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isPaying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Pay Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineItem extends StatelessWidget {
  const _LineItem(this.name, this.price);

  final String name;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(name, style: const TextStyle(color: Color(0xFF7A7A80), fontSize: 13)),
          const Spacer(),
          Text(price, style: const TextStyle(color: Color(0xFF7A7A80), fontSize: 13)),
        ],
      ),
    );
  }
}
