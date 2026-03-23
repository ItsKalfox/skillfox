import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../home/customer_home_screen.dart';
import '../community/customer_community_feed_screen.dart';
import '../search/customer_search_screen.dart';
import '../bookings/customer_bookings_screen.dart';
import '../profile/customer_profile_screen.dart';
import '../profile/addresses/addresses_screen.dart';
import '../../../services/location_service.dart';
import '../../../models/user_address.dart';
import '../../../services/address_service.dart';

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  int _currentIndex = 0;

  final LocationService _locationService = LocationService();
  final AddressService _addressService = AddressService();

  Future<Position?>? _locationFuture;
  Position? _currentPosition;
  UserAddress? _selectedAddress;
  String _selectedAddressLabel = 'Home';
  bool _isLoadingDefaultAddress = true;

  @override
  void initState() {
    super.initState();
    _locationFuture = _locationService.getCurrentLocation();
    _locationFuture?.then((pos) {
      if (mounted && pos != null) setState(() => _currentPosition = pos);
    });
    _loadDefaultAddress();
  }

  Future<void> _loadDefaultAddress() async {
    final defaultAddress = await _addressService.getDefaultAddress();
    if (!mounted) return;
    setState(() {
      _selectedAddress = defaultAddress;
      _selectedAddressLabel =
          (defaultAddress != null && defaultAddress.label.isNotEmpty)
              ? defaultAddress.label
              : 'Home';
      _isLoadingDefaultAddress = false;
    });
  }

  Future<void> _openAddresses() async {
    final result = await Navigator.push<UserAddress>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CustomerAddressesScreen(selectedAddress: _selectedAddress),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedAddress = result;
        _selectedAddressLabel = result.label.isEmpty ? 'Home' : result.label;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double lat = _selectedAddress?.location?.latitude ?? _currentPosition?.latitude ?? 6.9271;
    final double lng = _selectedAddress?.location?.longitude ?? _currentPosition?.longitude ?? 79.8612;

    final List<Widget> screens = [
      HomeScreen(
        selectedAddress: _selectedAddress,
        selectedAddressLabel: _selectedAddressLabel,
        locationFuture: _locationFuture,
        isLoadingDefaultAddress: _isLoadingDefaultAddress,
        onAddressTap: _openAddresses,
      ),
      const CustomerCommunityFeedScreen(),
      CustomerSearchScreen(
        customerLat: lat,
        customerLng: lng,
      ),
      const CustomerBookingsScreen(),
      const CustomerProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: screens[_currentIndex],
      bottomNavigationBar: SkillFoxBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class SkillFoxBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const SkillFoxBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEFEAFF), Color(0xFF8B79FF), Color(0xFF6C59F8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            children: [
              _NavCircleButton(
                icon: Icons.home_filled,
                active: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              const SizedBox(width: 10),
              _NavCircleButton(
                icon: Icons.chat_bubble_outline_rounded,
                active: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(2),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: Color(0xFF9A9A9A),
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Search',
                          style: TextStyle(
                            color: Color(0xFF9A9A9A),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              _NavCircleButton(
                icon: Icons.calendar_month_outlined,
                active: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              const SizedBox(width: 10),
              _NavCircleButton(
                icon: Icons.person_outline_rounded,
                active: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavCircleButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _NavCircleButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 22,
          color: active ? Colors.black : const Color(0xFF8F8F8F),
        ),
      ),
    );
  }
}