import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../models/user_address.dart';

class WorkerNewAddressScreen extends StatefulWidget {
  const WorkerNewAddressScreen({super.key});

  @override
  State<WorkerNewAddressScreen> createState() => _WorkerNewAddressScreenState();
}

class _WorkerNewAddressScreenState extends State<WorkerNewAddressScreen> {
  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _provinceController = TextEditingController();
  final _labelController = TextEditingController(text: 'Home');

  final Completer<GoogleMapController> _mapController = Completer();

  LatLng _selectedLatLng = const LatLng(6.9271, 79.8612);
  bool _isLoadingLocation = false;
  bool _isDefault = false;

  @override
  void dispose() {
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _provinceController.dispose();
    _labelController.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get current location')),
      );
    }
  }

  void _save() {
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
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, size: 20),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'New Address',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _selectedLatLng,
                            zoom: 14,
                          ),
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          onMapCreated: (controller) {
                            if (!_mapController.isCompleted) {
                              _mapController.complete(controller);
                            }
                          },
                          markers: {marker},
                          onTap: (latLng) {
                            setState(() {
                              _selectedLatLng = latLng;
                            });
                          },
                        ),
                        Positioned(
                          right: 10,
                          top: 10,
                          child: ElevatedButton.icon(
                            onPressed: _isLoadingLocation
                                ? null
                                : _useCurrentLocation,
                            icon: const Icon(Icons.my_location, size: 16),
                            label: Text(
                              _isLoadingLocation
                                  ? 'Loading...'
                                  : 'Current location',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF222222),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Selected pin: ${_selectedLatLng.latitude.toStringAsFixed(6)}, ${_selectedLatLng.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 18),
                const _FieldLabel('Address'),
                const SizedBox(height: 8),
                _RoundedField(
                  controller: _line1Controller,
                  hintText: 'Address Line 1',
                ),
                const SizedBox(height: 10),
                _RoundedField(
                  controller: _line2Controller,
                  hintText: 'Address Line 2',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _RoundedField(
                        controller: _cityController,
                        hintText: 'City',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RoundedField(
                        controller: _postalCodeController,
                        hintText: 'Postal Code',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _RoundedField(
                  controller: _provinceController,
                  hintText: 'Province',
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFEAECEF)),
                const SizedBox(height: 10),
                const _FieldLabel('Label'),
                const SizedBox(height: 8),
                _RoundedField(controller: _labelController, hintText: 'Label'),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isDefault,
                  onChanged: (value) {
                    setState(() {
                      _isDefault = value ?? false;
                    });
                  },
                  title: const Text('Set as default address'),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4B7DF3),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    );
  }
}

class _RoundedField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const _RoundedField({required this.controller, required this.hintText});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE1E3EA)),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          isCollapsed: true,
        ),
      ),
    );
  }
}
