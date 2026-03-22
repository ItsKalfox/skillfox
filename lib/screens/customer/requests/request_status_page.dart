import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/request_payment_service.dart';
import 'pay_worker_page.dart';

class RequestStatusPage extends StatelessWidget {
  const RequestStatusPage({super.key, required this.requestId});

  final String requestId;
  static final RequestPaymentService _paymentService = RequestPaymentService();

  static const _statusOrder = [
    'pending',
    'arriving',
    'inspection',
    'working',
    'finished',
  ];

  static const _statusLabels = {
    'pending': 'Request',
    'arriving': 'Arriving',
    'inspection': 'Inspection',
    'working': 'Working',
    'finished': 'Finished',
    'unavailable': 'Unavailable',
  };

  int _statusIndex(String status) {
    final i = _statusOrder.indexOf(status);
    return i == -1 ? 0 : i;
  }

  String _titleFor(String status) {
    switch (status) {
      case 'arriving':
        return 'Worker on the Way';
      case 'inspection':
        return 'Service Quotation';
      case 'working':
        return 'Work in Progress';
      case 'finished':
        return 'Request accepted';
      case 'unavailable':
        return 'Provider Unavailable';
      default:
        return 'Request Sent';
    }
  }

  String _messageFor(String status) {
    switch (status) {
      case 'arriving':
        return 'Worker Accepted - "Worker On The Way"';
      case 'inspection':
        return 'Review the service details and confirm to proceed.';
      case 'working':
        return 'Worker Accepted - "Work In Progress"';
      case 'finished':
        return 'Enrollment successful! Use below code as entry access';
      case 'unavailable':
        return 'The provider is currently busy and unable to accept your request.';
      default:
        return 'Waiting for the provider to accept your request.';
    }
  }

  String _paymentLabel(String paymentStatus) {
    switch (paymentStatus) {
      case 'held':
        return 'Payment held in escrow';
      case 'released':
        return 'Payment released to worker';
      case 'refund_requested':
        return 'Refund requested';
      case 'refunded':
        return 'Refund completed';
      default:
        return 'Payment pending';
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
        title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('service_requests')
              .doc(requestId)
              .snapshots(),
          builder: (context, snapshot) {
            final status = (snapshot.data?.data()?['status'] as String?) ?? 'pending';
            return Text(
              _titleFor(status),
              style: const TextStyle(
                color: Color(0xFF1B1B1D),
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            );
          },
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('service_requests')
            .doc(requestId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data();
          if (data == null) {
            return const Center(child: Text('Request not found'));
          }

          final status = (data['status'] as String?) ?? 'pending';
          final currentIndex = _statusIndex(status);

          final workerName = (data['workerName'] as String?)?.trim().isNotEmpty == true
              ? (data['workerName'] as String)
              : 'Assigned Worker';
          final workerCategory = (data['workerCategory'] as String?)?.trim().isNotEmpty == true
              ? (data['workerCategory'] as String)
              : 'Provider';
          final workerPhotoUrl = (data['workerPhotoUrl'] as String?) ?? '';
          final workerPhone = (data['workerPhone'] as String?)?.trim().isNotEmpty == true
              ? (data['workerPhone'] as String)
              : '+94XX XXXXXXX';
            final paymentStatus = (data['paymentStatus'] as String?) ?? 'unpaid';
            final refundStatus = (data['refundStatus'] as String?) ?? '';

          final price = (data['price'] as num?)?.toDouble() ?? 0;
          final distance = (data['distanceKm'] as num?)?.toDouble() ?? 5.8;
          final canPayOnFinished = paymentStatus == 'unpaid';

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            children: [
              _HeroVisual(status: status),
              const SizedBox(height: 18),
              Text(
                _messageFor(status),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF33333A),
                  fontSize: 30 / 2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              if (status != 'unavailable')
                _ProgressTimeline(
                  labels: _statusOrder.map((s) => _statusLabels[s]!).toList(),
                  currentIndex: currentIndex,
                ),
              const SizedBox(height: 16),
              _WorkerCard(
                name: workerName,
                category: workerCategory,
                rating: 4.5,
                photoUrl: workerPhotoUrl,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text(
                    'Payment',
                    style: TextStyle(fontSize: 12, color: Color(0xFF7A7A80)),
                  ),
                  const Spacer(),
                  Text(
                    _paymentLabel(paymentStatus),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B7DF3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (status == 'inspection') ...[
                const _DetailRow(label: 'Engine diagnostic', value: 'LKR 5,000'),
                const SizedBox(height: 8),
                const _DetailRow(label: 'Labor charge', value: 'LKR 6,000'),
                const SizedBox(height: 8),
                _DetailRow(label: 'Total', value: 'LKR ${price.toStringAsFixed(0)}'),
              ] else ...[
                _DetailRow(label: 'Estimated Arrival', value: status == 'arriving' ? '14 minutes' : '18 - 22 minutes'),
                const SizedBox(height: 8),
                _DetailRow(label: 'Distance Remaining', value: '${distance.toStringAsFixed(1)} km'),
              ],
              const SizedBox(height: 14),
              Container(height: 1, color: const Color(0xFFD0D0D5)),
              const SizedBox(height: 14),
              if (status == 'finished') ...[
                Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8D8DE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      '9999',
                      style: TextStyle(fontSize: 34 / 2, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _GradientButton(
                        text: canPayOnFinished ? 'Pay Now' : 'Paid',
                        onTap: canPayOnFinished
                            ? () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PayWorkerPage(
                                      requestId: requestId,
                                      workerName: workerName,
                                      workerCategory: workerCategory,
                                      workerPhotoUrl: workerPhotoUrl,
                                      total: price,
                                      markAsWorking: false,
                                    ),
                                  ),
                                )
                            : () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _GradientButton(
                        text: 'OK',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ] else if (status == 'unavailable') ...[
                _GradientButton(
                  text: 'Find Another Provider',
                  onTap: () => Navigator.of(context).pop(),
                ),
              ] else if (status == 'inspection') ...[
                Row(
                  children: [
                    Expanded(
                      child: _GradientButton(
                        text: 'Proceed to Pay',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PayWorkerPage(
                              requestId: requestId,
                              workerName: workerName,
                              workerCategory: workerCategory,
                              workerPhotoUrl: workerPhotoUrl,
                              total: price,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF9A9AA3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SizedBox(
                          height: 52,
                          child: TextButton(
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .collection('service_requests')
                                  .doc(requestId)
                                  .update({'status': 'unavailable', 'updatedAt': FieldValue.serverTimestamp()});
                            },
                            child: const Text('Reject', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                _CallButton(phone: workerPhone),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF9A9AA3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SizedBox(
                    height: 52,
                    child: TextButton(
                      onPressed: () {
                        FirebaseFirestore.instance
                            .collection('service_requests')
                            .doc(requestId)
                            .update({'status': 'cancelled', 'updatedAt': FieldValue.serverTimestamp()});
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Cancel Request',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                if ((status == 'cancelled' || status == 'unavailable') &&
                    paymentStatus == 'held') ...[
                  const SizedBox(height: 12),
                  _GradientButton(
                    text: 'Request Refund',
                    onTap: () async {
                      await _paymentService.requestRefund(requestId: requestId);
                    },
                  ),
                ],
                if (refundStatus == 'requested') ...[
                  const SizedBox(height: 12),
                  _GradientButton(
                    text: 'Process Refund',
                    onTap: () async {
                      await _paymentService.processRefund(requestId: requestId);
                    },
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual({required this.status});

  final String status;

  String _assetFor(String s) {
    switch (s) {
      case 'finished':
        return 'assets/images/signup-clipart.png';
      case 'working':
        return 'assets/images/worker-icon.png';
      case 'unavailable':
        return 'assets/images/password-change-clipart.png';
      default:
        return 'assets/images/password-change-clipart.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (status == 'arriving') {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFFE8E8EB),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: const Center(
          child: Icon(Icons.route_rounded, size: 82, color: Color(0xFF4B7DF3)),
        ),
      );
    }

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Image.asset(
        _assetFor(status),
        fit: BoxFit.contain,
      ),
    );
  }
}

class _ProgressTimeline extends StatelessWidget {
  const _ProgressTimeline({required this.labels, required this.currentIndex});

  final List<String> labels;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(labels.length, (i) {
            final active = i <= currentIndex;
            return Text(
              labels[i],
              style: TextStyle(
                fontSize: 11,
                color: active ? const Color(0xFF5C63F2) : const Color(0xFF8F8F96),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(height: 6, decoration: BoxDecoration(color: const Color(0xFFC4C4CB), borderRadius: BorderRadius.circular(50))),
            FractionallySizedBox(
              widthFactor: (currentIndex + 1) / labels.length,
              child: Container(height: 6, decoration: BoxDecoration(color: const Color(0xFF5962F2), borderRadius: BorderRadius.circular(50))),
            ),
          ],
        ),
      ],
    );
  }
}

class _WorkerCard extends StatelessWidget {
  const _WorkerCard({
    required this.name,
    required this.category,
    required this.rating,
    required this.photoUrl,
  });

  final String name;
  final String category;
  final double rating;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFD7D7DE),
          backgroundImage: photoUrl.trim().isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl.trim().isEmpty
              ? const Icon(Icons.person, color: Color(0xFF666670))
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 16 / 2, fontWeight: FontWeight.w600)),
              Text('($category)', style: const TextStyle(color: Color(0xFF7A7A80), fontSize: 12)),
            ],
          ),
        ),
        const Icon(Icons.star, color: Colors.amber, size: 16),
        const SizedBox(width: 3),
        Text(rating.toStringAsFixed(1), style: const TextStyle(color: Color(0xFF707078))),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF2B2B31), fontSize: 16 / 2)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Color(0xFF707078), fontSize: 16 / 2)),
      ],
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD7D7DE),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.phone, color: Color(0xFF2B2B31)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Call the Worker  $phone',
              style: const TextStyle(color: Color(0xFF1B1B1D), fontSize: 16 / 2),
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF1B1B1D)),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.mainGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
