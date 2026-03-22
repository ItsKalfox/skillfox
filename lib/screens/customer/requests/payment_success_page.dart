import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'request_status_page.dart';

class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({
    super.key,
    required this.requestId,
    required this.workerName,
    required this.workerCategory,
    required this.workerPhotoUrl,
    required this.amount,
  });

  final String requestId;
  final String workerName;
  final String workerCategory;
  final String workerPhotoUrl;
  final double amount;

  String _formatLkr(double value) => 'LKR ${value.toStringAsFixed(0)}';

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
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => RequestStatusPage(requestId: requestId),
              ),
              (route) => route.isFirst,
            );
          },
        ),
        title: const Text(
          'Payment Successful',
          style: TextStyle(
            color: Color(0xFF1B1B1D),
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),
            Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFB7F0D0),
              ),
              child: Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF84E5B8),
                  ),
                  child: const Center(
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Color(0xFF0E9548),
                      child: Icon(Icons.check, color: Colors.white, size: 54),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              _formatLkr(amount),
              style: const TextStyle(fontSize: 28 / 2, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment successful! Worker will now start your work',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFD7D7DE),
                    backgroundImage: workerPhotoUrl.trim().isNotEmpty
                        ? NetworkImage(workerPhotoUrl)
                        : null,
                    child: workerPhotoUrl.trim().isEmpty
                        ? const Icon(Icons.person, color: Color(0xFF666670))
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '($workerCategory)',
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
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.mainGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => RequestStatusPage(requestId: requestId),
                        ),
                        (route) => route.isFirst,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
