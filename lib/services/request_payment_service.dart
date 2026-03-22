import 'package:cloud_firestore/cloud_firestore.dart';

class RequestPaymentService {
  RequestPaymentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _requestRef(String requestId) {
    return _firestore.collection('service_requests').doc(requestId);
  }

  Future<void> markInspectionQuote({
    required String requestId,
    required List<Map<String, dynamic>> items,
    required double total,
  }) async {
    await _requestRef(requestId).update({
      'quoteItems': items,
      'quoteTotal': total,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Escrow-like state: payment is held until work completes.
  Future<void> holdPayment({
    required String requestId,
    required double amount,
    required String paymentMethod,
    bool markAsWorking = true,
  }) async {
    final payload = <String, dynamic>{
      'paymentStatus': 'held',
      'paymentAmount': amount,
      'paymentMethod': paymentMethod,
      'paymentHeldAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (markAsWorking) {
      payload['status'] = 'working';
    }

    await _requestRef(requestId).update({
      ...payload,
    });
  }

  Future<void> releaseEscrow({required String requestId}) async {
    await _requestRef(requestId).update({
      'paymentStatus': 'released',
      'paymentReleasedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> requestRefund({
    required String requestId,
    String reason = 'Requested by customer',
  }) async {
    await _requestRef(requestId).update({
      'refundStatus': 'requested',
      'refundReason': reason,
      'refundRequestedAt': FieldValue.serverTimestamp(),
      'paymentStatus': 'refund_requested',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Local simulation endpoint for now.
  Future<void> processRefund({required String requestId}) async {
    await _requestRef(requestId).update({
      'refundStatus': 'refunded',
      'refundProcessedAt': FieldValue.serverTimestamp(),
      'paymentStatus': 'refunded',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
