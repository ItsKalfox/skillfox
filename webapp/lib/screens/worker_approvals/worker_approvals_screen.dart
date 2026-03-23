import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';

class WorkerApprovalsScreen extends StatelessWidget {
  const WorkerApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Worker Approvals',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
                SizedBox(height: 4),
                Text('Review and approve pending worker applications',
                    style: TextStyle(
                        fontSize: 14, color: AppTheme.textSecondary)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Workers Table
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.border)),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 3, child: Text('WORKER NAME',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppTheme.textHint, letterSpacing: 0.5))),
                    Expanded(flex: 2, child: Text('CATEGORY',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppTheme.textHint, letterSpacing: 0.5))),
                    Expanded(flex: 2, child: Text('CONTACT',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppTheme.textHint, letterSpacing: 0.5))),
                    Expanded(flex: 2, child: Text('STATUS',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppTheme.textHint, letterSpacing: 0.5))),
                    Expanded(flex: 2, child: Text('ACTIONS',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppTheme.textHint, letterSpacing: 0.5))),
                  ],
                ),
              ),

              // Table Rows from Firestore
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'worker')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text('No workers found')),
                    );
                  }

                  final workers = snapshot.data!.docs;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: workers.length,
                    itemBuilder: (context, index) {
                      final data = workers[index].data() as Map<String, dynamic>;
                      final docId = workers[index].id;
                      final status = data['status']?.toString() ?? 'pending';

                      return _WorkerRow(
                        docId: docId,
                        name: data['name'] ?? 'Unknown',
                        category: data['jobType'] ?? 'N/A',
                        phone: data['phone'] ?? 'N/A',
                        email: data['email'] ?? 'N/A',
                        status: status,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkerRow extends StatelessWidget {
  final String docId;
  final String name;
  final String category;
  final String phone;
  final String email;
  final String status;

  const _WorkerRow({
    required this.docId,
    required this.name,
    required this.category,
    required this.phone,
    required this.email,
    required this.status,
  });

  void _updateStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .update({'status': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Worker ${newStatus == 'active' ? 'approved' : 'rejected'} successfully'),
          backgroundColor: newStatus == 'active' ? AppTheme.success : AppTheme.danger,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update status'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          // Worker Name
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'W',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    Text(email,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),

          // Category
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(category,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500)),
            ),
          ),

          // Contact
          Expanded(
            flex: 2,
            child: Text(phone,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ),

          // Status
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: status == 'active'
                    ? const Color(0xFFECFDF5)
                    : status == 'rejected'
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status == 'active'
                    ? 'Approved'
                    : status == 'rejected'
                        ? 'Rejected'
                        : 'Pending',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: status == 'active'
                        ? AppTheme.success
                        : status == 'rejected'
                            ? AppTheme.danger
                            : AppTheme.warning),
              ),
            ),
          ),

          // Actions
          Expanded(
            flex: 2,
            child: status == 'active' || status == 'rejected'
                ? Text(
                    status == 'active' ? 'Approved ✓' : 'Rejected ✗',
                    style: TextStyle(
                        fontSize: 13,
                        color: status == 'active'
                            ? AppTheme.success
                            : AppTheme.danger),
                  )
                : Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => _updateStatus(context, 'active'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text('Approve',
                            style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _updateStatus(context, 'rejected'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.danger,
                          side: const BorderSide(color: AppTheme.danger),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text('Reject',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}