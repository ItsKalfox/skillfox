import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:skillfox/core/utils/screen_helpers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../widgets/app_text_field.dart';
import 'worker_signup_5_screen.dart';

class WorkerSignup4Screen extends StatefulWidget {
  final String name, phone, nationalId, jobType, nicFrontUrl, nicBackUrl, profilePhotoUrl;
  final List<String> certificationUrls;
  const WorkerSignup4Screen({super.key, required this.name, required this.phone,
    required this.nationalId, required this.jobType, required this.nicFrontUrl,
    required this.nicBackUrl, required this.profilePhotoUrl, required this.certificationUrls});
  @override
  State<WorkerSignup4Screen> createState() => _WorkerSignup4ScreenState();
}

class _WorkerSignup4ScreenState extends State<WorkerSignup4Screen> {
  final _addr1Ctrl = TextEditingController();
  final _addr2Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  LatLng? _selectedLocation;
  bool _locationPermissionGranted = false; // ✅ added
  static const _defaultLocation = LatLng(6.9271, 79.8612);

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (mounted) {
      setState(() {
        _locationPermissionGranted = status.isGranted; // ✅ fixed
      });
    }
  }

  @override
  void dispose() {
    _addr1Ctrl.dispose();
    _addr2Ctrl.dispose();
    _cityCtrl.dispose();
    _postalCtrl.dispose();
    _provinceCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onNext() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pin your location on the map')),
      );
      return;
    }
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => WorkerSignup5Screen(
        name: widget.name,
        phone: widget.phone,
        nationalId: widget.nationalId,
        jobType: widget.jobType,
        nicFrontUrl: widget.nicFrontUrl,
        nicBackUrl: widget.nicBackUrl,
        profilePhotoUrl: widget.profilePhotoUrl,
        certificationUrls: widget.certificationUrls,
        address:
          '${_addr1Ctrl.text.trim()}, ${_addr2Ctrl.text.trim()}, '
          '${_cityCtrl.text.trim()}, ${_postalCtrl.text.trim()}, '
          '${_provinceCtrl.text.trim()}',
        lat: _selectedLocation!.latitude,
        lng: _selectedLocation!.longitude,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppColors.mainGradient)),
          SafeArea(
            child: Column(
              children: [
                ScreenHelpers.navBar(context, 'Sign up'),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30), topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Set your work location',
                              style: GoogleFonts.poppins(
                                fontSize: 22, fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text('Enter your address',
                              style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w500,
                                color: AppColors.neutral1,
                              ),
                            ),
                            const SizedBox(height: 10),
                            AppTextField(
                              placeholder: 'Address Line 1',
                              controller: _addr1Ctrl,
                              validator: (v) => Validators.required(v, 'Address Line 1'),
                            ),
                            const SizedBox(height: 10),
                            AppTextField(
                              placeholder: 'Address Line 2',
                              controller: _addr2Ctrl,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    placeholder: 'City',
                                    controller: _cityCtrl,
                                    validator: (v) => Validators.required(v, 'City'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: AppTextField(
                                    placeholder: 'Postal Code',
                                    controller: _postalCtrl,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            AppTextField(
                              placeholder: 'Province',
                              controller: _provinceCtrl,
                            ),
                            const SizedBox(height: 18),
                            Text('Set your workplace on map',
                              style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w500,
                                color: AppColors.neutral1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Tap on the map to pin your location',
                              style: GoogleFonts.poppins(
                                fontSize: 11, color: AppColors.neutral4,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: SizedBox(
                                height: 200,
                                child: GoogleMap(
                                  initialCameraPosition: const CameraPosition(
                                    target: _defaultLocation, zoom: 12,
                                  ),
                                  // ✅ dynamic based on permission
                                  myLocationEnabled: _locationPermissionGranted,
                                  myLocationButtonEnabled: _locationPermissionGranted,
                                  zoomControlsEnabled: false,
                                  markers: _selectedLocation == null ? {} : {
                                    Marker(
                                      markerId: const MarkerId('work'),
                                      position: _selectedLocation!,
                                      infoWindow: const InfoWindow(title: 'Your workplace'),
                                    ),
                                  },
                                  onTap: (pos) => setState(() => _selectedLocation = pos),
                                ),
                              ),
                            ),
                            // ✅ show pinned coordinates
                            if (_selectedLocation != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                      size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_selectedLocation!.latitude.toStringAsFixed(5)}, '
                                      '${_selectedLocation!.longitude.toStringAsFixed(5)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11, color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 10),
                            // Search bar
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: AppColors.borderColor),
                              ),
                              child: Row(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Icon(Icons.search, color: AppColors.neutral4),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchCtrl,
                                      decoration: InputDecoration(
                                        hintText: 'Search location...',
                                        hintStyle: GoogleFonts.poppins(
                                          fontSize: 13, color: AppColors.neutral4),
                                        border: InputBorder.none,
                                        contentPadding:
                                          const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18,
                                      color: AppColors.neutral4),
                                    onPressed: () => _searchCtrl.clear(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ScreenHelpers.signInLink(context),
                                GestureDetector(
                                  onTap: _onNext, // ✅ extracted to clean method
                                  child: Container(
                                    width: 56, height: 56,
                                    decoration: const BoxDecoration(
                                      gradient: AppColors.mainGradient,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.arrow_forward,
                                      color: Colors.white, size: 24),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
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