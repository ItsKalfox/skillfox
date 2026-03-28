import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../home/customer_details_screen.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  GoogleMapController? _mapController;
  Position? _currentPosition;
  Map<String, dynamic>? _workerData;
  bool _isLoadingProfile = true;

  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _pendingRequests = [];

  // ── Live completed jobs count (job_done status from requests) ──
  int _completedJobsCount = 0;
  StreamSubscription? _completedJobsSubscription;

  StreamSubscription? _requestSubscription;

  @override
  void initState() {
    super.initState();
    _loadWorkerProfile();
    _getCurrentLocation();
    _listenToPendingRequests();
    _listenToCompletedJobs(); // ← new
  }

  @override
  void dispose() {
    _requestSubscription?.cancel();
    _completedJobsSubscription?.cancel();
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
      _rebuildMarkers();
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

  void _listenToPendingRequests() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _requestSubscription = _firestore
        .collection('requests')
        .where('workerId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;

          final requests = snapshot.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            return data;
          }).toList();

          setState(() {
            _pendingRequests = requests;
          });

          _rebuildMarkers();
        });
  }

  // ── Counts all requests with status == 'job_done' for this worker ──
  void _listenToCompletedJobs() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _completedJobsSubscription = _firestore
        .collection('requests')
        .where('workerId', isEqualTo: uid)
        .where('status', isEqualTo: 'job_done')
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;
          setState(() {
            _completedJobsCount = snapshot.docs.length;
          });
        });
  }

  void _rebuildMarkers() {
    final markers = <Marker>{};

    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('my_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'You (Worker)'),
        ),
      );
    }

    for (final req in _pendingRequests) {
      final lat = (req['latitude'] as num?)?.toDouble();
      final lng = (req['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      markers.add(
        Marker(
          markerId: MarkerId(req['id'] as String),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow,
          ),
          infoWindow: InfoWindow(
            title: req['customerName'] as String? ?? 'Customer',
            snippet:
                req['category'] as String? ??
                req['serviceType'] as String? ??
                '',
          ),
        ),
      );
    }

    if (mounted) {
      setState(() => _markers = markers);
    }
  }

  String _distanceLabel(Map<String, dynamic> request) {
    if (_currentPosition == null) return '';
    final lat = (request['latitude'] as num?)?.toDouble();
    final lng = (request['longitude'] as num?)?.toDouble();
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

  void _openCustomerDetail(Map<String, dynamic> request) async {
    final requestId = request['id'] as String;

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => CustomerDetailScreen(request: request)),
    );

    if (result == 'accepted') {
      await _firestore.collection('requests').doc(requestId).update({
        'status': 'accepted',
        'workerId': _auth.currentUser?.uid,
        'workerName': _workerData?['name'] ?? '',
        'acceptedAt': FieldValue.serverTimestamp(),
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
    } else if (result == 'declined') {
      await _firestore.collection('requests').doc(requestId).update({
        'status': 'rejected',
        'rejectedBy': 'worker',
        'rejectedAt': FieldValue.serverTimestamp(),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final name = _workerData?['name'] ?? 'Worker';
    final category = _workerData?['category'] ?? '';
    final profilePhoto = _workerData?['profilePhotoUrl'] ?? '';
    final coverPhoto = _workerData?['coverPhotoUrl'] ?? '';
    final isAvailable = _workerData?['isAvailable'] ?? false;
    // completedJobsCount from _workerData removed — now using _completedJobsCount

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FA),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildProfileHeader(
              name: name,
              category: category,
              profilePhoto: profilePhoto,
              coverPhoto: coverPhoto,
              isAvailable: isAvailable,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildStatsRow(
                nearbyCount: _pendingRequests.length,
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
                    'Pending Requests',
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
                          '${_pendingRequests.length} pending',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 240,
                      child: _currentPosition == null
                          ? Container(
                              color: const Color(0xFFE8EAF3),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 10),
                                    Text(
                                      'Getting your location…',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF8A8A8A),
                                      ),
                                    ),
                                  ],
                                ),
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
                              zoomControlsEnabled: true,
                              zoomGesturesEnabled: true,
                              scrollGesturesEnabled: true,
                              mapToolbarEnabled: false,
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _MapLegendDot(
                        color: const Color(0xFF4B7DF3),
                        label: 'You (Worker)',
                      ),
                      const SizedBox(width: 16),
                      _MapLegendDot(
                        color: const Color(0xFFF5C518),
                        label: 'Pending Customer',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Pending request cards ──
          _pendingRequests.isEmpty
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
                            'No pending requests right now',
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
                    final request = _pendingRequests[index];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: GestureDetector(
                        onTap: () => _openCustomerDetail(request),
                        child: _buildRequestCard(request),
                      ),
                    );
                  }, childCount: _pendingRequests.length),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildProfileHeader({
    required String name,
    required String category,
    required String profilePhoto,
    required String coverPhoto,
    required bool isAvailable,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
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
              const SizedBox(height: 6),
              if (category.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF0FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B7DF3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 340),
      ],
    );
  }

  Widget _buildStatsRow({required int nearbyCount, required bool isAvailable}) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.list_alt_rounded,
            value: _completedJobsCount.toString(), // ← live from requests
            label: 'Completed',
            iconColor: const Color(0xFF4B7DF3),
            bgColor: const Color(0xFFEEF0FF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.pending_actions_rounded,
            value: nearbyCount.toString(),
            label: 'Pending',
            iconColor: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFEF3C7),
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
    final customerName = request['customerName'] as String? ?? 'Customer';
    final category =
        request['category'] as String? ??
        request['serviceType'] as String? ??
        'Service Request';
    final customerPhoto = request['customerPhotoUrl'] as String? ?? '';
    final description = request['description'] as String? ?? '';
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
                      category,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
            ],
          ),
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

// ─────────────────────────────────────────
// Map Legend Dot
// ─────────────────────────────────────────
class _MapLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _MapLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF555555),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// Stat Card
// ─────────────────────────────────────────
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
