import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> request;

  const CustomerDetailScreen({super.key, required this.request});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  String _timeAgo(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime date;
    try {
      date = (timestamp as dynamic).toDate();
    } catch (_) {
      return '';
    }
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final customerName = req['customerName'] ?? 'Customer';
    final serviceType = req['serviceType'] ?? 'Service Request';
    final description = req['description'] ?? '';
    final customerPhoto = req['customerPhotoUrl'] ?? '';
    final lat = req['customerLat'] as double?;
    final lng = req['customerLng'] as double?;
    final timeAgo = _timeAgo(req['createdAt']);
    final requestId = req['id'] ?? '';

    final hasLocation = lat != null && lng != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FA),
      body: CustomScrollView(
        slivers: [
          // ── Blue header ──
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Blue gradient bg
                Container(
                  height: 220,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF5AA4F6), Color(0xFF4B7DF3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),

                // Back button
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Customer Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
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
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                  ),
                ),

                // Avatar
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
                      backgroundImage: customerPhoto.isNotEmpty
                          ? NetworkImage(customerPhoto)
                          : null,
                      child: customerPhoto.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 48,
                              color: Color(0xFF5B6475),
                            )
                          : null,
                    ),
                  ),
                ),

                // Name + service type
                Positioned(
                  top: 215,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        customerName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF0FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          serviceType,
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

                const SizedBox(height: 310),
              ],
            ),
          ),

          // ── Info cards ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Request info card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
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
                        const Text(
                          'Request Info',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 14),

                        if (requestId.isNotEmpty)
                          _InfoRow(
                            icon: Icons.tag_rounded,
                            label: 'Request ID',
                            value: requestId,
                          ),
                        if (timeAgo.isNotEmpty)
                          _InfoRow(
                            icon: Icons.access_time_rounded,
                            label: 'Posted',
                            value: timeAgo,
                          ),
                        _InfoRow(
                          icon: Icons.build_outlined,
                          label: 'Service',
                          value: serviceType,
                        ),
                        if (description.isNotEmpty)
                          _InfoRow(
                            icon: Icons.notes_rounded,
                            label: 'Description',
                            value: description,
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Location map card
                  if (hasLocation) ...[
                    const Text(
                      'Customer Location',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 250,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(lat, lng),
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('customer'),
                              position: LatLng(lat, lng),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueRed,
                              ),
                              infoWindow: InfoWindow(title: customerName),
                            ),
                          },
                          onMapCreated: (controller) {
                            _mapController = controller;
                          },
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          myLocationEnabled: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),

          // ── Bottom spacing for buttons ──
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),

      // ── Accept / Decline buttons ──
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, 'declined'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Decline',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, 'accepted'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B7DF3),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Accept',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF0FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF4B7DF3)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8A8A8A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
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
