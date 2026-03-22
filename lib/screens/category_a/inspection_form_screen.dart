import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../models/worker.dart';
import 'customer_request_screen.dart';

class InspectionFormScreen extends StatefulWidget {
  final Worker worker;

  const InspectionFormScreen({super.key, required this.worker});

  @override
  State<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends State<InspectionFormScreen>
    with TickerProviderStateMixin {
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  LatLng _selectedLocation = const LatLng(7.0840, 80.0098);
  GoogleMapController? _mapController;

  List<File> _images = [];
  bool _loading = false;
  bool _locationLoading = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // ─── Color palette ────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF2563EB);
  static const Color _primaryLight = Color(0xFFEFF6FF);
  static const Color _accent = Color(0xFF0EA5E9);
  static const Color _surface = Color(0xFFF8FAFC);
  static const Color _cardBg = Colors.white;
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _starColor = Color(0xFFF59E0B);
  static const Color _verifiedColor = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();

    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _descController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // ─── Current Location ─────────────────────────────────────────────────────
  Future<void> _fetchCurrentLocation() async {
    setState(() => _locationLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack("Location services are disabled.", isError: true);
        setState(() => _locationLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack("Location permission denied.", isError: true);
          setState(() => _locationLoading = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack("Location permission permanently denied.", isError: true);
        setState(() => _locationLoading = false);
        return;
      }

      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final LatLng loc = LatLng(pos.latitude, pos.longitude);

      // Reverse geocode to human-readable address
      try {
        final List<Placemark> placemarks =
            await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [
            p.subLocality,
            p.locality,
            p.administrativeArea,
            p.country,
          ].where((s) => s != null && s.isNotEmpty).toList();
          _addressController.text = parts.join(', ');
        }
      } catch (_) {
        _addressController.text =
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      }

      setState(() {
        _selectedLocation = loc;
        _locationLoading = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(loc, 15),
      );
    } catch (e) {
      setState(() => _locationLoading = false);
      _showSnack("Could not get location: $e", isError: true);
    }
  }

  // ─── Image Picker ──────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _images.add(File(picked.path)));
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  // ─── Map Tap ───────────────────────────────────────────────────────────────
  void _onMapTap(LatLng position) async {
    setState(() => _selectedLocation = position);
    try {
      final List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.country,
        ].where((s) => s != null && s.isNotEmpty).toList();
        _addressController.text = parts.join(', ');
      }
    } catch (_) {}
  }

  // ─── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submitRequest() async {
    if (_descController.text.isEmpty || _images.isEmpty) {
      _showSnack("Please fill all fields and add at least one image.",
          isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final docRef =
          await FirebaseFirestore.instance.collection('requests').add({
        'workerId': widget.worker.id,
        'workerName': widget.worker.name,
        'category': widget.worker.category,
        'description': _descController.text,
        'address': _addressController.text,
        'imageUrls': [],
        'latitude': _selectedLocation.latitude,
        'longitude': _selectedLocation.longitude,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

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
      setState(() => _loading = false);
      _showSnack("Error: $e", isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFEF4444) : _primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWorkerCard(),
                const SizedBox(height: 20),
                _buildSectionLabel("Address", required: true),
                const SizedBox(height: 8),
                _buildAddressField(),
                const SizedBox(height: 14),
                _buildMapCard(),
                const SizedBox(height: 20),
                _buildSectionLabel("Description", required: true),
                const SizedBox(height: 8),
                _buildDescriptionField(),
                const SizedBox(height: 20),
                _buildSectionLabel("Upload Images", required: true),
                const SizedBox(height: 10),
                _buildImageGrid(),
                const SizedBox(height: 30),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "Request Inspection",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
          onPressed: _fetchCurrentLocation,
          tooltip: "Refresh location",
        ),
      ],
    );
  }

  // ─── Worker Card ───────────────────────────────────────────────────────────
  Widget _buildWorkerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with gradient background
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _primary.withOpacity(0.15),
                  _accent.withOpacity(0.12)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: _border, width: 2),
            ),
            child:
                const Icon(Icons.person_rounded, color: _primary, size: 28),
          ),
          const SizedBox(width: 14),

          // Worker Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.worker.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded,
                        color: _verifiedColor, size: 16),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.worker.category,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: _starColor, size: 15),
                    const SizedBox(width: 3),
                    const Text(
                      "4.5",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.location_on_outlined,
                        color: _textSecondary, size: 13),
                    const SizedBox(width: 2),
                    const Expanded(
                      child: Text(
                        "Gampaha, Western",
                        style: TextStyle(fontSize: 12, color: _textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Available badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Available",
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF16A34A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Label ─────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label, {bool required = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
            letterSpacing: 0.1,
          ),
        ),
        if (required)
          const Text(
            " *",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFFEF4444),
            ),
          ),
      ],
    );
  }

  // ─── Address Field ─────────────────────────────────────────────────────────
  Widget _buildAddressField() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _addressController,
        style: const TextStyle(
          fontSize: 14,
          color: _textPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: "Fetching your location...",
          hintStyle:
              TextStyle(color: _textSecondary.withOpacity(0.6), fontSize: 14),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          suffixIcon: _locationLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _primary),
                  ),
                )
              : IconButton(
                  onPressed: _fetchCurrentLocation,
                  icon: const Icon(Icons.my_location_rounded,
                      color: _primary, size: 22),
                  tooltip: "Use current location",
                ),
        ),
      ),
    );
  }

  // ─── Map Card ──────────────────────────────────────────────────────────────
  Widget _buildMapCard() {
    return Container(
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
                  target: _selectedLocation,
                  zoom: 14,
                ),
                onMapCreated: (c) => _mapController = c,
                onTap: _onMapTap,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                markers: {
                  Marker(
                    markerId: const MarkerId("selected"),
                    position: _selectedLocation,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure),
                  ),
                },
              ),
            ),

            // Top hint pill
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded,
                          size: 13, color: _textSecondary),
                      SizedBox(width: 5),
                      Text(
                        "Tap map to adjust location",
                        style: TextStyle(
                          fontSize: 11,
                          color: _textSecondary,
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

  // ─── Description Field ─────────────────────────────────────────────────────
  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _descController,
        maxLines: 5,
        style: const TextStyle(
            fontSize: 14, color: _textPrimary, height: 1.55),
        decoration: InputDecoration(
          hintText: "Describe the issue in detail...",
          hintStyle: TextStyle(
              color: _textSecondary.withOpacity(0.6), fontSize: 14),
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ─── Image Grid ────────────────────────────────────────────────────────────
  Widget _buildImageGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ..._images.asMap().entries.map((entry) =>
            _buildImageTile(img: entry.value, index: entry.key)),
        _buildAddPhotoTile(),
      ],
    );
  }

  Widget _buildImageTile({required File img, required int index}) {
    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(img, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEF4444),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40EF4444),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.close_rounded,
                  size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoTile() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: _primaryLight,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: _primary.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded,
                color: _primary.withOpacity(0.8), size: 26),
            const SizedBox(height: 4),
            Text(
              "Add Photo",
              style: TextStyle(
                fontSize: 10,
                color: _primary.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Submit Button ─────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _accent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.38),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _loading ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Request Inspection",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
