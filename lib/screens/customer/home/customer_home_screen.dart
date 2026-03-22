import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/utils/week_helper.dart';
import '../../../models/user_address.dart';
import '../../../models/worker.dart';
import '../../../services/address_service.dart';
import '../../../services/favorite_service.dart';
import '../../../services/location_service.dart';
import '../../../services/worker_service.dart';
import '../profile/addresses/addresses_screen.dart';
import 'section_workers_screen.dart';
import '../worker/worker_profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  final WorkerService _workerService = WorkerService();
  final FavoriteService _favoriteService = FavoriteService();
  final AddressService _addressService = AddressService();

  String selectedCategory = 'All';
  bool offersOnly = false;
  bool under30Min = false;
  bool highestRatedOnly = false;

  Future<Position?>? _locationFuture;

  UserAddress? _selectedAddress;
  String _selectedAddressLabel = 'Home';
  bool _isLoadingDefaultAddress = true;

  final List<_CategoryData> categories = const [
    _CategoryData(label: 'All', imagePath: ''),
    _CategoryData(label: 'Mechanic', imagePath: 'assets/icons/mechanic.png'),
    _CategoryData(label: 'Teacher', imagePath: 'assets/icons/teacher.png'),
    _CategoryData(label: 'Plumber', imagePath: 'assets/icons/plumber.png'),
    _CategoryData(
      label: 'Electrician',
      imagePath: 'assets/icons/electrician.png',
    ),
    _CategoryData(label: 'Cleaner', imagePath: 'assets/icons/cleaner.png'),
    _CategoryData(label: 'Caregiver', imagePath: 'assets/icons/caregiver.png'),
    _CategoryData(label: 'Mason', imagePath: 'assets/icons/mason.png'),
    _CategoryData(label: 'Handyman', imagePath: 'assets/icons/handyman.png'),
  ];

  @override
  void initState() {
    super.initState();
    _locationFuture = _locationService.getCurrentLocation();
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

  List<Worker> applyFilters(List<Worker> workers) {
    var filtered = workers;
    if (selectedCategory != 'All') {
      filtered = filtered
          .where(
            (worker) =>
                worker.category.toLowerCase() == selectedCategory.toLowerCase(),
          )
          .toList();
    }

    if (offersOnly) {
      filtered = filtered.where((worker) => worker.hasOffer).toList();
    }

    if (under30Min) {
      filtered = filtered
          .where((worker) => worker.travelMinutes <= 30)
          .toList();
    }

    if (highestRatedOnly) {
      filtered = filtered.where((worker) => worker.rating >= 4.8).toList();
    }

    return filtered;
  }

  void resetFilters() {
    setState(() {
      selectedCategory = 'All';
      offersOnly = false;
      under30Min = false;
      highestRatedOnly = false;
    });
  }

  void _showFeesInfoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Varies based on distance and service requirements.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: Color(0xFFE8E8E8)),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Travel Fee',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF222222),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Varies based on your location, the worker’s distance, traffic conditions, and availability in your area.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Inspection Fee',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF222222),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Varies depending on the type of service and whether an on-site assessment is required before starting the job.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _travelFeeLabel(Worker worker) {
    if (worker.hasOffer && worker.offerType == 'free_travel') {
      return 'Travel fee LKR 0';
    }
    return 'Travel fee LKR ${worker.travelFee.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDefaultAddress) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F6FB),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4B7DF3)),
        ),
      );
    }

    if (_selectedAddress?.location != null) {
      final selectedLocation = _selectedAddress!.location!;

      return _buildHomeContent(
        customerLat: loc.latitude,
        customerLng: loc.longitude,
      );
    }

    return FutureBuilder<Position?>(
      future: _locationFuture,
      builder: (context, locationSnapshot) {
        if (locationSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF4F6FB),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF4B7DF3)),
            ),
          );
        }
        final pos = locationSnapshot.data;
        if (pos == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF4F6FB),
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_off_outlined,
                      size: 48,
                      color: Color(0xFFBCC4D4),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Location access needed',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1F2E),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Enable location permission to see nearby workers and travel fees.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF9AA3B4)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return _buildHomeContent(
          customerLat: pos.latitude,
          customerLng: pos.longitude,
        );
      },
    );
  }

  Widget _buildHomeContent({
    required double customerLat,
    required double customerLng,
  }) {
    return StreamBuilder<List<Worker>>(
      stream: _workerService.getWorkersForCustomerLocation(
        customerLat: customerLat,
        customerLng: customerLng,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF4F6FB),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF4B7DF3)),
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFF4F6FB),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final allWorkers = snapshot.data ?? [];

        return StreamBuilder<Set<String>>(
          stream: _favoriteService.getFavoriteWorkerIds(),
          builder: (context, favoriteSnapshot) {
            final favoriteIds = favoriteSnapshot.data ?? <String>{};

            final workersWithFavorites = allWorkers.map((worker) {
              return Worker(
                id: worker.id,
                name: worker.name,
                category: worker.category,
                rating: worker.rating,
                ratingCount: worker.ratingCount,
                completedJobsCount: worker.completedJobsCount,
                distanceKm: worker.distanceKm,
                travelMinutes: worker.travelMinutes,
                travelFee: worker.travelFee,
                hasOffer: worker.hasOffer,
                offerType: worker.offerType,
                isFeatured: worker.isFeatured,
                featuredWeekKey: worker.featuredWeekKey,
                isFavorite: favoriteIds.contains(worker.id),
                profilePhotoUrl: worker.profilePhotoUrl,
                address: worker.address,
              );
            }).toList();

            final currentWeek = getCurrentWeekKey();

            final featured = applyFilters(
              workersWithFavorites
                  .where(
                    (w) => w.isFeatured && w.featuredWeekKey == currentWeek,
                  )
                  .toList(),
            );
            final bookAgain = applyFilters(const <Worker>[]);
            final nearby = applyFilters(
              workersWithFavorites.where((w) => w.distanceKm <= 10).toList()
                ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm)),
            );
            final offers = applyFilters(
              workersWithFavorites.where((worker) => worker.hasOffer).toList(),
            );
            final highestRated = applyFilters(
              [...workersWithFavorites]
                ..sort((a, b) => b.rating.compareTo(a.rating)),
            ).where((w) => w.rating >= 4.8).toList();
            final categoryListResults = applyFilters(
              [...workersWithFavorites]
                ..sort((a, b) => a.travelMinutes.compareTo(b.travelMinutes)),
            );

            final bool isCategoryMode = selectedCategory != 'All';

            return SafeArea(
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HomeHeaderCard(
                        categories: categories,
                        selectedCategory: selectedCategory,
                        onCategoryTap: (category) {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                        titleText: _selectedAddressLabel,
                        onAddressTap: _openAddresses,
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildFilterRow(),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isCategoryMode) ...[
                              Row(
                                children: [
                                  Text(
                                    '${categoryListResults.length} results',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF555555),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: resetFilters,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F1F1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Text(
                                        'Reset',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF444444),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (categoryListResults.isEmpty)
                                const _EmptySectionText(
                                  text: 'No workers found for this category',
                                )
                              else
                                ...categoryListResults.map(
                                  (worker) => _WorkerListTile(
                                    worker: worker,
                                    travelFeeLabel: _travelFeeLabel(worker),
                                    onFavoriteTap: () =>
                                        _favoriteService.toggleFavorite(
                                          worker.id,
                                          worker.isFavorite,
                                        ),
                                  ),
                                ),
                            ] else ...[
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF666666),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'Additional fees may apply. ',
                                    ),
                                    TextSpan(
                                      text: 'Learn more',
                                      style: const TextStyle(
                                        color: Color(0xFF222222),
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = _showFeesInfoSheet,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              _SectionHeader(
                                title: 'Featured on SkillFox',
                                onSeeAll: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SectionWorkersScreen(
                                        title: 'Featured on SkillFox',
                                        workers: featured,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              _buildListPreview(featured, 2),
                              const SizedBox(height: 22),
                              _SectionHeader(
                                title: 'Book again',
                                onSeeAll: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SectionWorkersScreen(
                                        title: 'Book again',
                                        workers: bookAgain,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              _buildGridPreview(bookAgain, 4),
                              const SizedBox(height: 22),
                              _SectionHeader(
                                title: 'Workers near you',
                                onSeeAll: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SectionWorkersScreen(
                                        title: 'Workers near you',
                                        workers: nearby,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              _buildListPreview(nearby, 2),
                              const SizedBox(height: 22),
                              _SectionHeader(
                                title: "Today's offers",
                                onSeeAll: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SectionWorkersScreen(
                                        title: "Today's offers",
                                        workers: offers,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              _buildOfferPreview(offers, 2),
                              const SizedBox(height: 22),
                              _SectionHeader(
                                title: 'Highest rated',
                                onSeeAll: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SectionWorkersScreen(
                                        title: 'Highest rated',
                                        workers: highestRated,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              _buildListPreview(highestRated, 2),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChipWidget(
            label: 'Offers',
            icon: Icons.local_offer_outlined,
            selected: offersOnly,
            onTap: () => setState(() => offersOnly = !offersOnly),
          ),
          const SizedBox(width: 8),
          _FilterChipWidget(
            label: 'Under 30 min',
            icon: Icons.access_time_rounded,
            selected: under30Min,
            onTap: () => setState(() => under30Min = !under30Min),
          ),
          const SizedBox(width: 8),
          _FilterChipWidget(
            label: 'Highest rated',
            icon: Icons.star_outline_rounded,
            selected: highestRatedOnly,
            onTap: () => setState(() => highestRatedOnly = !highestRatedOnly),
          ),
        ],
      ),
    );
  }

  Widget _buildListPreview(List<Worker> workers, int count) {
    if (workers.isEmpty) {
      return const _EmptySectionText();
    }

    final preview = workers.take(count).toList();
    return Column(
      children: workers
          .take(count)
          .map(
            (worker) => _WorkerListTile(
              worker: worker,
              travelFeeLabel: _travelFeeLabel(worker),
              onFavoriteTap: () =>
                  _favoriteService.toggleFavorite(worker.id, worker.isFavorite),
              onTap: () => _goToWorkerProfile(worker),
            ),
          )
          .toList(),
    );
  }

  Widget _buildOfferPreview(List<Worker> workers, int count) {
    if (workers.isEmpty) {
      return const _EmptySectionText();
    }

    final preview = workers.take(count).toList();
    return Column(
      children: workers
          .take(count)
          .map(
            (worker) => _OfferTile(
              worker: worker,
              travelFeeLabel: _travelFeeLabel(worker),
              onFavoriteTap: () =>
                  _favoriteService.toggleFavorite(worker.id, worker.isFavorite),
              onTap: () => _goToWorkerProfile(worker),
            ),
          )
          .toList(),
    );
  }

  Widget _buildGridPreview(List<Worker> workers, int count) {
    if (workers.isEmpty) return const _EmptySectionText();
    final preview = workers.take(count).toList();
    return GridView.builder(
      itemCount: preview.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.83,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (_, index) => _WorkerCard(
        worker: preview[index],
        travelFeeLabel: _travelFeeLabel(preview[index]),
        onFavoriteTap: () => _favoriteService.toggleFavorite(
          preview[index].id,
          preview[index].isFavorite,
        ),
        onTap: () => _goToWorkerProfile(preview[index]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  PRIVATE WIDGETS
// ═══════════════════════════════════════════════════════

// ═══════════════════════════════════════════════
//  Fee Row (bottom sheet helper)
// ═══════════════════════════════════════════════
class _FeeRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String description;

  const _FeeRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 19),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F2E),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: Color(0xFF9AA3B4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
//  Category Data
// ═══════════════════════════════════════════════
class _CategoryData {
  final String label;
  final String imagePath;
  const _CategoryData({required this.label, required this.imagePath});
}

// ═══════════════════════════════════════════════
//  Home Header Card
// ═══════════════════════════════════════════════
class _HomeHeaderCard extends StatelessWidget {
  final List<_CategoryData> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategoryTap;
  final String titleText;
  final VoidCallback onAddressTap;

  const _HomeHeaderCard({
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryTap,
    required this.titleText,
    required this.onAddressTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5AA4F6), Color(0xFF3A6BE8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              MediaQuery.of(context).padding.top + 18,
              18,
              14,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onAddressTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          titleText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF4F6FB),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
                bottom: Radius.circular(30),
              ),
            ),
            child: SizedBox(
              height: 98,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final bool isSelected = selectedCategory == category.label;
                  return GestureDetector(
                    onTap: () => onCategoryTap(category.label),
                    child: SizedBox(
                      width: 70,
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 56,
                            height: 56,
                            padding: EdgeInsets.all(
                                category.label == 'All' ? 0 : 7),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFEFF3FF)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF6B8EFF)
                                    : const Color(0xFFE8EBF4),
                                width: 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF4B7DF3,
                                        ).withOpacity(0.18),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: category.label == 'All'
                                ? Icon(
                                    Icons.grid_view_rounded,
                                    size: 22,
                                    color: isSelected
                                        ? const Color(0xFF5C7FFF)
                                        : const Color(0xFF909090),
                                  )
                                : Image.asset(
                                    category.imagePath,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.home_repair_service_outlined,
                                      color: isSelected
                                          ? const Color(0xFF5C7FFF)
                                          : const Color(0xFF909090),
                                      size: 22,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            category.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF4B7DF3)
                                  : const Color(0xFF555555),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Section Header
// ═══════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
              color: Color(0xFF1A1F2E),
            ),
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Row(
            children: [
              const Text(
                'See all',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4B7DF3),
                ),
              ),
              const SizedBox(width: 3),
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFFEEF2FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: Color(0xFF4B7DF3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
//  Filter Chip
// ═══════════════════════════════════════════════
class _FilterChipWidget extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipWidget({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4B7DF3) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF7B61FF) : const Color(0xFFE6E8F0),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4B7DF3).withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? const Color(0xFF6F5CFF)
                  : const Color(0xFF666666),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF444444),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerListTile extends StatelessWidget {
  final Worker worker;
  final String travelFeeLabel;
  final VoidCallback onFavoriteTap;

  const _WorkerListTile({
    required this.worker,
    required this.travelFeeLabel,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE9E9E9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: const Color(0xFFE6EAF7),
            backgroundImage: worker.profilePhotoUrl.isNotEmpty
                ? NetworkImage(worker.profilePhotoUrl)
                : null,
            child: worker.profilePhotoUrl.isEmpty
                ? const Icon(Icons.person, size: 28, color: Color(0xFF5B6475))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  worker.category,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF8A8A8A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$travelFeeLabel • ${worker.travelMinutes} min',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      worker.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${worker.distanceKm.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8A8A8A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onFavoriteTap,
            child: Icon(
              worker.isFavorite
                  ? Icons.favorite
                  : Icons.favorite_border_rounded,
              color: worker.isFavorite ? Colors.redAccent : Colors.black45,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final Worker worker;
  final String travelFeeLabel;
  final VoidCallback onFavoriteTap;

  const _WorkerCard({
    required this.worker,
    required this.travelFeeLabel,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 105,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EAF3),
                  borderRadius: BorderRadius.circular(18),
                  image: worker.profilePhotoUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(worker.profilePhotoUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: worker.profilePhotoUrl.isEmpty
                    ? const Center(
                        child: Icon(
                          Icons.person,
                          size: 42,
                          color: Color(0xFF677082),
                        ),
                      )
                    : null,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onFavoriteTap,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Icon(
                      worker.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border_rounded,
                      size: 18,
                      color: worker.isFavorite
                          ? Colors.redAccent
                          : Colors.black45,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            worker.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            worker.category,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF8A8A8A)),
          ),
          const SizedBox(height: 4),
          Text(
            '$travelFeeLabel • ${worker.travelMinutes} min',
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF8A8A8A)),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                worker.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${worker.distanceKm.toStringAsFixed(1)} km',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OfferTile extends StatelessWidget {
  final Worker worker;
  final String travelFeeLabel;
  final VoidCallback onFavoriteTap;

  const _OfferTile({
    required this.worker,
    required this.travelFeeLabel,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final offerBadge = worker.offerType == 'free_travel'
        ? 'FREE TRAVEL'
        : 'OFFER';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE9E9E9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: const Color(0xFFE6EAF7),
            backgroundImage: worker.profilePhotoUrl.isNotEmpty
                ? NetworkImage(worker.profilePhotoUrl)
                : null,
            child: worker.profilePhotoUrl.isEmpty
                ? const Icon(Icons.person, size: 28, color: Color(0xFF5B6475))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  worker.category,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$travelFeeLabel • ${worker.travelMinutes} min',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${worker.distanceKm.toStringAsFixed(1)} km away',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  offerBadge,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.redAccent,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onFavoriteTap,
                child: Icon(
                  worker.isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border_rounded,
                  color: worker.isFavorite ? Colors.redAccent : Colors.black45,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptySectionText extends StatelessWidget {
  final String text;

  const _EmptySectionText({this.text = 'No workers found for this section'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 32,
              color: Color(0xFFCBD0DC),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFF9AA3B4),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}