import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'worker_job_progress_screen.dart';
import '../category_b/worker_quotation_screen.dart';
import '../category_b/worker_job_screen.dart';
import '../category_c/worker_subscription_screen.dart';
import '../category_c/worker_subscription_mgmt_screen.dart';

class WorkerRequestDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const WorkerRequestDetailScreen({super.key, required this.data});

  String initials(String name) {
    final p = name.split(' ');
    return p.length > 1 ? '${p[0][0]}${p[1][0]}' : p[0][0];
  }

  /// Derive category type from the categoryType field, falling back
  /// to the job name when the field is absent (same logic as worker_profile_screen).
  String _categoryType() {
    final stored = (data['categoryType'] as String?)?.trim().toUpperCase();
    if (stored == 'A' || stored == 'B' || stored == 'C') return stored!;

    const catA = {'plumber', 'electrician', 'mechanic', 'mason'};
    const catC = {
      'teacher',
      'tutor',
      'caregiver',
      'care giver',
      'baby sitter',
      'babysitter',
      'nurse',
      'nanny',
    };
    final lower = (data['category'] as String? ?? '').toLowerCase().trim();
    if (catA.contains(lower)) return 'A';
    if (catC.contains(lower)) return 'C';
    return 'B';
  }

  @override
  Widget build(BuildContext context) {
    final name = data['customerName'] ?? 'Customer';
    final phone = data['phone'] ?? '+94 --------';
    final address = data['address'] ?? '';
    final desc = data['description'] ?? '';
    final requestId = data['id'] ?? '';
    final status = data['status'] ?? 'pending';
    final timestamp = data['createdAt'];
    final catType = _categoryType();

    final double lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
    final double lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;
    final bool hasLocation = lat != 0.0 && lng != 0.0;

    final images = List<String>.from(data['imageUrls'] ?? data['images'] ?? []);

    String formattedDate = '';
    String formattedTime = '';
    if (timestamp != null && timestamp is Timestamp) {
      final dt = timestamp.toDate();
      formattedDate = DateFormat('dd MMM yyyy').format(dt);
      formattedTime = DateFormat('hh:mm a').format(dt);
    }

    bool canCancel = false;
    if (data['acceptedAt'] != null) {
      final acceptedTime = (data['acceptedAt'] as Timestamp).toDate();
      if (DateTime.now().difference(acceptedTime).inMinutes <= 10) {
        canCancel = true;
      }
    }

    final isActiveJob =
        status != 'pending' && status != 'cancelled' && status != 'rejected';

    // ── Category-specific extra info shown below description ──────────────
    final preferredSchedule = data['preferredSchedule'] as String?;
    final preferredCycle = data['preferredBillingCycle'] as String?;
    final customerNotes = data['customerNotes'] as String?;

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
            child: Column(
              children: [
                // ── App bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Request Details',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Category badge
                      _categoryBadge(catType),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4F6FA),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // ── Customer info card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF469FEF),
                                  child: Text(
                                    initials(name),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      phone,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'Request ID: $requestId',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(child: _infoBox('Date', formattedDate)),
                              const SizedBox(width: 10),
                              Expanded(child: _infoBox('Time', formattedTime)),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ── Map
                          if (hasLocation) ...[
                            SizedBox(
                              height: 200,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(lat, lng),
                                    zoom: 15,
                                  ),
                                  markers: {
                                    Marker(
                                      markerId: const MarkerId(
                                        'customerLocation',
                                      ),
                                      position: LatLng(lat, lng),
                                    ),
                                  },
                                  zoomControlsEnabled: false,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ] else ...[
                            Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E6F0),
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'Location not available',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          _sectionCard('Address', address),
                          const SizedBox(height: 12),
                          _sectionCard('Description', desc),
                          const SizedBox(height: 12),

                          // ── Category B/C extra fields
                          if (preferredSchedule != null &&
                              preferredSchedule.isNotEmpty) ...[
                            _sectionCard(
                              'Preferred Schedule',
                              preferredSchedule,
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (preferredCycle != null &&
                              preferredCycle.isNotEmpty) ...[
                            _sectionCard(
                              'Preferred Billing',
                              preferredCycle.toUpperCase(),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (customerNotes != null &&
                              customerNotes.isNotEmpty) ...[
                            _sectionCard('Customer Notes', customerNotes),
                            const SizedBox(height: 12),
                          ],

                          // ── Inspection photos (Cat A)
                          if (images.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Inspection Photos',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: images
                                        .map(
                                          (img) => GestureDetector(
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => FullScreenImage(
                                                  imageUrl: img,
                                                ),
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.network(
                                                img,
                                                height: 90,
                                                width: 90,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Bottom action bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          // Reject (pending only)
                          if (status == 'pending')
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final nav = Navigator.of(context);
                                  await FirebaseFirestore.instance
                                      .collection('requests')
                                      .doc(requestId)
                                      .update({
                                        'status': 'rejected',
                                        'rejectedBy': 'worker',
                                        'rejectedAt':
                                            FieldValue.serverTimestamp(),
                                      });
                                  nav.pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text(
                                  'Reject',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),

                          // Cancel within 10 min of acceptance
                          if (status == 'accepted' && canCancel)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final nav = Navigator.of(context);
                                  await FirebaseFirestore.instance
                                      .collection('requests')
                                      .doc(requestId)
                                      .update({
                                        'status': 'cancelled',
                                        'cancelledBy': 'worker',
                                        'cancelledAt':
                                            FieldValue.serverTimestamp(),
                                      });
                                  nav.pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),

                          if (status == 'pending') const SizedBox(width: 10),

                          // Accept (pending only)
                          if (status == 'pending')
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final nav = Navigator.of(context);
                                  await FirebaseFirestore.instance
                                      .collection('requests')
                                      .doc(requestId)
                                      .update({
                                        'status': 'accepted',
                                        'acceptedAt':
                                            FieldValue.serverTimestamp(),
                                      });
                                  nav.pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C56F0),
                                ),
                                child: const Text(
                                  'Accept Request',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),

                          // ── Active job buttons — routed by category type ──────────
                          if (isActiveJob) ...[
                            if (catType == 'B') ...[
                              // Cat B: if no quotation sent yet → "Send Price"
                              // else → "View Progress"
                              if (data['quotationSent'] != true)
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CategoryBWorkerQuotationScreen(
                                              requestId: requestId,
                                              requestData: data,
                                            ),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                    ),
                                    child: const Text(
                                      'Send Price',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                )
                              else
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CategoryBWorkerJobScreen(
                                              requestId: requestId,
                                              requestData: data,
                                            ),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                    ),
                                    child: const Text(
                                      'View Progress',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                            ] else if (catType == 'C') ...[
                              // Cat C: if no subscription proposal sent → "Send Proposal"
                              // else → "Manage Subscription"
                              if (data['quotationSent'] != true)
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CategoryCWorkerSubscriptionScreen(
                                              requestId: requestId,
                                              requestData: data,
                                            ),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF8B5CF6),
                                    ),
                                    child: const Text(
                                      'Send Proposal',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                )
                              else
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CategoryCWorkerSubscriptionMgmtScreen(
                                              requestId: requestId,
                                              requestData: data,
                                            ),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF8B5CF6),
                                    ),
                                    child: const Text(
                                      'Manage Sub',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                            ] else ...[
                              // Cat A — original behaviour
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => WorkerJobProgressScreen(
                                        requestId: requestId,
                                        requestData: data,
                                      ),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4A98EF),
                                  ),
                                  child: const Text(
                                    'View Progress',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Small category badge shown in the app bar ──────────────────────────────
  Widget _categoryBadge(String type) {
    final Map<String, List<dynamic>> styles = {
      'A': [const Color(0xFFEFF6FF), const Color(0xFF2563EB), 'Inspection'],
      'B': [const Color(0xFFECFDF5), const Color(0xFF059669), 'One-time'],
      'C': [const Color(0xFFF3EEFF), const Color(0xFF7C3AED), 'Subscription'],
    };
    final s = styles[type] ?? styles['A']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (s[0] as Color).withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        s[2] as String,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white.withOpacity(0.9),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _sectionCard(String title, String value) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        Text(value),
      ],
    ),
  );

  Widget _infoBox(String title, String value) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    body: Center(child: InteractiveViewer(child: Image.network(imageUrl))),
  );
}
