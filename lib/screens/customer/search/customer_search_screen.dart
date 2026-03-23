import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../models/worker.dart';
import '../../../services/location_service.dart';
import '../../customer/worker/worker_profile.dart';

class CustomerSearchScreen extends StatefulWidget {
  final double customerLat;
  final double customerLng;

  const CustomerSearchScreen({
    super.key,
    required this.customerLat,
    required this.customerLng,
  });

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen>
    with TickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;

  String query = '';
  String selectedCategory = 'All';
  String sortOption = 'Rating';

  // Map visibility
  bool _mapVisible = true;
  late AnimationController _mapAnimController;
  late Animation<double> _mapHeightAnim;
  late Animation<double> _mapOpacityAnim;

  // Page fade
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // ── Categories ────────────────────────────────────────────────────
  static const _categories = [
    ('All', Icons.apps_rounded),
    ('Mechanic', Icons.build_rounded),
    ('Teacher', Icons.school_rounded),
    ('Plumber', Icons.plumbing_rounded),
    ('Electrician', Icons.electrical_services_rounded),
    ('Cleaner', Icons.cleaning_services_rounded),
    ('Caregiver', Icons.health_and_safety_rounded),
    ('Mason', Icons.construction_rounded),
    ('Handyman', Icons.handyman_rounded),
  ];

  // ── Design tokens ─────────────────────────────────────────────────
  static const _primaryBlue = Color(0xFF469FEF);
  static const _accentBlue = Color(0xFF5C75F0);
  static const _bgPage = Color(0xFFF5F7FA);
  static const _bgCard = Color(0xFFFFFFFF);
  static const _textPrimary = Color(0xFF1A1D26);
  static const _textMuted = Color(0xFF8A919E);
  static const _borderColor = Color(0xFFEAECF0);
  static const _amber = Color(0xFFF5A623);
  static const _green = Color(0xFF27C840);

  static const double _mapExpandedHeight = 200.0;

  @override
  void initState() {
    super.initState();

    // Page fade-in
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Map collapse/expand animation
    _mapAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 1.0, // starts expanded
    );
    _mapHeightAnim = Tween<double>(begin: 0.0, end: _mapExpandedHeight).animate(
      CurvedAnimation(parent: _mapAnimController, curve: Curves.easeInOutCubic),
    );
    _mapOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mapAnimController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _mapAnimController.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CustomerSearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.customerLat != oldWidget.customerLat ||
        widget.customerLng != oldWidget.customerLng) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(widget.customerLat, widget.customerLng),
        ),
      );
    }
  }

  // ── Toggle map ────────────────────────────────────────────────────
  void _toggleMap() {
    setState(() => _mapVisible = !_mapVisible);
    if (_mapVisible) {
      _mapAnimController.forward();
    } else {
      _mapAnimController.reverse();
    }
  }

  // ── Build markers from the current filtered worker list ───────────
  Set<Marker> _buildMarkers(List<Map<String, dynamic>> workers) {
    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('customer'),
        position: LatLng(widget.customerLat, widget.customerLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You'),
        zIndex: 99,
      ),
    };

    for (final w in workers) {
      final GeoPoint? loc = w['location'];
      if (loc == null) continue;
      final id = w['uid'] ?? w['id'] ?? UniqueKey().toString();
      markers.add(
        Marker(
          markerId: MarkerId(id),
          position: LatLng(loc.latitude, loc.longitude),
          infoWindow: InfoWindow(
            title: w['name'] ?? 'Worker',
            snippet: w['jobType'] ?? '',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    return markers;
  }

  // ── Filtering + sorting ───────────────────────────────────────────
  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> workers) {
    List<Map<String, dynamic>> filtered = workers.where((w) {
      final name = (w['name'] ?? '').toLowerCase();
      final job = (w['jobType'] ?? '').toLowerCase();
      final search = query.toLowerCase();
      return (name.contains(search) || job.contains(search)) &&
          (selectedCategory == 'All' || job == selectedCategory.toLowerCase());
    }).toList();

    if (sortOption == 'Rating') {
      filtered.sort((a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0));
    } else {
      filtered.sort(
        (a, b) => (a['distance'] ?? 999.0).compareTo(b['distance'] ?? 999.0),
      );
    }
    return filtered;
  }

  // ── Navigation ────────────────────────────────────────────────────
  void _openFullMap(Set<Marker> markers) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullMapScreen(
          customerLat: widget.customerLat,
          customerLng: widget.customerLng,
          markers: markers,
        ),
      ),
    );
  }

  void _openWorkerProfile(Map<String, dynamic> data, double distanceKm) {
    final GeoPoint? loc = data['location'];
    final worker = Worker(
      id: data['uid'] ?? '',
      name: data['name'] ?? 'Worker',
      category: data['jobType'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? 0,
      distanceKm: distanceKm,
      profilePhotoUrl: data['profilePhotoUrl'] ?? data['profileImageUrl'] ?? '',
      address: data['address'] ?? '',
      hasOffer: data['hasOffer'] ?? false,
      offerType: data['offerType'] ?? '',
      offerDetails: data['offerDetails'] ?? '',
      travelFee: (data['travelFee'] as num?)?.toDouble() ?? 0.0,
      travelMinutes: (data['travelMinutes'] as num?)?.toInt() ?? 0,
      completedJobsCount: (data['completedJobsCount'] as num?)?.toInt() ?? 0,
      isFeatured: data['isFeatured'] ?? false,
      featuredWeekKey: data['featuredWeekKey'] ?? '',
      isFavorite: data['isFavorite'] ?? false,
      lat: loc?.latitude,
      lng: loc?.longitude,
    );

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => WorkerProfileScreen(worker: worker),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: StreamBuilder<Map<String, dynamic>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('status', isEqualTo: 'active')
              .where('role', isEqualTo: 'worker')
              .snapshots()
              .asyncMap((snapshot) async {
                double searchRadius = 30.0;
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                  if (userDoc.exists) {
                    final data = userDoc.data();
                    if (data != null && data['searchRadius'] != null) {
                      searchRadius = (data['searchRadius'] as num).toDouble();
                    }
                  }
                }
                return {'snapshot': snapshot, 'searchRadius': searchRadius};
              }),
          builder: (context, snapshotData) {
            // Compute distances once per snapshot
            List<Map<String, dynamic>> allWorkers = [];
            final isLoading = !snapshotData.hasData;

            if (snapshotData.hasData) {
              final snapData = snapshotData.data!;
              final QuerySnapshot snapshot = snapData['snapshot'] as QuerySnapshot;
              final double searchRadius = snapData['searchRadius'] as double;

              allWorkers = snapshot.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final GeoPoint? loc = data['location'];
                data['distance'] = loc != null
                    ? _locationService.calculateDistanceKm(
                        startLat: widget.customerLat,
                        startLng: widget.customerLng,
                        endLat: loc.latitude,
                        endLng: loc.longitude,
                      )
                    : 999.0;
                return data;
              }).where((w) => (w['distance'] as double) <= searchRadius).toList();
            }

            final filtered = _applyFilters(allWorkers);
            final markers = _buildMarkers(filtered);

            return Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 4),
                _buildCategoryChips(),
                const SizedBox(height: 4),
                _buildSortAndToggleRow(filtered.length),
                const SizedBox(height: 6),
                _buildAnimatedMap(markers, filtered.length, isLoading),
                const SizedBox(height: 8),
                Expanded(child: _buildWorkerList(filtered, isLoading)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _bgCard,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      title: const Text(
        'Find Workers',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _borderColor),
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => query = v),
        style: const TextStyle(
          fontSize: 14,
          color: _textPrimary,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: 'Search by name or skill…',
          hintStyle: const TextStyle(fontSize: 14, color: _textMuted),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: _textMuted,
            size: 20,
          ),
          suffixIcon: query.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => query = '');
                  },
                  child: const Icon(
                    Icons.close_rounded,
                    color: _textMuted,
                    size: 18,
                  ),
                )
              : null,
          filled: true,
          fillColor: _bgCard,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Category chips ────────────────────────────────────────────────
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _categories.map((c) {
          final label = c.$1;
          final icon = c.$2;
          final isSelected = selectedCategory == label;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => selectedCategory = label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryBlue : _bgCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? _primaryBlue : _borderColor,
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _primaryBlue.withOpacity(0.22),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 15,
                      color: isSelected ? Colors.white : _textMuted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected ? Colors.white : _textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Sort row + map toggle ─────────────────────────────────────────
  Widget _buildSortAndToggleRow(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text(
            'Sort by:',
            style: TextStyle(fontSize: 12, color: _textMuted),
          ),
          const SizedBox(width: 8),
          _sortChip('Rating', Icons.star_rounded),
          const SizedBox(width: 6),
          _sortChip('Nearest', Icons.near_me_rounded),
          const Spacer(),
          // Map hide/show button
          GestureDetector(
            onTap: _toggleMap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _mapVisible ? _primaryBlue.withOpacity(0.1) : _bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _mapVisible ? _primaryBlue : _borderColor,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _mapVisible ? Icons.map_rounded : Icons.map_outlined,
                    size: 13,
                    color: _mapVisible ? _primaryBlue : _textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _mapVisible ? 'Hide Map' : 'Show Map',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _mapVisible ? _primaryBlue : _textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortChip(String label, IconData icon) {
    final isSelected = sortOption == label;
    return GestureDetector(
      onTap: () => setState(() => sortOption = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? _accentBlue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? _accentBlue : _borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isSelected ? _accentBlue : _textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? _accentBlue : _textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Animated collapsible map ──────────────────────────────────────
  Widget _buildAnimatedMap(
    Set<Marker> markers,
    int workerCount,
    bool isLoading,
  ) {
    return AnimatedBuilder(
      animation: _mapAnimController,
      builder: (_, __) {
        final height = _mapHeightAnim.value;
        if (height <= 0) return const SizedBox.shrink();
        return Opacity(
          opacity: _mapOpacityAnim.value,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Stack(
                    children: [
                      // Fully interactive Google Map
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            widget.customerLat,
                            widget.customerLng,
                          ),
                          zoom: 13,
                        ),
                        markers: markers,
                        onMapCreated: (ctrl) => _mapController = ctrl,
                        // All gestures enabled
                        scrollGesturesEnabled: true,
                        zoomGesturesEnabled: true,
                        rotateGesturesEnabled: true,
                        tiltGesturesEnabled: true,
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        liteModeEnabled: false,
                      ),

                      // Status pill — top left
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.93),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.07),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLoading) ...[
                                const SizedBox(
                                  width: 9,
                                  height: 9,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: _primaryBlue,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'Loading…',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _textMuted,
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: _green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '$workerCount workers nearby',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _textPrimary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Controls — bottom right
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Re-centre on user
                            _mapIconBtn(
                              icon: Icons.my_location_rounded,
                              onTap: () {
                                _mapController?.animateCamera(
                                  CameraUpdate.newLatLng(
                                    LatLng(
                                      widget.customerLat,
                                      widget.customerLng,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 6),
                            // Open full-screen map
                            _mapIconBtn(
                              icon: Icons.fullscreen_rounded,
                              onTap: () => _openFullMap(markers),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _mapIconBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: _textPrimary),
      ),
    );
  }

  // ── Worker list ───────────────────────────────────────────────────
  Widget _buildWorkerList(List<Map<String, dynamic>> filtered, bool isLoading) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryBlue),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search_rounded,
              size: 48,
              color: _textMuted.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            const Text(
              'No workers found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _textMuted,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try a different search or category',
              style: TextStyle(fontSize: 13, color: _textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final w = filtered[index];
        final distanceKm = (w['distance'] ?? 0).toDouble();
        return _WorkerCard(
          data: w,
          distanceKm: distanceKm,
          onTap: () => _openWorkerProfile(w, distanceKm),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Worker Card
// ─────────────────────────────────────────────────────────────────────────────

class _WorkerCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final double distanceKm;
  final VoidCallback onTap;

  const _WorkerCard({
    required this.data,
    required this.distanceKm,
    required this.onTap,
  });

  @override
  State<_WorkerCard> createState() => _WorkerCardState();
}

class _WorkerCardState extends State<_WorkerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scale;

  static const _primaryBlue = Color(0xFF469FEF);
  static const _bgCard = Color(0xFFFFFFFF);
  static const _textPrimary = Color(0xFF1A1D26);
  static const _textMuted = Color(0xFF8A919E);
  static const _borderColor = Color(0xFFEAECF0);
  static const _amber = Color(0xFFF5A623);
  static const _green = Color(0xFF27C840);

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.data;
    final photoUrl = w['profilePhotoUrl'] ?? w['profileImageUrl'] ?? '';
    final isAvailable = w['isAvailable'] ?? true;
    final rating = (w['rating'] ?? 0).toDouble();
    final ratingStr = rating.toStringAsFixed(1);
    final distStr = widget.distanceKm < 1
        ? '${(widget.distanceKm * 1000).toStringAsFixed(0)} m'
        : '${widget.distanceKm.toStringAsFixed(1)} km';
    final hasOffer = w['hasOffer'] ?? false;

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar with availability dot
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFEDF2FF),
                        border: Border.all(
                          color: _primaryBlue.withOpacity(0.15),
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: photoUrl.isNotEmpty
                            ? Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person_rounded,
                                  size: 26,
                                  color: Color(0xFF8A919E),
                                ),
                              )
                            : const Icon(
                                Icons.person_rounded,
                                size: 26,
                                color: Color(0xFF8A919E),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: isAvailable ? _green : const Color(0xFFBBBBBB),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Name + job + stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              w['name'] ?? 'Worker',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _textPrimary,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasOffer) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Text(
                                'Offer',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        w['jobType'] ?? '',
                        style: const TextStyle(fontSize: 12, color: _textMuted),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: _amber,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            ratingStr,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.near_me_rounded,
                            size: 12,
                            color: _textMuted,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            distStr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: _textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full Screen Map
// ─────────────────────────────────────────────────────────────────────────────

class _FullMapScreen extends StatelessWidget {
  final double customerLat;
  final double customerLng;
  final Set<Marker> markers;

  const _FullMapScreen({
    required this.customerLat,
    required this.customerLng,
    required this.markers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Workers Near You',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.2),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1D26),
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEAECF0)),
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(customerLat, customerLng),
          zoom: 13,
        ),
        markers: markers,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        scrollGesturesEnabled: true,
        zoomGesturesEnabled: true,
        rotateGesturesEnabled: true,
        tiltGesturesEnabled: true,
      ),
    );
  }
}