import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../models/user_address.dart';
import '../../../../widgets/gradient_button.dart';

class CustomerNewAddressScreen extends StatefulWidget {
  const CustomerNewAddressScreen({super.key});

  @override
  State<CustomerNewAddressScreen> createState() =>
      _CustomerNewAddressScreenState();
}

class _CustomerNewAddressScreenState extends State<CustomerNewAddressScreen>
    with TickerProviderStateMixin {
  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _provinceController = TextEditingController();
  final _labelController = TextEditingController(text: 'Home');

  final _line1Focus = FocusNode();
  final _line2Focus = FocusNode();
  final _cityFocus = FocusNode();
  final _postalFocus = FocusNode();
  final _provinceFocus = FocusNode();
  final _labelFocus = FocusNode();

  final Completer<GoogleMapController> _mapController = Completer();

  LatLng _selectedLatLng = const LatLng(6.9271, 79.8612);
  bool _isLoadingLocation = false;
  bool _isDefault = false;
  bool _mapInteractionEnabled = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  final List<String> _labelPresets = ['Home', 'Work', 'Other'];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _provinceController.dispose();
    _labelController.dispose();
    _line1Focus.dispose();
    _line2Focus.dispose();
    _cityFocus.dispose();
    _postalFocus.dispose();
    _provinceFocus.dispose();
    _labelFocus.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        _showErrorSnack('Location permission denied');
        setState(() => _isLoadingLocation = false);
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      final newLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLatLng = newLatLng;
        _isLoadingLocation = false;
      });
      final controller = await _mapController.future;
      await controller.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 16));
    } catch (_) {
      setState(() => _isLoadingLocation = false);
      if (!mounted) return;
      _showErrorSnack('Failed to get current location');
    }
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _save() {
    if (_line1Controller.text.trim().isEmpty) {
      _showErrorSnack('Please enter at least Address Line 1');
      return;
    }
    final address = UserAddress(
      id: '',
      label: _labelController.text.trim().isEmpty
          ? 'Home'
          : _labelController.text.trim(),
      line1: _line1Controller.text.trim(),
      line2: _line2Controller.text.trim(),
      city: _cityController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      province: _provinceController.text.trim(),
      isDefault: _isDefault,
      location: GeoPoint(_selectedLatLng.latitude, _selectedLatLng.longitude),
    );
    Navigator.pop(context, address);
  }

  @override
  Widget build(BuildContext context) {
    final marker = Marker(
      markerId: const MarkerId('selected_location'),
      position: _selectedLatLng,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF4B7DF3),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'New Address',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F6FB),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel(label: 'PIN LOCATION'),
                        const SizedBox(height: 10),
                        _MapCard(
                          selectedLatLng: _selectedLatLng,
                          mapInteractionEnabled: _mapInteractionEnabled,
                          isLoadingLocation: _isLoadingLocation,
                          mapController: _mapController,
                          marker: marker,
                          onMapTap: (latLng) =>
                              setState(() => _selectedLatLng = latLng),
                          onToggleInteraction: () => setState(
                            () => _mapInteractionEnabled =
                                !_mapInteractionEnabled,
                          ),
                          onUseMyLocation: _useCurrentLocation,
                        ),
                        const SizedBox(height: 6),
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text(
                            'Tap anywhere on the map to move the pin',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF9AA3B4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        const _SectionLabel(label: 'ADDRESS DETAILS'),
                        const SizedBox(height: 12),
                        _AddressFormCard(
                          children: [
                            _ProField(
                              controller: _line1Controller,
                              focusNode: _line1Focus,
                              nextFocus: _line2Focus,
                              label: 'Address Line 1',
                              hint: 'Street number and name',
                              icon: Icons.home_outlined,
                            ),
                            const _FieldDivider(),
                            _ProField(
                              controller: _line2Controller,
                              focusNode: _line2Focus,
                              nextFocus: _cityFocus,
                              label: 'Address Line 2',
                              hint: 'Apartment, floor (optional)',
                              icon: Icons.apartment_outlined,
                            ),
                            const _FieldDivider(),
                            Row(
                              children: [
                                Expanded(
                                  child: _ProField(
                                    controller: _cityController,
                                    focusNode: _cityFocus,
                                    nextFocus: _postalFocus,
                                    label: 'City',
                                    hint: 'City',
                                    icon: Icons.location_city_outlined,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 52,
                                  color: const Color(0xFFF0F2F8),
                                ),
                                Expanded(
                                  child: _ProField(
                                    controller: _postalCodeController,
                                    focusNode: _postalFocus,
                                    nextFocus: _provinceFocus,
                                    label: 'Postal Code',
                                    hint: '00000',
                                    icon: Icons.markunread_mailbox_outlined,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const _FieldDivider(),
                            _ProField(
                              controller: _provinceController,
                              focusNode: _provinceFocus,
                              label: 'Province',
                              hint: 'Province / State',
                              icon: Icons.map_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),

                        const _SectionLabel(label: 'LABEL'),
                        const SizedBox(height: 12),
                        _LabelPresets(
                          presets: _labelPresets,
                          labelController: _labelController,
                          onSelect: (p) =>
                              setState(() => _labelController.text = p),
                        ),
                        const SizedBox(height: 10),
                        _AddressFormCard(
                          children: [
                            _ProField(
                              controller: _labelController,
                              focusNode: _labelFocus,
                              label: 'Custom Label',
                              hint: 'e.g. Mom\'s house, Gym...',
                              icon: Icons.label_outline_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _DefaultToggle(
                          isDefault: _isDefault,
                          onTap: () => setState(() => _isDefault = !_isDefault),
                        ),
                        const SizedBox(height: 28),

                        GradientButton(
                          text: 'Save Address',
                          onPressed: _save,
                          isLoading: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  final LatLng selectedLatLng;
  final bool mapInteractionEnabled;
  final bool isLoadingLocation;
  final Completer<GoogleMapController> mapController;
  final Marker marker;
  final void Function(LatLng) onMapTap;
  final VoidCallback onToggleInteraction;
  final VoidCallback onUseMyLocation;

  const _MapCard({
    required this.selectedLatLng,
    required this.mapInteractionEnabled,
    required this.isLoadingLocation,
    required this.mapController,
    required this.marker,
    required this.onMapTap,
    required this.onToggleInteraction,
    required this.onUseMyLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: selectedLatLng,
                  zoom: 14,
                ),
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: (controller) {
                  if (!mapController.isCompleted) {
                    mapController.complete(controller);
                  }
                },
                markers: {marker},
                onTap: mapInteractionEnabled ? onMapTap : null,
                gestureRecognizers: mapInteractionEnabled
                    ? {
                        Factory<OneSequenceGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                        ),
                      }
                    : {},
              ),

              if (!mapInteractionEnabled)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: onToggleInteraction,
                    child: Container(
                      color: Colors.black.withOpacity(0.18),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.touch_app_rounded,
                                size: 18,
                                color: Color(0xFF4B7DF3),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Tap to interact with map',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1F2E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              Positioned(
                right: 12,
                top: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: onToggleInteraction,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: mapInteractionEnabled
                              ? const Color(0xFF4B7DF3)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              mapInteractionEnabled
                                  ? Icons.check_rounded
                                  : Icons.edit_location_alt_outlined,
                              size: 15,
                              color: mapInteractionEnabled
                                  ? Colors.white
                                  : const Color(0xFF4B7DF3),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              mapInteractionEnabled ? 'Done' : 'Edit pin',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: mapInteractionEnabled
                                    ? Colors.white
                                    : const Color(0xFF1A1F2E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: isLoadingLocation ? null : onUseMyLocation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            isLoadingLocation
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF4B7DF3),
                                    ),
                                  )
                                : const Icon(
                                    Icons.my_location_rounded,
                                    size: 15,
                                    color: Color(0xFF4B7DF3),
                                  ),
                            const SizedBox(width: 6),
                            Text(
                              isLoadingLocation ? 'Locating...' : 'My location',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1F2E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${selectedLatLng.latitude.toStringAsFixed(4)}, ${selectedLatLng.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabelPresets extends StatelessWidget {
  final List<String> presets;
  final TextEditingController labelController;
  final void Function(String) onSelect;

  const _LabelPresets({
    required this.presets,
    required this.labelController,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: presets.map((preset) {
          final isActive = labelController.text == preset;
          return GestureDetector(
            onTap: () => onSelect(preset),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF4B7DF3) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF4B7DF3)
                      : const Color(0xFFE2E6F0),
                  width: 1.5,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFF4B7DF3).withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                preset,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : const Color(0xFF555555),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DefaultToggle extends StatelessWidget {
  final bool isDefault;
  final VoidCallback onTap;

  const _DefaultToggle({required this.isDefault, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDefault ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDefault
                ? const Color(0xFF4B7DF3)
                : const Color(0xFFEAECEF),
            width: isDefault ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDefault
                    ? const Color(0xFF4B7DF3)
                    : const Color(0xFFF4F6FB),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.home_rounded,
                size: 19,
                color: isDefault ? Colors.white : const Color(0xFF9AA3B4),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set as default address',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDefault
                          ? const Color(0xFF4B7DF3)
                          : const Color(0xFF1A1F2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Used automatically on the home screen',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9AA3B4)),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDefault ? const Color(0xFF4B7DF3) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDefault
                      ? const Color(0xFF4B7DF3)
                      : const Color(0xFFCBD0DC),
                  width: 2,
                ),
              ),
              child: isDefault
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF9AA3B4),
        letterSpacing: 1.4,
      ),
    );
  }
}

class _AddressFormCard extends StatelessWidget {
  final List<Widget> children;
  const _AddressFormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _FieldDivider extends StatelessWidget {
  const _FieldDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Color(0xFFF0F2F8),
    );
  }
}

class _ProField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;

  const _ProField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    this.nextFocus,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_ProField> createState() => _ProFieldState();
}

class _ProFieldState extends State<_ProField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.icon,
                size: 13,
                color: _focused
                    ? const Color(0xFF4B7DF3)
                    : const Color(0xFFADB5C7),
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: _focused
                      ? const Color(0xFF4B7DF3)
                      : const Color(0xFF9AA3B4),
                ),
              ),
            ],
          ),
          TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: widget.keyboardType,
            textInputAction: widget.nextFocus != null
                ? TextInputAction.next
                : TextInputAction.done,
            onSubmitted: (_) {
              if (widget.nextFocus != null) {
                FocusScope.of(context).requestFocus(widget.nextFocus);
              }
            },
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1F2E),
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(
                color: Color(0xFFCBD0DC),
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.only(top: 6, bottom: 10),
            ),
          ),
        ],
      ),
    );
  }
}
