import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'worker_request_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkerRequestsScreen extends StatefulWidget {
  const WorkerRequestsScreen({super.key});

  @override
  State<WorkerRequestsScreen> createState() => _WorkerRequestsScreenState();
}

class _WorkerRequestsScreenState extends State<WorkerRequestsScreen> {
  String _selectedFilter = "All";

  final List<String> _filters = [
    "All",
    "pending",
    "accepted",
    "inprogress",
    "arrived",
    "completed",
    "quotation_sent",
    "cancelled",
  ];

  String initials(String name) {
    if (name.trim().isEmpty) return '?';
    final p = name.trim().split(" ");
    if (p.length > 1 && p[1].isNotEmpty)
      return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return p[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF469FEF),
                  Color(0xFF5C75F0),
                  Color(0xFF6C56F0),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Container(
              margin: const EdgeInsets.only(top: 80),
              decoration: const BoxDecoration(
                color: Color(0xFFF4F6FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Inspection Requests",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),

                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('requests')
                                  .where('workerId', isEqualTo: user!.uid)
                                  .where('status', isEqualTo: 'pending')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                int count = snapshot.data?.docs.length ?? 0;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF469FEF),
                                        Color(0xFF6C56F0),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "$count New",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _filters.map((f) {
                              bool active = _selectedFilter == f;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedFilter = f),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: active
                                          ? const LinearGradient(
                                              colors: [
                                                Color(0xFF469FEF),
                                                Color(0xFF6C56F0),
                                              ],
                                            )
                                          : null,
                                      color: active ? null : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      _filterLabel(f),
                                      style: TextStyle(
                                        color: active
                                            ? Colors.white
                                            : Colors.black54,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('requests')
                          .where('workerId', isEqualTo: user!.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError)
                          return const Center(
                            child: Text("Error loading requests"),
                          );
                        if (!snapshot.hasData)
                          return const Center(
                            child: CircularProgressIndicator(),
                          );

                        final docs = snapshot.data!.docs;

                        final filteredDocs = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          if (_selectedFilter == "All") return true;
                          return (data['status'] ?? '').toString() ==
                              _selectedFilter;
                        }).toList();

                        filteredDocs.sort((a, b) {
                          final ta =
                              ((a.data() as Map)['createdAt'] as Timestamp?)
                                  ?.millisecondsSinceEpoch ??
                              0;
                          final tb =
                              ((b.data() as Map)['createdAt'] as Timestamp?)
                                  ?.millisecondsSinceEpoch ??
                              0;
                          return tb.compareTo(ta);
                        });

                        if (filteredDocs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inbox_rounded,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "No requests found",
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredDocs.length,
                          itemBuilder: (context, index) {
                            final doc = filteredDocs[index];
                            final data = Map<String, dynamic>.from(
                              doc.data() as Map<String, dynamic>,
                            );
                            data['id'] = doc.id;

                            final name = (data['customerName'] ?? 'Customer')
                                .toString();
                            final address = (data['address'] ?? '').toString();
                            final desc = (data['description'] ?? '').toString();
                            final status = (data['status'] ?? 'pending')
                                .toString();
                            final shortId =
                                '#' +
                                (doc.id.length >= 8
                                    ? doc.id.substring(0, 8).toUpperCase()
                                    : doc.id.toUpperCase());

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: const Color(
                                          0xFF469FEF,
                                        ),
                                        child: Text(
                                          initials(name),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              shortId,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF6C56F0),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      buildStatusChip(status),
                                    ],
                                  ),

                                  const SizedBox(height: 10),
                                  const Divider(),

                                  if (address.isNotEmpty) ...[
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 14,
                                          color: Color(0xFF6C56F0),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            address,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                  ],

                                  if (desc.isNotEmpty)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            desc,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),

                                  const SizedBox(height: 12),

                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              WorkerRequestDetailScreen(
                                                data: data,
                                              ),
                                        ),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF469FEF),
                                              Color(0xFF6C56F0),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Text(
                                          "View",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, Worker 👋",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      "Manage your requests",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _filterLabel(String filter) {
    switch (filter) {
      case 'All':
        return 'ALL';
      case 'pending':
        return 'PENDING';
      case 'accepted':
        return 'ACCEPTED';
      case 'inprogress':
        return 'PAID';
      case 'arrived':
        return 'ARRIVED';
      case 'completed':
        return 'COMPLETED';
      case 'quotation_sent':
        return 'QUOTATION';
      case 'cancelled':
        return 'CANCELLED';
      case 'rejected':
        return 'REJECTED';
      default:
        return filter.toUpperCase();
    }
  }

  Widget buildStatusChip(String status) {
    Color bg;
    Color text;
    switch (status) {
      case 'pending':
        bg = Colors.orange.shade100;
        text = Colors.orange.shade800;
        break;
      case 'accepted':
        bg = Colors.blue.shade100;
        text = Colors.blue.shade800;
        break;
      case 'inprogress':
        bg = Colors.purple.shade100;
        text = Colors.purple.shade800;
        break;
      case 'arrived':
        bg = Colors.teal.shade100;
        text = Colors.teal.shade800;
        break;
      case 'completed':
        bg = Colors.green.shade100;
        text = Colors.green.shade800;
        break;
      case 'quotation_sent':
        bg = Colors.blue.shade100;
        text = Colors.blue.shade800;
        break;
      case 'cancelled':
        bg = Colors.red.shade100;
        text = Colors.red.shade800;
        break;
      case 'rejected':
        bg = Colors.red.shade100;
        text = Colors.red.shade800;
        break;
      default:
        bg = Colors.grey.shade200;
        text = Colors.black54;
    }
    final label = _filterLabel(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label.isEmpty ? status.toUpperCase() : label,
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
