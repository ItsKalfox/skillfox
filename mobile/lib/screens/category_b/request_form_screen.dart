// lib/screens/category_b/category_b_request_form_screen.dart
//
// Category B — One-time Fixed Jobs (cleaning, handyman)
// Customer fills address, description, preferred schedule → Firestore doc
// created → CustomerRequestScreen opens (same tracking screen as Cat A).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../models/worker.dart';
import '../category_a/customer_request_screen.dart';

class _C {
  static const gradA = Color(0xFF10B981);
  static const gradB = Color(0xFF059669);
  static const bg = Color(0xFFF8FAFC);
  static const cardBg = Colors.white;
  static const border = Color(0xFFE2E8F0);
  static const txt1 = Color(0xFF0F172A);
  static const txt2 = Color(0xFF64748B);
  static const muted = Color(0xFF94A3B8);
  static const green = Color(0xFF16A34A);
  static const red = Color(0xFFEF4444);
  static const star = Color(0xFFF59E0B);
}

class CategoryBRequestFormScreen extends StatefulWidget {
  final Worker worker;
  const CategoryBRequestFormScreen({super.key, required this.worker});

  @override
  State<CategoryBRequestFormScreen> createState() =>
      _CategoryBRequestFormScreenState();
}

class _CategoryBRequestFormScreenState
    extends State<CategoryBRequestFormScreen> {
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _scheduleCtrl = TextEditingController(); // preferred date/time

  LatLng _location = const LatLng(7.0840, 80.0098);
  GoogleMapController? _mapCtrl;

  bool _loading = false;
  bool _locationLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _scheduleCtrl.dispose();
    super.dispose();
  }

  // ── Location ────────────────────────────────────────────────────────────────
  Future<void> _fetchLocation() async {
    setState(() => _locationLoading = true);
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _snack('Location services disabled.', isError: true);
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          _snack('Location permission denied.', isError: true);
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        _snack('Location permanently denied.', isError: true);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final loc = LatLng(pos.latitude, pos.longitude);

      try {
        final marks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (marks.isNotEmpty) {
          final p = marks.first;
          final parts = [
            p.subLocality,
            p.locality,
            p.administrativeArea,
            p.country,
          ].where((s) => s != null && s!.isNotEmpty).toList();
          _addressCtrl.text = parts.join(', ');
        }
      } catch (_) {
        _addressCtrl.text =
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      }

      setState(() => _location = loc);
      _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(loc, 15));
    } catch (e) {
      _snack('Could not get location: $e', isError: true);
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  Future<void> _onMapTap(LatLng pos) async {
    setState(() => _location = pos);
    try {
      final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (marks.isNotEmpty) {
        final p = marks.first;
        final parts = [
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.country,
        ].where((s) => s != null && s!.isNotEmpty).toList();
        _addressCtrl.text = parts.join(', ');
      }
    } catch (_) {}
  }

  // ── Submit ──────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_descCtrl.text.trim().isEmpty) {
      _snack('Please describe the job.', isError: true);
      return;
    }
    if (_addressCtrl.text.trim().isEmpty) {
      _snack('Please enter your address.', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final customerId = user?.uid ?? '';

      String customerName = 'Customer';
      if (customerId.isNotEmpty) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(customerId)
              .get();
          if (doc.exists) {
            customerName =
                (doc.data()?['name'] as String?)?.trim().isNotEmpty == true
                ? doc.data()!['name'] as String
                : user?.email ?? 'Customer';
          }
        } catch (_) {
          customerName = user?.email ?? 'Customer';
        }
      }

      final docRef = await FirebaseFirestore.instance
          .collection('requests')
          .add({
            // worker info
            'workerId': widget.worker.id,
            'workerName': widget.worker.name,
            'category': widget.worker.category,
            'categoryType': 'B', // ← Category B flag
            // customer info
            'customerId': customerId,
            'customerName': customerName,
            // job details
            'description': _descCtrl.text.trim(),
            'address': _addressCtrl.text.trim(),
            'preferredSchedule': _scheduleCtrl.text.trim(),
            'latitude': _location.latitude,
            'longitude': _location.longitude,
            // status
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
            // fees (travel fee from worker model)
            'travelFee': widget.worker.travelFee,
          });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerRequestScreen(
            requestId: docRef.id,
            worker: widget.worker,
          ),
        ),
      );
    } catch (e) {
      _snack('Error submitting request: $e', isError: true);
      setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? _C.red : _C.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          // ── header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_C.gradA, _C.gradB]),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 4,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Book a Job',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.worker.name,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ONE-TIME JOB',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  // ── worker card
                  _workerCard(),
                  const SizedBox(height: 20),

                  // ── job description
                  _sectionLabel('Job Description', required: true),
                  const SizedBox(height: 8),
                  _textArea(
                    _descCtrl,
                    hint:
                        'Describe what you need done (e.g. Full house clean, 3 bedrooms, 2 bathrooms…)',
                  ),
                  const SizedBox(height: 18),

                  // ── preferred schedule
                  _sectionLabel('Preferred Date & Time'),
                  const SizedBox(height: 8),
                  _textField(
                    _scheduleCtrl,
                    hint: 'e.g. Saturday 15 June, 9:00 AM',
                    icon: Icons.calendar_today_outlined,
                  ),
                  const SizedBox(height: 18),

                  // ── address
                  _sectionLabel('Your Address', required: true),
                  const SizedBox(height: 8),
                  _addressField(),
                  const SizedBox(height: 12),

                  // ── map
                  _mapCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── bottom submit
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
              16,
              14,
              16,
              MediaQuery.of(context).padding.bottom + 20,
            ),
            child: GestureDetector(
              onTap: _loading ? null : _submit,
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_C.gradA, _C.gradB]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _C.gradA.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Submit Request',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sub-widgets ──────────────────────────────────────────────────────────────

  Widget _workerCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _C.cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _C.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [_C.gradA, _C.gradB]),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: _C.gradA.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: widget.worker.profilePhotoUrl.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    widget.worker.profilePhotoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _workerInitial(),
                  ),
                )
              : _workerInitial(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.worker.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _C.txt1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.verified_rounded, color: _C.gradA, size: 15),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                widget.worker.category,
                style: const TextStyle(fontSize: 12, color: _C.txt2),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: _C.star, size: 14),
                  const SizedBox(width: 3),
                  Text(
                    widget.worker.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _C.txt1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.location_on_outlined,
                    size: 13,
                    color: _C.txt2,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    widget.worker.distanceKm < 1
                        ? '${(widget.worker.distanceKm * 1000).toStringAsFixed(0)} m away'
                        : '${widget.worker.distanceKm.toStringAsFixed(1)} km away',
                    style: const TextStyle(fontSize: 12, color: _C.txt2),
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Available',
                style: TextStyle(
                  fontSize: 10,
                  color: _C.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            if (widget.worker.travelFee == 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Free Travel',
                  style: TextStyle(
                    fontSize: 9,
                    color: _C.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Text(
                'LKR ${widget.worker.travelFee.toStringAsFixed(0)} travel',
                style: const TextStyle(fontSize: 10, color: _C.txt2),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _workerInitial() => Center(
    child: Text(
      widget.worker.name.isNotEmpty ? widget.worker.name[0].toUpperCase() : 'W',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _sectionLabel(String label, {bool required = false}) => Row(
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _C.txt1,
        ),
      ),
      if (required)
        const Text(
          ' *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _C.red,
          ),
        ),
    ],
  );

  Widget _textArea(TextEditingController ctrl, {required String hint}) =>
      Container(
        decoration: BoxDecoration(
          color: _C.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: ctrl,
          maxLines: 5,
          style: const TextStyle(fontSize: 14, color: _C.txt1, height: 1.55),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _C.txt2.withOpacity(0.6), fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      );

  Widget _textField(
    TextEditingController ctrl, {
    required String hint,
    required IconData icon,
  }) => Container(
    decoration: BoxDecoration(
      color: _C.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _C.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: TextField(
      controller: ctrl,
      style: const TextStyle(fontSize: 14, color: _C.txt1),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _C.txt2.withOpacity(0.6), fontSize: 14),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        prefixIcon: Icon(icon, size: 18, color: _C.gradA),
      ),
    ),
  );

  Widget _addressField() => Container(
    decoration: BoxDecoration(
      color: _C.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _C.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: TextField(
      controller: _addressCtrl,
      style: const TextStyle(fontSize: 14, color: _C.txt1),
      decoration: InputDecoration(
        hintText: 'Fetching your location…',
        hintStyle: TextStyle(color: _C.txt2.withOpacity(0.6), fontSize: 14),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: _locationLoading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _C.gradA,
                  ),
                ),
              )
            : IconButton(
                onPressed: _fetchLocation,
                icon: const Icon(
                  Icons.my_location_rounded,
                  color: _C.gradA,
                  size: 22,
                ),
              ),
      ),
    ),
  );

  Widget _mapCard() => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          SizedBox(
            height: 210,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _location,
                zoom: 14,
              ),
              onMapCreated: (c) => _mapCtrl = c,
              onTap: _onMapTap,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              markers: {
                Marker(
                  markerId: const MarkerId('selected'),
                  position: _location,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                ),
              },
            ),
          ),
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app_rounded, size: 13, color: _C.txt2),
                    SizedBox(width: 5),
                    Text(
                      'Tap map to adjust location',
                      style: TextStyle(
                        fontSize: 11,
                        color: _C.txt2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
