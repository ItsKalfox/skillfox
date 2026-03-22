import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/subscription_service.dart';
import 'create_subscription_page.dart';
import 'subscription_detail_shell_page.dart';

class SubscriptionHomePage extends StatelessWidget {
  const SubscriptionHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = SubscriptionService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const CreateSubscriptionPage(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Subscription'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.subscriptionsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final activeCount = docs
              .where((doc) => (doc.data()['status'] ?? '') == 'active')
              .length;

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recurring Services Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Track plans, sessions, and invoices in one place.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _statChip('Total', docs.length.toString()),
                        _statChip('Active', activeCount.toString()),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: docs.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No subscriptions yet. Tap "New Subscription" to create one.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: docs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final sub = docs[index].data();
                          final status = (sub['status'] ?? 'unknown').toString();
                          final serviceType =
                              (sub['serviceType'] ?? 'Service').toString();
                          final frequency = (sub['frequency'] ?? '-').toString();
                          final sessions = (sub['sessions'] ?? 0).toString();

                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFE0F2F1),
                                child: Icon(
                                  Icons.work_outline,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                              title: Text(
                                serviceType,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '$frequency • $sessions sessions\nStatus: $status',
                              ),
                              isThreeLine: true,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => SubscriptionDetailShellPage(
                                      subscriptionId: docs[index].id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
