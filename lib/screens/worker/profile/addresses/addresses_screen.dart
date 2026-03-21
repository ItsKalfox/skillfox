import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../models/user_address.dart';
import '../../../../services/address_service.dart';
import 'edit_address_screen.dart';
import 'new_address_screen.dart';

class WorkerAddressesScreen extends StatefulWidget {
  final UserAddress? selectedAddress;

  const WorkerAddressesScreen({super.key, this.selectedAddress});

  @override
  State<WorkerAddressesScreen> createState() => _WorkerAddressesScreenState();
}

class _WorkerAddressesScreenState extends State<WorkerAddressesScreen> {
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
      MaterialPageRoute(builder: (_) => const WorkerNewAddressScreen()),
    );

    if (result != null) {
      await _addressService.addAddress(result);
    }
  }

  Future<void> _openEditAddress(UserAddress address) async {
    final result = await Navigator.push<UserAddress>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkerEditAddressScreen(address: address),
      ),
    );

    if (result != null) {
      await _addressService.updateAddress(result);
    }
  }

  Future<void> _selectCurrentLocation() async {
    setState(() {
      _isLoadingCurrentLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _isLoadingCurrentLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
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
      setState(() {
        _isLoadingCurrentLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get current location')),
      );
    }
  }

  void _selectAddress(UserAddress address) {
    Navigator.pop(context, address);
  }

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
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, size: 20),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Addresses',
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F2F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        size: 18,
                        color: Color(0xFF8A8A8A),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search for an address',
                            border: InputBorder.none,
                            isCollapsed: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: StreamBuilder<List<UserAddress>>(
                  stream: _addressService.getAddresses(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final addresses = _filterAddresses(snapshot.data ?? []);

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        const Text(
                          'Nearby',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _CurrentLocationTile(
                          selected: currentLocationSelected,
                          isLoading: _isLoadingCurrentLocation,
                          onTap: _selectCurrentLocation,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Saved Address',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (addresses.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'No saved addresses yet',
                                style: TextStyle(
                                  color: Color(0xFF8A8A8A),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                        else
                          ...addresses.map(
                            (address) => _AddressTile(
                              address: address,
                              selected: _isSelected(address),
                              onTap: () => _selectAddress(address),
                              onEditTap: () => _openEditAddress(address),
                              onSetDefaultTap: () =>
                                  _addressService.setDefaultAddress(address.id),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _openNewAddress,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add new address'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F2F6),
                      foregroundColor: const Color(0xFF222222),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
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
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: const Border(bottom: BorderSide(color: Color(0xFFEAECEF))),
          color: selected ? const Color(0xFFF7FAFF) : Colors.transparent,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.my_location_rounded,
              size: 18,
              color: Color(0xFF666666),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Location',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF222222),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Use your live device location',
                    style: TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: const Border(bottom: BorderSide(color: Color(0xFFEAECEF))),
          color: selected ? const Color(0xFFF7FAFF) : Colors.transparent,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 18,
              color: Color(0xFF666666),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.label,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF222222),
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
                            color: const Color(0xFFEFF3FF),
                            borderRadius: BorderRadius.circular(10),
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
                  const SizedBox(height: 2),
                  Text(
                    address.fullAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8A8A8A),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEditTap();
                if (value == 'default') onSetDefaultTap();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'default', child: Text('Set as default')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
