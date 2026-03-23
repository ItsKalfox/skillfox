import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/wallet_service.dart';

class CustomerBookingHistoryScreen extends StatefulWidget {
  const CustomerBookingHistoryScreen({super.key});

  @override
  State<CustomerBookingHistoryScreen> createState() =>
      _CustomerBookingHistoryScreenState();
}

class _CustomerBookingHistoryScreenState extends State<CustomerBookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final WalletService _walletService = WalletService();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (_uid.isNotEmpty) {
      _walletService.ensureWallet(_uid);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _money(num n) => 'LKR ${n.toStringAsFixed(2)}';

  String _date(DateTime? d) {
    if (d == null) return 'No date';
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$month-$day ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Widget _empty(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF666666),
        ),
      ),
    );
  }

  Widget _buildBookingList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('service_requests')
          .where('customerId', isEqualTo: _uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _empty('Failed to load bookings. Please try again.');
        }

        final docs = (snapshot.data?.docs ?? const [])..sort((a, b) {
          final aDate =
              (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          final bDate =
              (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          return bDate.compareTo(aDate);
        });

        if (docs.isEmpty) {
          return _empty('No booking history yet.');
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final worker = (data['workerName'] as String?)?.trim().isNotEmpty == true
                ? data['workerName'] as String
                : 'Worker';
            final service = (data['serviceType'] as String?)?.trim().isNotEmpty == true
                ? data['serviceType'] as String
                : (data['service'] as String?) ?? 'Service';
            final status = (data['status'] as String?) ?? 'pending';
            final amount = (data['paymentAmount'] as num?)?.toDouble() ??
                (data['price'] as num?)?.toDouble() ??
                0.0;
            final createdAt =
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE7ECF4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          worker,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        _money(amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Service: $service'),
                  const SizedBox(height: 2),
                  Text('Status: $status'),
                  const SizedBox(height: 2),
                  Text(_date(createdAt), style: const TextStyle(color: Color(0xFF6B7280))),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWalletHistoryList({String? type}) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _walletService.historyStream(_uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _empty('Failed to load history. Please try again.');
        }

        final allDocs = snapshot.data?.docs ?? const [];
        final docs = allDocs.where((doc) {
          final docType = (doc.data()['type'] as String?) ?? '';
          if (type != null) {
            return docType == type;
          }
          return true;
        }).toList();

        if (docs.isEmpty) {
          return _empty('No records yet.');
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final entryType = (data['type'] as String?) ?? 'transaction';
            final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
            final balanceAfter = (data['balanceAfter'] as num?)?.toDouble();
            final workerName = (data['workerName'] as String?) ?? '';
            final note = (data['note'] as String?) ?? '';
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

            final isTopUp = entryType == 'topup';
            final title = isTopUp
                ? 'Wallet Top-up'
                : workerName.isNotEmpty
                ? 'Worker Pay - $workerName'
                : 'Wallet Transaction';

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE7ECF4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '${isTopUp ? '+' : '-'}${_money(amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isTopUp
                              ? const Color(0xFF0E9F6E)
                              : const Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(note.isNotEmpty ? note : 'Type: $entryType'),
                  if (balanceAfter != null) ...[
                    const SizedBox(height: 2),
                    Text('Balance after: ${_money(balanceAfter)}'),
                  ],
                  const SizedBox(height: 2),
                  Text(_date(createdAt), style: const TextStyle(color: Color(0xFF6B7280))),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        appBar: AppBar(
          title: const Text('History'),
          centerTitle: true,
          backgroundColor: const Color(0xFFF7F8FC),
          elevation: 0,
        ),
        body: _empty('Please sign in to view history.'),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('History'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F8FC),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Bookings'),
            Tab(text: 'Top-ups'),
            Tab(text: 'Worker Pay'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingList(),
          _buildWalletHistoryList(type: 'topup'),
          _buildWalletHistoryList(type: 'worker_pay'),
        ],
      ),
    );
  }
}
