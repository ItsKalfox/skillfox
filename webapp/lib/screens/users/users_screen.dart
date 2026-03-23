import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _selectedRole = 'All Roles';
  String _selectedStatus = 'All Status';

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
                Text('User Management',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
                SizedBox(height: 4),
                Text('Manage customers and workers on the platform',
                    style: TextStyle(
                        fontSize: 14, color: AppTheme.textSecondary)),
              ],
            ),
            Row(
              children: [
                _DropdownFilter(
                  value: _selectedRole,
                  items: const ['All Roles', 'worker', 'customer'],
                  onChanged: (v) => setState(() => _selectedRole = v!),
                ),
                const SizedBox(width: 12),
                _DropdownFilter(
                  value: _selectedStatus,
                  items: const ['All Status', 'active', 'pending', 'suspended'],
                  onChanged: (v) => setState(() => _selectedStatus = v!),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Stats Row
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            final total = docs.length;
            final customers = docs.where((d) =>
                (d.data() as Map)['role'] == 'customer').length;
            final workers = docs.where((d) =>
                (d.data() as Map)['role'] == 'worker').length;
            final active = docs.where((d) =>
                (d.data() as Map)['status'] == 'active').length;

            return Row(
              children: [
                Expanded(child: _StatBox(label: 'Total Users', value: '$total', color: AppTheme.textPrimary)),
                const SizedBox(width: 16),
                Expanded(child: _StatBox(label: 'Customers', value: '$customers', color: AppTheme.primary)),
                const SizedBox(width: 16),
                Expanded(child: _StatBox(label: 'Workers', value: '$workers', color: const Color(0xFF10B981))),
                const SizedBox(width: 16),
                Expanded(child: _StatBox(label: 'Active Users', value: '$active', color: AppTheme.success)),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Users Table
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
                    Expanded(flex: 3, child: Text('USER',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppTheme.textHint, letterSpacing: 0.5))),
                    Expanded(flex: 3, child: Text('CONTACT',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppTheme.textHint, letterSpacing: 0.5))),
                    Expanded(flex: 2, child: Text('ROLE',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppTheme.textHint, letterSpacing: 0.5))),
                    Expanded(flex: 2, child: Text('JOIN DATE',
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

              // Table Rows
              StreamBuilder<QuerySnapshot>(
                stream: _buildQuery(),
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
                      child: Center(child: Text('No users found')),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _UserRow(
                        docId: doc.id,
                        name: data['name'] ?? 'Unknown',
                        email: data['email'] ?? 'N/A',
                        phone: data['phone'] ?? 'N/A',
                        role: data['role'] ?? 'N/A',
                        status: data['status'] ?? 'active',
                        createdAt: data['createdAt'],
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

  Stream<QuerySnapshot> _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('users');
    if (_selectedRole != 'All Roles') {
      query = query.where('role', isEqualTo: _selectedRole);
    }
    if (_selectedStatus != 'All Status') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }
    return query.snapshots();
  }
}

class _DropdownFilter extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownFilter({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary))))
              .toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final String docId;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;
  final dynamic createdAt;

  const _UserRow({
    required this.docId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final dt = (timestamp as Timestamp).toDate();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  void _updateStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .update({'status': newStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User status updated to $newStatus'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update user'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWorker = role == 'worker';
    final isActive = status == 'active';
    final isSuspended = status == 'suspended';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          // User
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isWorker
                      ? const Color(0xFF10B981)
                      : AppTheme.primary,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                  ],
                ),
              ],
            ),
          ),

          // Contact
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(email,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textPrimary)),
                Text(phone,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),

          // Role
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isWorker
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isWorker ? 'Worker' : 'Customer',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isWorker
                        ? const Color(0xFF10B981)
                        : AppTheme.primary),
              ),
            ),
          ),

          // Join Date
          Expanded(
            flex: 2,
            child: Text(_formatDate(createdAt),
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ),

          // Status
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFECFDF5)
                    : isSuspended
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isActive
                    ? 'Active'
                    : isSuspended
                        ? 'Suspended'
                        : 'Pending',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isActive
                        ? AppTheme.success
                        : isSuspended
                            ? AppTheme.danger
                            : AppTheme.warning),
              ),
            ),
          ),

          // Actions
          Expanded(
            flex: 2,
            child: Row(
              children: [
                // Suspend / Activate button
                GestureDetector(
                  onTap: () => _updateStatus(
                      context, isActive ? 'suspended' : 'active'),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFFFFBEB)
                          : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      isActive ? Icons.pause_outlined : Icons.play_arrow_outlined,
                      size: 16,
                      color: isActive ? AppTheme.warning : AppTheme.success,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Delete button
                GestureDetector(
                  onTap: () => _showDeleteDialog(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.block_outlined,
                        size: 16, color: AppTheme.danger),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspend User'),
        content: Text('Are you sure you want to suspend $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateStatus(context, 'suspended');
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }
}