import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionService {
  SubscriptionService({FirebaseFirestore? firestore, String? userId})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _userId = userId ?? 'local-user';

  final FirebaseFirestore _firestore;
  final String _userId;

  Stream<QuerySnapshot<Map<String, dynamic>>> subscriptionsStream() {
    return _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> subscriptionStream(
    String subscriptionId,
  ) {
    return _firestore.collection('subscriptions').doc(subscriptionId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> sessionsStream(String subscriptionId) {
    return _firestore
        .collection('sessions')
        .where('userId', isEqualTo: _userId)
        .where('subscriptionId', isEqualTo: subscriptionId)
        .orderBy('scheduledAt')
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> sessionStream(String sessionId) {
    return _firestore.collection('sessions').doc(sessionId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> invoicesStream(String subscriptionId) {
    return _firestore
        .collection('invoices')
        .where('userId', isEqualTo: _userId)
        .where('subscriptionId', isEqualTo: subscriptionId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<String> createSubscription({
    required String serviceType,
    required String frequency,
    required int durationCount,
    required int sessionsPerCycle,
    required DateTime startDate,
    required String preferredSchedule,
    required double pricePerSession,
    required String paymentMethod,
  }) async {
    final userId = _userId;
    final subscriptionsRef = _firestore.collection('subscriptions').doc();
    final totalSessions = durationCount * sessionsPerCycle;
    final totalPrice = totalSessions * pricePerSession;
    final now = Timestamp.now();

    final assignedWorker = <String, dynamic>{
      'id': 'pending',
      'name': 'Worker assignment in progress',
      'phone': null,
    };

    final batch = _firestore.batch();

    batch.set(subscriptionsRef, {
      'userId': userId,
      'serviceType': serviceType,
      'frequency': frequency,
      'durationCount': durationCount,
      'sessionsPerCycle': sessionsPerCycle,
      'sessions': totalSessions,
      'startDate': Timestamp.fromDate(startDate),
      'preferredSchedule': preferredSchedule,
      'pricePerSession': pricePerSession,
      'paymentMethod': paymentMethod,
      'totalPrice': totalPrice,
      'status': 'active',
      'assignedWorker': assignedWorker,
      'createdAt': now,
      'updatedAt': now,
    });

    for (var index = 0; index < totalSessions; index++) {
      final scheduledDate = _buildSessionDate(
        startDate: startDate,
        frequency: frequency,
        sessionIndex: index,
      );
      final sessionRef = _firestore.collection('sessions').doc();
      batch.set(sessionRef, {
        'userId': userId,
        'subscriptionId': subscriptionsRef.id,
        'sessionNumber': index + 1,
        'scheduledAt': Timestamp.fromDate(scheduledDate),
        'status': 'upcoming',
        'progressNote': 'Scheduled',
        'createdAt': now,
        'updatedAt': now,
      });
    }

    final firstInvoiceRef = _firestore.collection('invoices').doc();
    final invoiceAmount = sessionsPerCycle * pricePerSession;
    batch.set(firstInvoiceRef, {
      'userId': userId,
      'subscriptionId': subscriptionsRef.id,
      'amount': invoiceAmount,
      'dueDate': Timestamp.fromDate(_nextDueDate(startDate, frequency)),
      'status': 'due',
      'paymentState': 'pending',
      'escrowStatus': 'not_funded',
      'escrowAmount': 0,
      'refundStatus': 'none',
      'refundedAmount': 0,
      'paymentMethod': paymentMethod,
      'billingCycle': 1,
      'createdAt': now,
      'updatedAt': now,
    });

    await batch.commit();
    return subscriptionsRef.id;
  }

  Future<void> updateSubscriptionStatus({
    required String subscriptionId,
    required String status,
  }) async {
    await _firestore.collection('subscriptions').doc(subscriptionId).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });

    if (status == 'canceled') {
      final query = await _firestore
          .collection('sessions')
          .where('subscriptionId', isEqualTo: subscriptionId)
          .where('status', isEqualTo: 'upcoming')
          .get();
      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.update(doc.reference, {
          'status': 'canceled',
          'updatedAt': Timestamp.now(),
        });
      }
      await batch.commit();
    }
  }

  Future<void> setSessionStatus({
    required String sessionId,
    required String status,
    String? progressNote,
  }) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'status': status,
      'progressNote': progressNote,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> rescheduleSession({
    required String sessionId,
    required DateTime newDate,
  }) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'scheduledAt': Timestamp.fromDate(newDate),
      'status': 'upcoming',
      'progressNote': 'Rescheduled by customer',
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> generateInvoice({
    required String subscriptionId,
    required double amount,
    required DateTime dueDate,
    required String paymentMethod,
    required int billingCycle,
  }) async {
    await _firestore.collection('invoices').add({
      'userId': _userId,
      'subscriptionId': subscriptionId,
      'amount': amount,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': 'due',
      'paymentState': 'pending',
      'escrowStatus': 'not_funded',
      'escrowAmount': 0,
      'refundStatus': 'none',
      'refundedAmount': 0,
      'paymentMethod': paymentMethod,
      'billingCycle': billingCycle,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> markInvoicePaid(String invoiceId) async {
    final invoiceDoc = await _firestore.collection('invoices').doc(invoiceId).get();
    final amount = (invoiceDoc.data()?['amount'] as num?)?.toDouble() ?? 0;
    await _firestore.collection('invoices').doc(invoiceId).update({
      'status': 'paid',
      'paymentState': 'captured',
      'escrowStatus': 'funded',
      'escrowAmount': amount,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> updateInvoicePaymentState({
    required String invoiceId,
    required String paymentState,
  }) async {
    await _firestore.collection('invoices').doc(invoiceId).update({
      'paymentState': paymentState,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> releaseEscrow(String invoiceId) async {
    await _firestore.collection('invoices').doc(invoiceId).update({
      'escrowStatus': 'released',
      'paymentState': 'settled',
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> requestRefund({
    required String invoiceId,
    required double amount,
    required String reason,
  }) async {
    await _firestore.collection('invoices').doc(invoiceId).update({
      'refundStatus': 'requested',
      'refundReason': reason,
      'refundRequestedAmount': amount,
      'paymentState': 'refund_requested',
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> completeRefund(String invoiceId) async {
    final invoiceDoc = await _firestore.collection('invoices').doc(invoiceId).get();
    final requestedAmount =
        (invoiceDoc.data()?['refundRequestedAmount'] as num?)?.toDouble() ?? 0;

    await _firestore.collection('invoices').doc(invoiceId).update({
      'status': 'refunded',
      'refundStatus': 'refunded',
      'refundedAmount': requestedAmount,
      'escrowStatus': 'refunded',
      'escrowAmount': 0,
      'paymentState': 'refunded',
      'updatedAt': Timestamp.now(),
    });
  }

  DateTime _buildSessionDate({
    required DateTime startDate,
    required String frequency,
    required int sessionIndex,
  }) {
    if (frequency == 'monthly') {
      return DateTime(
        startDate.year,
        startDate.month + sessionIndex,
        startDate.day,
        startDate.hour,
        startDate.minute,
      );
    }
    return startDate.add(Duration(days: sessionIndex * 7));
  }

  DateTime _nextDueDate(DateTime startDate, String frequency) {
    if (frequency == 'monthly') {
      return DateTime(startDate.year, startDate.month + 1, startDate.day);
    }
    return startDate.add(const Duration(days: 7));
  }
}
