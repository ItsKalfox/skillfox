import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../home/customer_details_screen.dart';
import '../../../services/request_payment_service.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RequestPaymentService _paymentService = RequestPaymentService();

  GoogleMapController? _mapController;
  Position? _currentPosition;
  Map<String, dynamic>? _workerData;
  bool _isLoadingProfile = true;

  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _nearbyRequests = [];
  StreamSubscription? _requestSubscription;

  @override
  void initState() {
    super.initState();
    _loadWorkerProfile();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _requestSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadWorkerProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!mounted) return;

    setState(() {
      _workerData = doc.data();
      _isLoadingProfile = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = position;
      });

      _updateWorkerLocation(position);
      _listenToNearbyRequests(position);
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _updateWorkerLocation(Position position) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).update({
      'lat': position.latitude,
      'lng': position.longitude,
      'lastLocationUpdate': FieldValue.serverTimestamp(),
    });
  }

  void _listenToNearbyRequests(Position position) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _requestSubscription = _firestore
        .collection('service_requests')
        .where(
          'status',
          whereIn: const ['pending', 'arriving', 'inspection', 'working'],
        )
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;

          final requests = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

          final nearby = requests.where((req) {
            final status = (req['status'] as String?) ?? 'pending';
            final requestWorkerId = (req['workerId'] as String?) ?? '';

            if (status != 'pending') {
              return requestWorkerId == uid;
            }

            if (requestWorkerId.isNotEmpty && requestWorkerId != uid) {
              return false;
            }

            final lat = (req['customerLat'] as num?)?.toDouble();
            final lng = (req['customerLng'] as num?)?.toDouble();
            if (lat == null || lng == null) return false;

            final distance = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              lat,
              lng,
            );
            return distance <= 10000;
          }).toList();

          setState(() {
            _nearbyRequests = nearby;
            _buildMarkers(position, nearby);
          });
        });
  }

  void _buildMarkers(Position myPos, List<Map<String, dynamic>> requests) {
    final markers = <Marker>{};

    markers.add(
      Marker(
        markerId: const MarkerId('my_location'),
        position: LatLng(myPos.latitude, myPos.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'You are here'),
      ),
    );

    for (final req in requests) {
      final lat = (req['customerLat'] as num?)?.toDouble();
      final lng = (req['customerLng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      markers.add(
        Marker(
          markerId: MarkerId(req['id']),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: req['customerName'] ?? 'Customer',
            snippet: req['serviceType'] ?? '',
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  Future<void> _acceptRequest(
    String requestId,
    Map<String, dynamic> request,
  ) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore.collection('service_requests').doc(requestId).update({
        'status': 'arriving',
        'workerId': uid,
        'workerName': _workerData?['name'] ?? '',
        'workerCategory': _workerData?['category'] ?? '',
        'workerPhotoUrl': _workerData?['profilePhotoUrl'] ?? '',
        'workerPhone': _workerData?['phone'] ?? '',
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request from ${request['customerName'] ?? 'Customer'} accepted!',
          ),
          backgroundColor: const Color(0xFF22C55E),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to accept: $e')));
    }
  }

  Future<void> _declineRequest(
    String requestId,
    Map<String, dynamic> request,
  ) async {
    try {
      await _firestore.collection('service_requests').doc(requestId).update({
        'status': 'unavailable',
        'declinedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request from ${request['customerName'] ?? 'Customer'} declined.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to decline: $e')));
    }
  }

  String _distanceLabel(Map<String, dynamic> request) {
    if (_currentPosition == null) return '';
    final lat = (request['customerLat'] as num?)?.toDouble();
    final lng = (request['customerLng'] as num?)?.toDouble();
    if (lat == null || lng == null) return '';

    final dist = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    );

    if (dist < 1000) return '${dist.toStringAsFixed(0)}m away';
    return '${(dist / 1000).toStringAsFixed(1)}km away';
  }

  /// Navigate to CustomerDetailScreen and handle accept/decline result
  void _openCustomerDetail(Map<String, dynamic> request) async {
    final status = (request['status'] as String?) ?? 'pending';
    if (status != 'pending') {
      return;
    }

    final requestId = request['id'] as String;

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => CustomerDetailScreen(request: request)),
    );

    if (result == 'accepted') {
      await _acceptRequest(requestId, request);
    } else if (result == 'declined') {
      await _declineRequest(requestId, request);
    }
  }

  Future<void> _advanceRequestStatus(
    String requestId,
    String nextStatus, {
    String? currentStatus,
    String? paymentStatus,
  }) async {
    if (currentStatus == 'inspection' && paymentStatus != 'held') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waiting for customer payment.')),
      );
      return;
    }

    try {
      await _firestore.collection('service_requests').doc(requestId).update({
        'status': nextStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (nextStatus == 'finished') {
        await _paymentService.releaseEscrow(requestId: requestId);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  String _nextActionLabel(String status) {
    switch (status) {
      case 'arriving':
        return 'Start Inspection';
      case 'inspection':
        return 'Start Working';
      case 'working':
        return 'Mark Finished';
      default:
        return '';
    }
  }

  String _nextStatus(String status) {
    switch (status) {
      case 'arriving':
        return 'inspection';
      case 'inspection':
        return 'working';
      case 'working':
        return 'finished';
      default:
        return status;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'arriving':
        return 'Arriving';
      case 'inspection':
        return 'Inspection';
      case 'working':
        return 'Working';
      case 'finished':
        return 'Finished';
      case 'unavailable':
        return 'Unavailable';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final name = _workerData?['name'] ?? 'Worker';
    final category = _workerData?['category'] ?? '';
    final rating = (_workerData?['rating'] ?? 0.0).toDouble();
    final profilePhoto = _workerData?['profilePhotoUrl'] ?? '';
    final coverPhoto = _workerData?['coverPhotoUrl'] ?? '';
    final isAvailable = _workerData?['isAvailable'] ?? false;
    final completedJobs = _workerData?['completedJobsCount'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FA),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildProfileHeader(
              name: name,
              category: category,
              rating: rating,
              profilePhoto: profilePhoto,
              coverPhoto: coverPhoto,
              isAvailable: isAvailable,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildStatsRow(
                completedJobs: completedJobs,
                nearbyCount: _nearbyRequests.length,
                isAvailable: isAvailable,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Row(
                children: [
                  const Text(
                    'Nearby Requests',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF0FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4B7DF3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${_nearbyRequests.length} pending',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4B7DF3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Map ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 220,
                  child: _currentPosition == null
                      ? Container(
                          color: const Color(0xFFE8EAF3),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            zoom: 13,
                          ),
                          markers: _markers,
                          onMapCreated: (controller) {
                            _mapController = controller;
                          },
                          myLocationEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                        ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Customer request list ──
          _nearbyRequests.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'No nearby requests right now',
                            style: TextStyle(
                              color: Color(0xFF8A8A8A),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final request = _nearbyRequests[index];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      // Pending requests can open details; active ones use inline action.
                      child: GestureDetector(
                        onTap: (request['status'] as String? ?? 'pending') ==
                                'pending'
                            ? () => _openCustomerDetail(request)
                            : null,
                        child: _buildRequestCard(request),
                      ),
                    );
                  }, childCount: _nearbyRequests.length),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildProfileHeader({
    required String name,
    required String category,
    required double rating,
    required String profilePhoto,
    required String coverPhoto,
    required bool isAvailable,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Cover gradient
        Container(
          height: 220,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5AA4F6), Color(0xFF4B7DF3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: coverPhoto.isNotEmpty
              ? Image.network(
                  coverPhoto,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  color: Colors.black.withOpacity(0.25),
                  colorBlendMode: BlendMode.darken,
                )
              : null,
        ),

        // Top bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Text(
                    'Home',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // White card curve
        Positioned(
          top: 160,
          left: 0,
          right: 0,
          child: Container(
            height: 120,
            decoration: const BoxDecoration(
              color: Color(0xFFF2F4FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
          ),
        ),

        // Profile avatar
        Positioned(
          top: 110,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFF2F4FA),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFFE6EAF7),
              backgroundImage: profilePhoto.isNotEmpty
                  ? NetworkImage(profilePhoto)
                  : null,
              child: profilePhoto.isEmpty
                  ? const Icon(Icons.person, size: 48, color: Color(0xFF5B6475))
                  : null,
            ),
          ),
        ),

        // ✅ Name → Category → Stars (all three, in order)
        Positioned(
          top: 215,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 4),
              // ── CATEGORY (shown between name and stars) ──
              if (category.isNotEmpty)
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B7DF3),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 340),
      ],
    );
  }

  Widget _buildStatsRow({
    required int completedJobs,
    required int nearbyCount,
    required bool isAvailable,
  }) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.list_alt_rounded,
            value: completedJobs.toString(),
            label: 'Requests',
            iconColor: const Color(0xFF4B7DF3),
            bgColor: const Color(0xFFEEF0FF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.near_me_rounded,
            value: nearbyCount.toString(),
            label: 'Within 5km',
            iconColor: const Color(0xFF22C55E),
            bgColor: const Color(0xFFEAFBF0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_outline_rounded,
            value: isAvailable ? 'Active' : 'Offline',
            label: 'Status',
            iconColor: isAvailable
                ? const Color(0xFF22C55E)
                : const Color(0xFF8A8A8A),
            bgColor: isAvailable
                ? const Color(0xFFEAFBF0)
                : const Color(0xFFF0F0F0),
            valueColor: isAvailable
                ? const Color(0xFF22C55E)
                : const Color(0xFF8A8A8A),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = (request['status'] as String?) ?? 'pending';
    final paymentStatus = (request['paymentStatus'] as String?) ?? 'unpaid';
    final customerName = request['customerName'] ?? 'Customer';
    final serviceType = request['serviceType'] ?? 'Service Request';
    final customerPhoto = request['customerPhotoUrl'] ?? '';
    final description = request['description'] ?? '';
    final distLabel = _distanceLabel(request);
    final timestamp = request['createdAt'] as Timestamp?;
    final timeAgo = timestamp != null ? _timeAgo(timestamp.toDate()) : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE6EAF7),
                backgroundImage: customerPhoto.isNotEmpty
                    ? NetworkImage(customerPhoto)
                    : null,
                child: customerPhoto.isEmpty
                    ? const Icon(
                        Icons.person,
                        size: 24,
                        color: Color(0xFF5B6475),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      serviceType,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4B7DF3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (distLabel.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        distLabel,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ),
                  if (timeAgo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF8A8A8A),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          if (description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF555555),
                height: 1.4,
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Status + action
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF0FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _statusLabel(status),
                  style: const TextStyle(
                    color: Color(0xFF4B7DF3),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (status == 'pending') ...[
                Text(
                  'Tap to view details',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ] else if (status != 'finished')
                GestureDetector(
                  onTap: () => _advanceRequestStatus(
                    request['id'] as String,
                    _nextStatus(status),
                    currentStatus: status,
                    paymentStatus: paymentStatus,
                  ),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4B7DF3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _nextActionLabel(status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (status != 'pending') ...[
            const SizedBox(height: 8),
            Text(
              'Payment: $paymentStatus',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF7A7A80),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final Color? valueColor;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: valueColor ?? const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF8A8A8A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
