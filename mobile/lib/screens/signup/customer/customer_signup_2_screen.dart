import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:skillfox/core/utils/screen_helpers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/app_text_field.dart';
import 'customer_signup_3_screen.dart';

class CustomerSignup2Screen extends StatefulWidget {
  final String name, phone;
  const CustomerSignup2Screen({super.key, required this.name, required this.phone});
  @override
  State<CustomerSignup2Screen> createState() => _CustomerSignup2ScreenState();
}

class _CustomerSignup2ScreenState extends State<CustomerSignup2Screen> {
  final _addr1Ctrl  = TextEditingController();
  final _addr2Ctrl  = TextEditingController();
  final _cityCtrl   = TextEditingController();
  final _postalCtrl = TextEditingController();

  LatLng? _selectedLocation;
  bool _locationPermissionGranted = false;
  bool _validated = false;
  String? _selectedProvince;

  bool _addr1Error   = false;
  bool _addr2Error   = false;
  bool _cityError    = false;
  bool _postalError  = false;
  bool _provinceError = false;

  GoogleMapController? _mapController;

  static const _defaultLocation = LatLng(6.9271, 79.8612);

  static const List<String> _provinces = [
    'Western Province',
    'Central Province',
    'Southern Province',
    'Northern Province',
    'Eastern Province',
    'North Western Province',
    'North Central Province',
    'Uva Province',
    'Sabaragamuwa Province',
  ];

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _addr1Ctrl.addListener(()  { if (_addr1Error  && _addr1Ctrl.text.isNotEmpty)  setState(() => _addr1Error  = false); });
    _addr2Ctrl.addListener(()  { if (_addr2Error  && _addr2Ctrl.text.isNotEmpty)  setState(() => _addr2Error  = false); });
    _cityCtrl.addListener(()   { if (_cityError   && _cityCtrl.text.isNotEmpty)   setState(() => _cityError   = false); });
    _postalCtrl.addListener(() { if (_postalError && _postalCtrl.text.isNotEmpty) setState(() => _postalError = false); });
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (mounted) setState(() => _locationPermissionGranted = status.isGranted);
  }

  Future<void> _goToMyLocation(GoogleMapController? controller) async {
    if (!_locationPermissionGranted) return;
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      controller?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 16));
    } catch (_) {}
  }

  @override
  void dispose() {
    _addr1Ctrl.dispose(); _addr2Ctrl.dispose();
    _cityCtrl.dispose();  _postalCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onNext() {
    final a1 = _addr1Ctrl.text.trim().isEmpty;
    final a2 = _addr2Ctrl.text.trim().isEmpty;
    final ci = _cityCtrl.text.trim().isEmpty;
    final po = _postalCtrl.text.trim().isEmpty;
    final pr = _selectedProvince == null;
    final mp = _selectedLocation == null;

    if (a1 || a2 || ci || po || pr || mp) {
      setState(() {
        _validated     = true;
        _addr1Error    = a1;
        _addr2Error    = a2;
        _cityError     = ci;
        _postalError   = po;
        _provinceError = pr;
      });
      return;
    }

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CustomerSignup3Screen(
        name: widget.name,
        phone: widget.phone,
        address:
          '${_addr1Ctrl.text.trim()}, ${_addr2Ctrl.text.trim()}, '
          '${_cityCtrl.text.trim()}, ${_postalCtrl.text.trim()}, '
          '$_selectedProvince',
        lat: _selectedLocation!.latitude,
        lng: _selectedLocation!.longitude,
      ),
    ));
  }

  void _openFullScreenMap() {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FullScreenMapPage(
        initialLocation: _selectedLocation,
        locationPermissionGranted: _locationPermissionGranted,
        onLocationPicked: (loc) {
          setState(() {
            _selectedLocation = loc;
            if (_validated) _validated = false;
          });
          _mapController?.animateCamera(CameraUpdate.newLatLng(loc));
        },
      ),
    ));
  }

  Widget _errorLabel() => Padding(
    padding: const EdgeInsets.only(top: 5, left: 4),
    child: Row(
      children: [
        const Text('* ', style: TextStyle(
          color: Color(0xFFE53935), fontSize: 14, fontWeight: FontWeight.bold)),
        Text('Required', style: GoogleFonts.poppins(
          fontSize: 11, color: const Color(0xFFE53935))),
      ],
    ),
  );

  Widget _mapBtn({required IconData icon, required VoidCallback onTap}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.15), blurRadius: 6,
            offset: const Offset(0, 2))],
        ),
        child: Icon(icon, size: 22, color: Colors.black87),
      ),
    );

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const double whiteLayerHeight = 160.0; // <-- change this value
    final bool mapError = _validated && _selectedLocation == null;

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                        topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 45, right: 45, top: 28,
                        bottom: bottomPadding + whiteLayerHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Set your home location',
                            style: GoogleFonts.poppins(fontSize: 22,
                              fontWeight: FontWeight.w700, color: AppColors.primary)),
                          const SizedBox(height: 16),
                          Text('Enter your address',
                            style: GoogleFonts.poppins(fontSize: 13,
                              fontWeight: FontWeight.w500, color: AppColors.neutral1)),
                          const SizedBox(height: 10),

                          // Address Line 1
                          AppTextField(
                            placeholder: 'Address Line 1',
                            controller: _addr1Ctrl,
                            validator: (v) => (v == null || v.trim().isEmpty) ? '' : null,
                          ),
                          if (_addr1Error) _errorLabel(),
                          const SizedBox(height: 10),

                          // Address Line 2
                          AppTextField(
                            placeholder: 'Address Line 2',
                            controller: _addr2Ctrl,
                            validator: (v) => (v == null || v.trim().isEmpty) ? '' : null,
                          ),
                          if (_addr2Error) _errorLabel(),
                          const SizedBox(height: 10),

                          // City + Postal Code
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppTextField(
                                      placeholder: 'City',
                                      controller: _cityCtrl,
                                      validator: (v) => (v == null || v.trim().isEmpty) ? '' : null,
                                    ),
                                    if (_cityError) _errorLabel(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppTextField(
                                      placeholder: 'Postal Code',
                                      controller: _postalCtrl,
                                      keyboardType: TextInputType.number,
                                      validator: (v) => (v == null || v.trim().isEmpty) ? '' : null,
                                    ),
                                    if (_postalError) _errorLabel(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Province dropdown
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _provinceError ? const Color(0xFFE53935) : AppColors.borderColor,
                                width: _provinceError ? 1.5 : 1.0),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedProvince,
                                isExpanded: true,
                                hint: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('Province',
                                    style: GoogleFonts.poppins(fontSize: 13,
                                      color: _provinceError
                                          ? const Color(0xFFE53935)
                                          : AppColors.neutral4)),
                                ),
                                icon: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Icon(Icons.keyboard_arrow_down_rounded,
                                    color: _provinceError
                                        ? const Color(0xFFE53935)
                                        : AppColors.neutral4),
                                ),
                                borderRadius: BorderRadius.circular(12),
                                items: _provinces.map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(p, style: GoogleFonts.poppins(
                                      fontSize: 13, color: AppColors.neutral1)),
                                  ),
                                )).toList(),
                                onChanged: (v) => setState(() {
                                  _selectedProvince = v;
                                  _provinceError = false;
                                }),
                              ),
                            ),
                          ),
                          if (_provinceError) _errorLabel(),
                          const SizedBox(height: 18),

                          // Map label — title never changes color
                          Row(
                            children: [
                              Text('Set your home on map',
                                style: GoogleFonts.poppins(fontSize: 13,
                                  fontWeight: FontWeight.w500, color: AppColors.neutral1)),
                              if (mapError) ...[
                                const SizedBox(width: 5),
                                const Text('*', style: TextStyle(
                                  color: Color(0xFFE53935), fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                                const SizedBox(width: 6),
                                Text('Required', style: GoogleFonts.poppins(
                                  fontSize: 11, color: const Color(0xFFE53935))),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Tap on the map to pin your location',
                            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.neutral4)),
                          const SizedBox(height: 10),

                          // Mini map
                          Stack(
                            children: [
                              Container(
                                decoration: mapError ? BoxDecoration(
                                  border: Border.all(color: const Color(0xFFE53935), width: 1.5),
                                  borderRadius: BorderRadius.circular(15)) : null,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(mapError ? 14 : 15),
                                  child: SizedBox(
                                    height: 200,
                                    child: GoogleMap(
                                      initialCameraPosition: const CameraPosition(
                                        target: _defaultLocation, zoom: 12),
                                      myLocationEnabled: _locationPermissionGranted,
                                      myLocationButtonEnabled: false,
                                      zoomControlsEnabled: false,
                                      onMapCreated: (c) => _mapController = c,
                                      markers: _selectedLocation == null ? {} : {
                                        Marker(
                                          markerId: const MarkerId('home'),
                                          position: _selectedLocation!,
                                          infoWindow: const InfoWindow(title: 'Your home'),
                                        ),
                                      },
                                      onTap: (pos) => setState(() {
                                        _selectedLocation = pos;
                                        if (_validated) _validated = false;
                                      }),
                                    ),
                                  ),
                                ),
                              ),
                              // Buttons: top-left
                              Positioned(
                                top: 10, left: 10,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_locationPermissionGranted) ...[
                                      _mapBtn(
                                        icon: Icons.my_location_rounded,
                                        onTap: () => _goToMyLocation(_mapController),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    _mapBtn(
                                      icon: Icons.fullscreen_rounded,
                                      onTap: _openFullScreenMap,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          if (_selectedLocation != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_selectedLocation!.latitude.toStringAsFixed(5)}, '
                                    '${_selectedLocation!.longitude.toStringAsFixed(5)}',
                                    style: GoogleFonts.poppins(fontSize: 11, color: AppColors.primary)),
                                ],
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

          // White layer
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: bottomPadding + whiteLayerHeight,
            child: Column(
              children: [
                Container(
                  height: 30, // <-- change this value
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [Colors.white, Colors.white.withOpacity(0.0)])),
                ),
                Expanded(child: Container(color: Colors.white)),
              ],
            ),
          ),

          // bottom-line.png
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Image.asset('assets/images/bottom-line.png', fit: BoxFit.fitWidth),
          ),

          // Arrow button + sign-in link
          Positioned(
            bottom: bottomPadding + 100, left: 28, right: 28,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _onNext,
                    child: Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        gradient: AppColors.mainGradient,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 30),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ScreenHelpers.signInLink(context),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Full-screen map page ──────────────────────────────────────────────────────
class _FullScreenMapPage extends StatefulWidget {
  final LatLng? initialLocation;
  final bool locationPermissionGranted;
  final ValueChanged<LatLng> onLocationPicked;

  const _FullScreenMapPage({
    required this.initialLocation,
    required this.locationPermissionGranted,
    required this.onLocationPicked,
  });

  @override
  State<_FullScreenMapPage> createState() => _FullScreenMapPageState();
}

class _FullScreenMapPageState extends State<_FullScreenMapPage> {
  LatLng? _pinned;
  GoogleMapController? _ctrl;

  @override
  void initState() {
    super.initState();
    _pinned = widget.initialLocation;
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  Future<void> _goToMyLocation() async {
    if (!widget.locationPermissionGranted) return;
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _ctrl?.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(pos.latitude, pos.longitude), 16));
    } catch (_) {}
  }

  Widget _mapBtn({required IconData icon, required VoidCallback onTap}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.15), blurRadius: 6,
            offset: const Offset(0, 2))],
        ),
        child: Icon(icon, size: 22, color: Colors.black87),
      ),
    );

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pinned ?? const LatLng(6.9271, 79.8612),
              zoom: _pinned != null ? 15 : 12,
            ),
            myLocationEnabled: widget.locationPermissionGranted,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (c) => _ctrl = c,
            markers: _pinned == null ? {} : {
              Marker(
                markerId: const MarkerId('home'),
                position: _pinned!,
                infoWindow: const InfoWindow(title: 'Your home'),
              ),
            },
            onTap: (pos) => setState(() => _pinned = pos),
          ),

          // Top navbar
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.mainGradient),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          if (_pinned != null) widget.onLocationPicked(_pinned!);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Pin your home',
                        style: GoogleFonts.poppins(fontSize: 17,
                          fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Right-side controls: zoom in, zoom out, my location
          Positioned(
            right: 12,
            bottom: bottomPadding + 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _mapBtn(icon: Icons.add_rounded,
                  onTap: () => _ctrl?.animateCamera(CameraUpdate.zoomIn())),
                const SizedBox(height: 8),
                _mapBtn(icon: Icons.remove_rounded,
                  onTap: () => _ctrl?.animateCamera(CameraUpdate.zoomOut())),
                if (widget.locationPermissionGranted) ...[
                  const SizedBox(height: 8),
                  _mapBtn(icon: Icons.my_location_rounded, onTap: _goToMyLocation),
                ],
              ],
            ),
          ),

          // Bottom hint bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 14,
                bottom: bottomPadding + 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
                  blurRadius: 12, offset: const Offset(0, -4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_pinned != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${_pinned!.latitude.toStringAsFixed(5)}, '
                            '${_pinned!.longitude.toStringAsFixed(5)}',
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  Text('Tap anywhere on the map to pin your home',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.neutral4),
                    textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}