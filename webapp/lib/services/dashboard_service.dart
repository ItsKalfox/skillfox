import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardService {
  static final _db = FirebaseFirestore.instance;

  static Stream<Map<String, dynamic>> getDashboardStats() async* {
    try {
      final usersSnapshot = await _db.collection('users').get();
      final requestsSnapshot = await _db.collection('requests').get();
      final reportsSnapshot = await _db.collection('reports').get();
      final paymentsSnapshot = await _db.collection('payments').get();

      // Count users
      int totalWorkers = 0;
      int totalCustomers = 0;
      int activeUsers = 0;

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final role = data['role']?.toString().toLowerCase() ?? '';
        final status = data['status']?.toString().toLowerCase() ?? '';
        if (role == 'worker') totalWorkers++;
        if (role == 'customer') totalCustomers++;
        if (status == 'active') activeUsers++;
      }

      // Count requests
      int pendingRequests = 0;
      int completedRequests = 0;
      int cancelledRequests = 0;

      for (var doc in requestsSnapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString().toLowerCase() ?? '';
        if (status == 'pending') pendingRequests++;
        if (status == 'completed') completedRequests++;
        if (status == 'cancelled') cancelledRequests++;
      }

      // Calculate real revenue from payments
      double totalRevenue = 0;
      double completedAmount = 0;
      double pendingAmount = 0;
      double failedAmount = 0;
      int completedTransactions = 0;
      int pendingTransactions = 0;
      int failedTransactions = 0;

      for (var doc in paymentsSnapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString().toLowerCase() ?? '';
        final amount = (data['amount'] ?? 0).toDouble();

        if (status == 'completed') {
          totalRevenue += amount;
          completedAmount += amount;
          completedTransactions++;
        } else if (status == 'pending') {
          pendingAmount += amount;
          pendingTransactions++;
        } else if (status == 'failed') {
          failedAmount += amount;
          failedTransactions++;
        }
      }

      yield {
        'totalRevenue': totalRevenue,
        'totalUsers': usersSnapshot.docs.length,
        'totalWorkers': totalWorkers,
        'totalCustomers': totalCustomers,
        'activeUsers': activeUsers,
        'totalRequests': requestsSnapshot.docs.length,
        'pendingPayments': pendingRequests,
        'completedRequests': completedRequests,
        'cancelledRequests': cancelledRequests,
        'activeDisputes': reportsSnapshot.docs.length,
        'completedAmount': completedAmount,
        'completedTransactions': completedTransactions,
        'pendingAmount': pendingAmount,
        'pendingTransactions': pendingTransactions,
        'failedAmount': failedAmount,
        'failedTransactions': failedTransactions,
      };
    } catch (e) {
      yield {};
    }
  }
}