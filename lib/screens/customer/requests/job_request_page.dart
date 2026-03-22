import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/job_request_repository.dart';
import 'request_status_page.dart';

class JobRequestPage extends StatefulWidget {
  const JobRequestPage({
    super.key,
    required this.repository,
    this.workerId,
    this.workerName,
    this.workerCategory,
    this.workerPhotoUrl,
    this.workerAddress,
    this.workerRating,
    this.distanceKm,
    this.estimatedArrival,
    this.services,
  });

  final JobRequestRepository repository;
  final String? workerId;
  final String? workerName;
  final String? workerCategory;
  final String? workerPhotoUrl;
  final String? workerAddress;
  final double? workerRating;
  final double? distanceKm;
  final String? estimatedArrival;
  final List<Map<String, String>>? services;

  @override
  State<JobRequestPage> createState() => _JobRequestPageState();
}

class _JobRequestPageState extends State<JobRequestPage> {
  final _notesController = TextEditingController();

  bool _isSubmitting = false;
  List<XFile> _images = const [];
  int _selectedServiceIndex = 0;

  List<Map<String, String>> get _services {
    final incoming = widget.services ?? const <Map<String, String>>[];
    if (incoming.isNotEmpty) {
      return incoming;
    }

    return const [
      {'name': 'General Service', 'price': 'LKR 4,500'},
    ];
  }

  String _serviceNameAt(int i) => _services[i]['name'] ?? 'Service';
  String _servicePriceAt(int i) => _services[i]['price'] ?? 'LKR 0';

  String _workerName() {
    final name = widget.workerName?.trim();
    return (name == null || name.isEmpty) ? 'Worker' : name;
  }

  String _workerCategory() {
    final role = widget.workerCategory?.trim();
    return (role == null || role.isEmpty) ? 'Provider' : role;
  }

  String _estimatedArrival() {
    final eta = widget.estimatedArrival?.trim();
    return (eta == null || eta.isEmpty) ? '18 - 22 minutes' : eta;
  }

  String _distanceLabel() {
    final d = widget.distanceKm;
    if (d == null) return '6.2 km';
    return '${d.toStringAsFixed(1)} km';
  }

  double _toAmount(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  String _formatLkr(double amount) {
    return 'LKR ${amount.toStringAsFixed(0)}';
  }

  String _requestStatusLabel(String status) {
    switch (status) {
      case 'arriving':
        return 'Worker on the way';
      case 'inspection':
        return 'Inspection';
      case 'working':
        return 'Work in progress';
      case 'finished':
        return 'Finished';
      case 'unavailable':
        return 'Unavailable';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Request sent';
    }
  }

  Widget _buildExistingRequestsSection() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final workerId = widget.workerId;

    if (currentUserId == null || workerId == null || workerId.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('service_requests')
          .where('customerId', isEqualTo: currentUserId)
          .where('workerId', isEqualTo: workerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final items = docs.toList()
          ..sort((a, b) {
            final at = (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                0;
            final bt = (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                0;
            return bt.compareTo(at);
          });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 22),
            const Text(
              'Your Requests With This Worker',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B1B1D),
              ),
            ),
            const SizedBox(height: 10),
            ...items.take(5).map((doc) {
              final data = doc.data();
              final status = (data['status'] as String?) ?? 'pending';
              final serviceType =
                  (data['serviceType'] as String?) ?? (data['service'] as String?) ?? 'Service';
              final price = (data['price'] as num?)?.toDouble() ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RequestStatusPage(requestId: doc.id),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDADAE0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                serviceType,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2B2B31),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _requestStatusLabel(status),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6E6E76),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatLkr(price),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6E6E76),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF6E6E76),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final selected = await picker.pickMultiImage(imageQuality: 80);
    if (!mounted) return;

    setState(() {
      _images = selected;
    });
  }

  Future<void> _submitRequest() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('Please sign in to make a request.');
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() ?? const <String, dynamic>{};

      final customerName =
          (userData['name'] as String?)?.trim().isNotEmpty == true
              ? (userData['name'] as String).trim()
              : (user.displayName?.trim().isNotEmpty == true
                    ? user.displayName!.trim()
                    : 'Customer');

      final customerPhotoUrl =
          (userData['profilePhotoUrl'] as String?) ?? user.photoURL ?? '';

      double? customerLat = (userData['lat'] as num?)?.toDouble();
      double? customerLng = (userData['lng'] as num?)?.toDouble();

      if (customerLat == null || customerLng == null) {
        final permission = await Geolocator.checkPermission();
        var effectivePermission = permission;
        if (effectivePermission == LocationPermission.denied) {
          effectivePermission = await Geolocator.requestPermission();
        }

        if (effectivePermission != LocationPermission.denied &&
            effectivePermission != LocationPermission.deniedForever) {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          customerLat = position.latitude;
          customerLng = position.longitude;
        }
      }

      if (customerLat == null || customerLng == null) {
        throw StateError(
          'Location is required so nearby workers can receive your request.',
        );
      }

      final selectedName = _serviceNameAt(_selectedServiceIndex);
      final selectedPrice = _toAmount(_servicePriceAt(_selectedServiceIndex));

      final requestId = await widget.repository.createServiceRequest(
        customerId: user.uid,
        customerName: customerName,
        customerPhotoUrl: customerPhotoUrl,
        serviceType: selectedName,
        description: _notesController.text.trim().isEmpty
            ? 'Request created from confirm request page.'
            : _notesController.text.trim(),
        scheduledAt: DateTime.now().add(const Duration(minutes: 30)),
        location: (userData['address'] as String?)?.trim().isNotEmpty == true
            ? (userData['address'] as String).trim()
            : 'Customer location',
        price: selectedPrice,
        customerLat: customerLat,
        customerLng: customerLng,
        images: _images,
      );

      await FirebaseFirestore.instance
          .collection('service_requests')
          .doc(requestId)
          .update({
        'workerId': widget.workerId,
        'workerName': _workerName(),
        'workerPhone': '',
        'workerCategory': _workerCategory(),
        'workerPhotoUrl': widget.workerPhotoUrl ?? '',
      });

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RequestStatusPage(requestId: requestId),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servicePrice = _toAmount(_servicePriceAt(_selectedServiceIndex));
    final travelFee = 450.0;
    final total = servicePrice + travelFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1B1B1D)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Confirm Request',
          style: TextStyle(
            color: Color(0xFF1B1B1D),
            fontWeight: FontWeight.w500,
            fontSize: 30 / 2,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            _MapPreviewCard(distanceLabel: _distanceLabel()),
            const SizedBox(height: 14),
            _WorkerSummaryTile(
              photoUrl: widget.workerPhotoUrl ?? '',
              name: _workerName(),
              category: _workerCategory(),
              address: widget.workerAddress ?? 'Matara - Akuressa Hwy, Godagama',
              rating: widget.workerRating ?? 4.5,
            ),
            const SizedBox(height: 14),
            _CostRow(label: 'Distance', value: _distanceLabel()),
            const SizedBox(height: 2),
            _CostRow(label: 'Arrival Estimated Time', value: _estimatedArrival()),
            const SizedBox(height: 14),
            Container(height: 1, color: const Color(0xFFD6D6D8)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Services & Pricing',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1B1B1D),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(_services.length, (index) {
                    final isSelected = index == _selectedServiceIndex;
                    return InkWell(
                      onTap: () => setState(() => _selectedServiceIndex = index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              size: 18,
                              color: isSelected
                                  ? const Color(0xFF5962F2)
                                  : const Color(0xFF7A7A80),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _serviceNameAt(index),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF585860),
                                ),
                              ),
                            ),
                            Text(
                              _servicePriceAt(index),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7A7A80),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              minLines: 2,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Additional notes (optional)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(
                _images.isEmpty
                    ? 'Upload reference images'
                    : '${_images.length} image(s) selected',
              ),
            ),
            const SizedBox(height: 8),
            Container(height: 1, color: const Color(0xFFD6D6D8)),
            const SizedBox(height: 14),
            _CostRow(label: 'Service Fee', value: _formatLkr(servicePrice)),
            const SizedBox(height: 4),
            const _CostRow(label: 'Travelling Fee', value: 'LKR 450'),
            const SizedBox(height: 4),
            _CostRow(
              label: 'Total',
              value: _formatLkr(total),
              valueStyle: const TextStyle(
                fontSize: 22 / 2,
                color: Color(0xFF1B1B1D),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _PaymentTile(),
            const SizedBox(height: 26),
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.mainGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Request & Pay',
                          style: TextStyle(
                            fontSize: 18 / 2,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            _buildExistingRequestsSection(),
          ],
        ),
      ),
    );
  }
}

class _MapPreviewCard extends StatelessWidget {
  const _MapPreviewCard({required this.distanceLabel});

  final String distanceLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8EB),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Center(
            child: Icon(Icons.map_outlined, size: 72, color: Color(0xFFB5B5BB)),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Row(
              children: [
                const Icon(Icons.place, color: Color(0xFF4B7DF3), size: 18),
                const SizedBox(width: 5),
                Text(
                  distanceLabel,
                  style: const TextStyle(
                    color: Color(0xFF4B4B55),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerSummaryTile extends StatelessWidget {
  const _WorkerSummaryTile({
    required this.photoUrl,
    required this.name,
    required this.category,
    required this.address,
    required this.rating,
  });

  final String photoUrl;
  final String name;
  final String category;
  final String address;
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFD7D7DE),
          backgroundImage: photoUrl.trim().isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl.trim().isEmpty
              ? const Icon(Icons.person, color: Color(0xFF666670))
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16 / 2,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B1B1D),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '($category)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7A7A80),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7A7A80),
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.star, color: Colors.amber, size: 16),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(color: Color(0xFF707078), fontSize: 16 / 2),
        ),
      ],
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF2B2B31),
            fontSize: 16 / 2,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: valueStyle ??
              const TextStyle(
                color: Color(0xFF707078),
                fontSize: 16 / 2,
              ),
        ),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD7D7DE),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: const [
          Icon(Icons.credit_card, color: Color(0xFF2B2B31)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mastercard  **** 9999',
              style: TextStyle(
                color: Color(0xFF1B1B1D),
                fontSize: 16 / 2,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: Color(0xFF1B1B1D)),
        ],
      ),
    );
  }
}
