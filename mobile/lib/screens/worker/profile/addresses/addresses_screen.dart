import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../models/user_address.dart';
import '../../../../services/address_service.dart';
import '../../../../widgets/gradient_button.dart';
import 'edit_address_screen.dart';
import 'new_address_screen.dart';

class CustomerAddressesScreen extends StatefulWidget {
  final UserAddress? selectedAddress;

  const CustomerAddressesScreen({super.key, this.selectedAddress});

  @override
  State<CustomerAddressesScreen> createState() =>
      _CustomerAddressesScreenState();
}

class _CustomerAddressesScreenState extends State<CustomerAddressesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AddressService _addressService = AddressService();

  String _searchText = '';
  bool _isLoadingCurrentLocation = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserAddress> _filterAddresses(List<UserAddress> addresses) {
    if (_searchText.isEmpty) return addresses;
    return addresses.where((address) {
      return address.label.toLowerCase().contains(_searchText) ||
          address.fullAddress.toLowerCase().contains(_searchText);
    }).toList();
  }

  Future<void> _openNewAddress() async {
    final result = await Navigator.push<UserAddress>(
      context,
      MaterialPageRoute(builder: (_) => const CustomerNewAddressScreen()),
    );
    if (result != null) await _addressService.addAddress(result);
  }

  Future<void> _openEditAddress(UserAddress address) async {
    final result = await Navigator.push<UserAddress>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerEditAddressScreen(address: address),
      ),
    );
    if (result != null) await _addressService.updateAddress(result);
  }

  Future<void> _selectCurrentLocation() async {
    setState(() => _isLoadingCurrentLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _isLoadingCurrentLocation = false);
        _showErrorSnack('Location permission denied');
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      final currentLocationAddress = UserAddress(
        id: 'current_location',
        label: 'Current Location',
        line1: '',
        line2: '',
        city: '',
        postalCode: '',
        province: '',
        isDefault: false,
        location: GeoPoint(position.latitude, position.longitude),
        isCurrentLocation: true,
      );
      if (!mounted) return;
      Navigator.pop(context, currentLocationAddress);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCurrentLocation = false);
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

  void _selectAddress(UserAddress address) => Navigator.pop(context, address);

  bool _isSelected(UserAddress address) {
    if (address.isCurrentLocation) {
      return widget.selectedAddress?.isCurrentLocation == true;
    }
    return widget.selectedAddress?.id == address.id;
  }

  @override
  Widget build(BuildContext context) {
    final bool currentLocationSelected =
        widget.selectedAddress?.isCurrentLocation == true;

    return Scaffold(
      backgroundColor: const Color(0xFF4B7DF3),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────
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
                        'My Addresses',
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

            // ── Search bar ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.30),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search addresses...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                    if (_searchText.isNotEmpty)
                      GestureDetector(
                        onTap: () => _searchController.clear(),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Body card ───────────────────────────────
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F6FB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<UserAddress>>(
                        stream: _addressService.getAddresses(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF4B7DF3),
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }

                          final addresses = _filterAddresses(
                            snapshot.data ?? [],
                          );

                          return ListView(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                            children: [
                              const _SectionLabel(label: 'NEARBY'),
                              const SizedBox(height: 10),
                              _CurrentLocationTile(
                                selected: currentLocationSelected,
                                isLoading: _isLoadingCurrentLocation,
                                onTap: _selectCurrentLocation,
                              ),
                              const SizedBox(height: 22),
                              Row(
                                children: [
                                  const _SectionLabel(label: 'SAVED'),
                                  const Spacer(),
                                  Text(
                                    '${addresses.length} address${addresses.length == 1 ? '' : 'es'}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF9AA3B4),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (addresses.isEmpty)
                                const _EmptyAddresses()
                              else
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFEAECEF),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: addresses.asMap().entries.map((
                                      entry,
                                    ) {
                                      final isLast =
                                          entry.key == addresses.length - 1;
                                      return Column(
                                        children: [
                                          _AddressTile(
                                            address: entry.value,
                                            selected: _isSelected(entry.value),
                                            onTap: () =>
                                                _selectAddress(entry.value),
                                            onEditTap: () =>
                                                _openEditAddress(entry.value),
                                            onSetDefaultTap: () =>
                                                _addressService
                                                    .setDefaultAddress(
                                                      entry.value.id,
                                                    ),
                                          ),
                                          if (!isLast)
                                            const Divider(
                                              height: 1,
                                              indent: 56,
                                              endIndent: 16,
                                              color: Color(0xFFF0F2F8),
                                            ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),

                    // ── Add new address button ─────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: GradientButton(
                        text: 'Add New Address',
                        onPressed: _openNewAddress,
                        isLoading: false,
                      ),
                    ),
                  ],
                ),
              ),
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

class _CurrentLocationTile extends StatelessWidget {
  final bool selected;
  final bool isLoading;
  final VoidCallback onTap;

  const _CurrentLocationTile({
    required this.selected,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF4B7DF3) : const Color(0xFFEAECEF),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF4B7DF3)
                    : const Color(0xFFF0F4FF),
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF4B7DF3),
                      ),
                    )
                  : Icon(
                      Icons.my_location_rounded,
                      size: 20,
                      color: selected ? Colors.white : const Color(0xFF4B7DF3),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Location',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? const Color(0xFF4B7DF3)
                          : const Color(0xFF1A1F2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLoading
                        ? 'Fetching your location...'
                        : 'Use your live device location',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9AA3B4),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFF4B7DF3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final UserAddress address;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEditTap;
  final VoidCallback onSetDefaultTap;

  const _AddressTile({
    required this.address,
    required this.selected,
    required this.onTap,
    required this.onEditTap,
    required this.onSetDefaultTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0F4FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF4B7DF3)
                    : const Color(0xFFF4F6FB),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on_rounded,
                size: 19,
                color: selected ? Colors.white : const Color(0xFF9AA3B4),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          address.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? const Color(0xFF4B7DF3)
                                : const Color(0xFF1A1F2E),
                          ),
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4B7DF3),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    address.fullAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9AA3B4),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected)
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4B7DF3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: Color(0xFFBCC4D4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') onEditTap();
                    if (value == 'default') onSetDefaultTap();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 17,
                            color: Color(0xFF555555),
                          ),
                          SizedBox(width: 10),
                          Text('Edit address', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'default',
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 17,
                            color: Color(0xFF4B7DF3),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Set as default',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAddresses extends StatelessWidget {
  const _EmptyAddresses();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: const Column(
        children: [
          Icon(Icons.location_off_outlined, size: 36, color: Color(0xFFCBD0DC)),
          SizedBox(height: 10),
          Text(
            'No saved addresses yet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9AA3B4),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap the button below to add one',
            style: TextStyle(fontSize: 12, color: Color(0xFFBCC4D4)),
          ),
        ],
      ),
    );
  }
}
