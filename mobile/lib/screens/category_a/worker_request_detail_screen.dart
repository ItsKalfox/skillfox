import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'worker_job_progress_screen.dart';

class WorkerRequestDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const WorkerRequestDetailScreen({super.key, required this.data});

  String initials(String name) {
    final p = name.split(' ');
    return p.length > 1 ? '${p[0][0]}${p[1][0]}' : p[0][0];
  }

  String _studentRefFromId(String customerId) {
    if (customerId.isEmpty) return 'STUDENT-NA';
    final suffix = customerId.length > 6
        ? customerId.substring(customerId.length - 6)
        : customerId;
    return 'STUDENT-${suffix.toUpperCase()}';
  }

  String _cycleLabel(Map<String, dynamic> d) {
    final model = (d['subscriptionModel'] ?? '').toString().toLowerCase();
    final idx = (d['subscriptionCycleIndex'] as num?)?.toInt() ?? 1;
    if (model == 'monthly') return 'Month $idx';
    return 'Week $idx';
  }

  String _cycleDateRange(Map<String, dynamic> d) {
    final ts = d['subscriptionCycleStartAt'] as Timestamp?;
    if (ts == null) return '';
    final start = ts.toDate();
    final model = (d['subscriptionModel'] ?? '').toString().toLowerCase();
    final end = model == 'monthly'
        ? DateTime(
            start.year,
            start.month + 1,
            start.day,
          ).subtract(const Duration(days: 1))
        : start.add(const Duration(days: 6));
    final f = DateFormat('dd MMM yyyy');
    return '${f.format(start)} - ${f.format(end)}';
  }

  Future<String?> _askSubscriptionPrice(
    BuildContext context,
    String currentValue,
  ) async {
    final controller = TextEditingController(text: currentValue);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Subscription Price'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Enter weekly/monthly amount',
            prefixText: 'LKR ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = controller.text.trim();
              if (price.isEmpty) return;
              Navigator.pop(ctx, price);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final name = data['customerName'] ?? 'Customer';
    final phone = data['phone'] ?? '+94 --------';
    final address = data['address'] ?? '';
    final desc = data['description'] ?? '';
    final requestId = data['id'] ?? '';
    final status = (data['status'] ?? 'pending').toString();
    final timestamp = data['createdAt'];
    final category = (data['category'] ?? '').toString().toLowerCase();
    final requestType = (data['requestType'] ?? '').toString().toLowerCase();
    final isSubscriptionRequest =
        requestType == 'subscription' ||
        category == 'teacher' ||
        category == 'caregiver';
    final studentName =
        (data['studentName'] ?? data['customerName'] ?? 'Student').toString();
    final studentId = (data['studentId'] ?? data['customerId'] ?? '')
        .toString();
    final studentRef = (data['studentRef'] ?? '').toString().isNotEmpty
        ? (data['studentRef'] ?? '').toString()
        : _studentRefFromId(studentId);
    final subscriptionPlan =
        (data['subscriptionPlan'] ?? data['serviceType'] ?? '').toString();
    final subscriptionModel = (data['subscriptionModel'] ?? '').toString();
    final daysRaw = data['subscriptionDays'];
    final subscriptionDays = daysRaw is List
        ? daysRaw
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .join(', ')
        : '';

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
    final cycleLabel = _cycleLabel(data);
    final cycleRange = _cycleDateRange(data);

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

                          if (isSubscriptionRequest)
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
                                    'Subscription Details',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Student: $studentName ($studentRef)'),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Model: ${subscriptionModel.isEmpty ? 'Not specified' : subscriptionModel.toUpperCase()}',
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Requested days: ${subscriptionDays.isEmpty ? 'Not specified' : subscriptionDays}',
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Current cycle: $cycleLabel'),
                                  if (cycleRange.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text('Cycle date: $cycleRange'),
                                  ],
                                  if (subscriptionPlan.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text('Plan: $subscriptionPlan'),
                                  ],
                                ],
                              ),
                            ),

                          if (isSubscriptionRequest) const SizedBox(height: 12),

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

                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
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

                          if (status == 'pending')
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final nav = Navigator.of(context);
                                  String subscriptionPrice =
                                      (data['subscriptionPrice'] ?? '')
                                          .toString()
                                          .trim();
                                  if (isSubscriptionRequest) {
                                    final entered = await _askSubscriptionPrice(
                                      context,
                                      subscriptionPrice,
                                    );
                                    if (entered == null || entered.isEmpty) {
                                      return;
                                    }
                                    subscriptionPrice = entered;
                                  }
                                  await FirebaseFirestore.instance
                                      .collection('requests')
                                      .doc(requestId)
                                      .update({
                                        'status': 'accepted',
                                        'acceptedAt':
                                            FieldValue.serverTimestamp(),
                                        if (isSubscriptionRequest)
                                          'subscriptionPrice':
                                              subscriptionPrice,
                                        if (isSubscriptionRequest)
                                          'subscriptionCyclePaymentStatus':
                                              'pending',
                                        if (isSubscriptionRequest)
                                          'acceptedStudentRef': studentRef,
                                        if (isSubscriptionRequest)
                                          'acceptedStudentName': studentName,
                                        if (isSubscriptionRequest &&
                                            subscriptionModel.isNotEmpty)
                                          'acceptedSubscriptionModel':
                                              subscriptionModel,
                                        if (isSubscriptionRequest &&
                                            subscriptionDays.isNotEmpty)
                                          'acceptedSubscriptionDays':
                                              subscriptionDays,
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

                          if (isSubscriptionRequest && status == 'completed')
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final nav = Navigator.of(context);
                                  final currentCycle =
                                      (data['subscriptionCycleIndex'] as num?)
                                          ?.toInt() ??
                                      1;
                                  await FirebaseFirestore.instance
                                      .collection('requests')
                                      .doc(requestId)
                                      .update({
                                        'status': 'accepted',
                                        'subscriptionCycleIndex':
                                            currentCycle + 1,
                                        'subscriptionCycleStartAt':
                                            FieldValue.serverTimestamp(),
                                        'subscriptionCyclePaymentStatus':
                                            'pending',
                                        'inprogressAt': null,
                                        'arrivedAt': null,
                                        'completedAt': null,
                                      });
                                  nav.pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                ),
                                child: const Text(
                                  'Start Next Cycle',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),

                          if (isSubscriptionRequest && status == 'completed')
                            const SizedBox(width: 10),

                          if (isSubscriptionRequest &&
                              status != 'cancelled' &&
                              status != 'rejected')
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final nav = Navigator.of(context);
                                  await FirebaseFirestore.instance
                                      .collection('requests')
                                      .doc(requestId)
                                      .update({
                                        'status': 'cancelled',
                                        'subscriptionEndedBy': 'worker',
                                        'subscriptionEndedAt':
                                            FieldValue.serverTimestamp(),
                                      });
                                  nav.pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                ),
                                child: const Text(
                                  'End',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),

                          if (isActiveJob)
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
                                  backgroundColor: const Color(0xFF4A98EF),
                                ),
                                child: const Text(
                                  'View Progress',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
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
