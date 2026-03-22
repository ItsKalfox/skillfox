import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'worker_job_progress_screen.dart';
import 'quotation_screen.dart';
//import '../category_a/worker_job_progress_screen.dart';

class WorkerRequestDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const WorkerRequestDetailScreen({super.key, required this.data});

  String initials(String name) {
    final p = name.split(' ');
    return p.length > 1 ? '${p[0][0]}${p[1][0]}' : p[0][0];
  }

  @override
  Widget build(BuildContext context) {
    final name      = data['customerName'] ?? 'Customer';
    final phone     = data['phone']        ?? '+94 --------';
    final address   = data['address']      ?? '';
    final desc      = data['description']  ?? '';
    final requestId = data['id']           ?? '';
    final status    = data['status']       ?? 'pending';
    final timestamp = data['createdAt'];

    // FIX: guard against null/zero lat-lng — use 0.0 fallback instead of crashing
    final double lat = (data['latitude']  as num?)?.toDouble() ?? 0.0;
    final double lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;
    final bool hasLocation = lat != 0.0 && lng != 0.0;

    final images = List<String>.from(data['imageUrls'] ?? data['images'] ?? []);

    String formattedDate = '';
    String formattedTime = '';
    if (timestamp != null && timestamp is Timestamp) {
      final dt   = timestamp.toDate();
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

    return Scaffold(
      body: Stack(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [
              Color(0xFF469FEF),
              Color(0xFF5C75F0),
              Color(0xFF6C56F0),
            ]),
          ),
        ),

        SafeArea(
          child: Column(children: [
            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text('Request Details',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ]),
            ),

            // ── Content ──────────────────────────────────────────────────
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F6FA),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  child: Column(children: [
                    // Customer card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)),
                      child: Row(children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF469FEF),
                          child: Text(initials(name),
                              style: const TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 10),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          Text(phone,
                              style: const TextStyle(fontSize: 12)),
                          Text('Request ID: $requestId',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        ]),
                      ]),
                    ),

                    const SizedBox(height: 12),

                    Row(children: [
                      Expanded(child: _infoBox('Date', formattedDate)),
                      const SizedBox(width: 10),
                      Expanded(child: _infoBox('Time', formattedTime)),
                    ]),

                    const SizedBox(height: 12),

                    // Map — only show if we have real coordinates
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
                                markerId:
                                    const MarkerId('customerLocation'),
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
                          border: Border.all(color: const Color(0xFFE2E6F0)),
                        ),
                        child: const Center(
                          child: Text('Location not available',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    _sectionCard('Address', address),
                    const SizedBox(height: 12),
                    _sectionCard('Description', desc),

                    const SizedBox(height: 12),

                    // Images
                    if (images.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          const Text('Inspection Photos',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: images.map((img) {
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        FullScreenImage(imageUrl: img),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(img,
                                      height: 90,
                                      width: 90,
                                      fit: BoxFit.cover),
                                ),
                              );
                            }).toList(),
                          ),
                        ]),
                      ),

                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ),

            // ── Action buttons ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  // FIX: Reject writes status='rejected' (not 'cancelled')
                  // so customer sees the red rejection banner correctly
                  if (status == 'pending')
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final nav = Navigator.of(context);
                          await FirebaseFirestore.instance
                              .collection('requests')
                              .doc(requestId)
                              .update({
                            'status':     'rejected',  // FIX was 'cancelled'
                            'rejectedBy': 'worker',
                            'rejectedAt': FieldValue.serverTimestamp(),
                          });
                          nav.pop();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Reject',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),

                  if (status == 'accepted' && canCancel)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final nav = Navigator.of(context);
                          await FirebaseFirestore.instance
                              .collection('requests')
                              .doc(requestId)
                              .update({
                            'status':      'cancelled',
                            'cancelledBy': 'worker',
                            'cancelledAt': FieldValue.serverTimestamp(),
                          });
                          nav.pop();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),

                  if (status == 'pending') const SizedBox(width: 10),

                  // Accept button
                  if (status == 'pending')
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final nav = Navigator.of(context);
                          await FirebaseFirestore.instance
                              .collection('requests')
                              .doc(requestId)
                              .update({
                            'status':     'accepted',
                            'acceptedAt': FieldValue.serverTimestamp(),
                          });
                          nav.pop();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C56F0)),
                        child: const Text('Accept Request',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),

                  // FIX: View Progress goes to WorkerJobProgressScreen
                  // NOT WaitingWorkerScreen (which is the customer screen)
                  if (status != 'pending' && status != 'cancelled' && status != 'rejected')
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WorkerJobProgressScreen(
                                requestId: requestId,
                                requestData: data,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A98EF)),
                        child: const Text('View Progress',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                ]),

                // Send Quotation button — shown for accepted/inprogress
                if (status == 'accepted' || status == 'inprogress') ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuotationScreen(
                              requestId:   requestId,
                              requestData: data,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.description_outlined,
                          color: Colors.white, size: 18),
                      label: const Text('Send Quotation',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _sectionCard(String title, String value) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(value),
        ]),
      );

  Widget _infoBox(String title, String value) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 10)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
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
        body: Center(
          child: InteractiveViewer(
            child: Image.network(imageUrl),
          ),
        ),
      );
}
