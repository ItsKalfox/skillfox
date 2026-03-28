import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/week_helper.dart';
import '../../../models/user_address.dart';
import '../../../models/worker.dart';
import '../../../services/address_service.dart';
import '../../../services/favorite_service.dart';
import '../../../services/location_service.dart';
import '../../../services/worker_service.dart';
import 'section_workers_screen.dart';
import '../../customer/worker/worker_profile.dart';

class HomeScreen extends StatefulWidget {
  final UserAddress? selectedAddress;
  final String selectedAddressLabel;
  final Future<Position?>? locationFuture;
  final bool isLoadingDefaultAddress;
  final VoidCallback onAddressTap;

  const HomeScreen({
    super.key,
    required this.selectedAddress,
    required this.selectedAddressLabel,
    required this.locationFuture,
    required this.isLoadingDefaultAddress,
    required this.onAddressTap,
  });

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

  // ── Book Again ────────────────────────────────────────────────────────────
  List<Worker> _bookAgainWorkers = [];

  @override
  void initState() {
    super.initState();
    _loadBookAgainWorkers();
  }

  /// Fetches the customer's past completed requests, deduplicates by workerId,
  /// and builds Worker objects. Also fetches the worker's live profile photo
  /// from the 'workers' collection so the avatar is always up to date.
  Future<void> _loadBookAgainWorkers() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // Fetch all completed requests for this customer.
      // We include every terminal status so Cat A (quotation_paid/declined),
      // Cat B (job_done/completed) and Cat C (completed) all appear.
      // NOTE: whereIn + orderBy requires a composite index in Firestore.
      // To avoid that requirement we fetch without orderBy and sort in-memory.
      final snap = await FirebaseFirestore.instance
          .collection('requests')
          .where('customerId', isEqualTo: uid)
          .where(
            'status',
            whereIn: [
              'completed',
              'job_done',
              'quotation_paid',
              'quotation_declined',
            ],
          )
          .get();

      // Sort in-memory newest first (avoids composite index requirement)
      final docs = [...snap.docs]
        ..sort((a, b) {
          final ta =
              (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
              0;
          final tb =
              (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
              0;
          return tb.compareTo(ta);
        });

      // Deduplicate — keep only the most recent request per workerId
      final Map<String, Map<String, dynamic>> seen = {};
      for (final doc in docs) {
        final d = doc.data();
        final wid = d['workerId'] as String? ?? '';
        if (wid.isNotEmpty && !seen.containsKey(wid)) {
          seen[wid] = d;
        }
      }

      debugPrint(
        '[BookAgain] total docs: \${snap.docs.length}, unique workers: \${seen.length}',
      );
      if (seen.isEmpty) return;

      // Fetch live worker docs in parallel to get profilePhotoUrl + travelFee
      final workerFutures = seen.keys.map(
        (wid) =>
            FirebaseFirestore.instance.collection('workers').doc(wid).get(),
      );
      final workerDocs = await Future.wait(workerFutures);
      final Map<String, Map<String, dynamic>> workerData = {};
      for (final doc in workerDocs) {
        if (doc.exists) workerData[doc.id] = doc.data()!;
      }

      final List<Worker> result = [];
      for (final entry in seen.entries) {
        final wid = entry.key;
        final req = entry.value;
        final wd = workerData[wid] ?? {};

        result.add(
          Worker(
            id: wid,
            name: req['workerName'] as String? ?? '',
            category: req['category'] as String? ?? '',
            rating:
                (wd['averageRating'] as num?)?.toDouble() ??
                (req['workerRating'] as num?)?.toDouble() ??
                0.0,
            ratingCount: (wd['totalReviews'] as num?)?.toInt() ?? 0,
            completedJobsCount:
                (wd['completedJobsCount'] as num?)?.toInt() ?? 0,
            distanceKm: 0, // not relevant for book-again display
            travelMinutes: 0,
            travelFee:
                (wd['travelFee'] as num?)?.toDouble() ??
                (req['travelFee'] as num?)?.toDouble() ??
                0.0,
            hasOffer: (wd['hasOffer'] as bool?) ?? false,
            offerType: wd['offerType'] as String? ?? '',
            offerDetails: wd['offerDetails'] as String? ?? '',
            isFeatured: (wd['isFeatured'] as bool?) ?? false,
            featuredWeekKey: wd['featuredWeekKey'] as String? ?? '',
            isFavorite: false, // updated by favorites stream below
            profilePhotoUrl:
                (wd['profileImageUrl'] as String?) ??
                (wd['profilePhotoUrl'] as String?) ??
                '',
            address: wd['address'] as String? ?? '',
          ),
        );
      }

      if (mounted) setState(() => _bookAgainWorkers = result);
    } catch (e) {
      debugPrint('Book Again load error: $e');
    }
  }
  // ─────────────────────────────────────────────────────────────────────────

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

  void _goToWorkerProfile(Worker worker) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WorkerProfileScreen(worker: worker)),
    );
  }

  List<Worker> applyFilters(List<Worker> workers) {
    var filtered = workers;
    if (selectedCategory != 'All') {
      filtered = filtered
          .where(
            (w) => w.category.toLowerCase() == selectedCategory.toLowerCase(),
          )
          .toList();
    }
    if (offersOnly) filtered = filtered.where((w) => w.hasOffer).toList();
    if (under30Min)
      filtered = filtered.where((w) => w.travelMinutes <= 30).toList();
    if (highestRatedOnly)
      filtered = filtered.where((w) => w.rating >= 4.8).toList();
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
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'About Fees',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1F2E),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Varies based on distance and service requirements.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9AA3B4),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFF0F2F8)),
              const SizedBox(height: 20),
              _FeeRow(
                icon: Icons.directions_car_outlined,
                iconColor: const Color(0xFF4B7DF3),
                iconBg: const Color(0xFFEEF2FF),
                title: 'Travel Fee',
                description:
                    'Based on your location, the worker\'s distance, traffic conditions, and local availability.',
              ),
              const SizedBox(height: 16),
              _FeeRow(
                icon: Icons.search_rounded,
                iconColor: const Color(0xFF7C5CFC),
                iconBg: const Color(0xFFF0EBFF),
                title: 'Inspection Fee',
                description:
                    'Depends on service type and whether an on-site assessment is required before starting.',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1F2E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _travelFeeLabel(Worker worker) {
    if (worker.hasOffer && worker.offerType == 'Free Travel') {
      return 'LKR 0';
    }
    return 'LKR ${worker.travelFee.toStringAsFixed(0)}';
  }

  String _offerBadgeLabel(Worker worker) {
    if (worker.offerType == 'Free Travel') return 'FREE TRAVEL';
    if (worker.offerType == 'Percentage Discount') {
      return worker.offerDetails.isNotEmpty
          ? '${worker.offerDetails} OFF'
          : 'DISCOUNT';
    }
    return worker.offerDetails.isNotEmpty ? worker.offerDetails : 'OFFER';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoadingDefaultAddress) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F6FB),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4B7DF3)),
        ),
      );
    }

    if (widget.selectedAddress?.location != null) {
      final loc = widget.selectedAddress!.location!;
      return _buildHomeContent(
        customerLat: loc.latitude,
        customerLng: loc.longitude,
      );
    }

    return FutureBuilder<Position?>(
      future: widget.locationFuture,
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
                offerDetails: worker.offerDetails,
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

            // ── Book Again: use past-order workers, update isFavorite from stream
            final bookAgain = applyFilters(
              _bookAgainWorkers.map((w) {
                // Check if this worker also appears in the live list (for distance/travel)
                final live = workersWithFavorites
                    .where((lw) => lw.id == w.id)
                    .firstOrNull;
                return Worker(
                  id: w.id,
                  name: w.name,
                  category: w.category,
                  rating: live?.rating ?? w.rating,
                  ratingCount: live?.ratingCount ?? w.ratingCount,
                  completedJobsCount:
                      live?.completedJobsCount ?? w.completedJobsCount,
                  distanceKm: live?.distanceKm ?? w.distanceKm,
                  travelMinutes: live?.travelMinutes ?? w.travelMinutes,
                  travelFee: live?.travelFee ?? w.travelFee,
                  hasOffer: live?.hasOffer ?? w.hasOffer,
                  offerType: live?.offerType ?? w.offerType,
                  offerDetails: live?.offerDetails ?? w.offerDetails,
                  isFeatured: live?.isFeatured ?? w.isFeatured,
                  featuredWeekKey: live?.featuredWeekKey ?? w.featuredWeekKey,
                  isFavorite: favoriteIds.contains(w.id),
                  profilePhotoUrl: live?.profilePhotoUrl ?? w.profilePhotoUrl,
                  address: live?.address ?? w.address,
                );
              }).toList(),
            );

            final nearby = applyFilters(
              workersWithFavorites.where((w) => w.distanceKm <= 10).toList()
                ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm)),
            );
            final offers = applyFilters(
              workersWithFavorites.where((w) => w.hasOffer).toList(),
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

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
              ),
              child: SafeArea(
                top: false,
                child: Scaffold(
                  backgroundColor: const Color(0xFFF4F6FB),
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HomeHeaderCard(
                          categories: categories,
                          selectedCategory: selectedCategory,
                          onCategoryTap: (c) =>
                              setState(() => selectedCategory = c),
                          titleText: widget.selectedAddressLabel,
                          onAddressTap: widget.onAddressTap,
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildFilterRow(),
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isCategoryMode) ...[
                                Row(
                                  children: [
                                    Text(
                                      '${categoryListResults.length} result${categoryListResults.length == 1 ? '' : 's'}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF555555),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: resetFilters,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEEF2FF),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Text(
                                          'Reset filters',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF4B7DF3),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                if (categoryListResults.isEmpty)
                                  const _EmptySectionText(
                                    text: 'No workers found for this category',
                                  )
                                else
                                  ...categoryListResults.map(
                                    (worker) => _WorkerListTile(
                                      worker: worker,
                                      travelFeeLabel: _travelFeeLabel(worker),
                                      showOfferTag: true,
                                      onFavoriteTap: () =>
                                          _favoriteService.toggleFavorite(
                                            worker.id,
                                            worker.isFavorite,
                                          ),
                                      onTap: () => _goToWorkerProfile(worker),
                                    ),
                                  ),
                              ] else ...[
                                // Fees notice
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F4FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFD6E2FF),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline_rounded,
                                        size: 15,
                                        color: Color(0xFF4B7DF3),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: Color(0xFF4B7DF3),
                                              fontWeight: FontWeight.w500,
                                            ),
                                            children: [
                                              const TextSpan(
                                                text:
                                                    'Additional fees may apply. ',
                                              ),
                                              TextSpan(
                                                text: 'Learn more',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                                recognizer:
                                                    TapGestureRecognizer()
                                                      ..onTap =
                                                          _showFeesInfoSheet,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 22),

                                _SectionHeader(
                                  title: 'Featured on SkillFox',
                                  onSeeAll: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SectionWorkersScreen(
                                        title: 'Featured on SkillFox',
                                        workers: featured,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildListPreview(featured, 2),
                                const SizedBox(height: 26),

                                // ── Book Again — only shown when customer has past orders
                                if (bookAgain.isNotEmpty) ...[
                                  _SectionHeader(
                                    title: 'Book again',
                                    onSeeAll: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SectionWorkersScreen(
                                          title: 'Book again',
                                          workers: bookAgain,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildGridPreview(bookAgain, 4),
                                  const SizedBox(height: 26),
                                ],

                                _SectionHeader(
                                  title: 'Workers near you',
                                  onSeeAll: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SectionWorkersScreen(
                                        title: 'Workers near you',
                                        workers: nearby,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildListPreview(nearby, 2),
                                const SizedBox(height: 26),

                                _SectionHeader(
                                  title: "Today's offers",
                                  onSeeAll: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SectionWorkersScreen(
                                        title: "Today's offers",
                                        workers: offers,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildOfferPreview(offers, 2),
                                const SizedBox(height: 26),

                                _SectionHeader(
                                  title: 'Highest rated',
                                  onSeeAll: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SectionWorkersScreen(
                                        title: 'Highest rated',
                                        workers: highestRated,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildListPreview(highestRated, 2),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
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
    if (workers.isEmpty) return const _EmptySectionText();
    return Column(
      children: workers
          .take(count)
          .map(
            (worker) => _WorkerListTile(
              worker: worker,
              travelFeeLabel: _travelFeeLabel(worker),
              showOfferTag: false,
              onFavoriteTap: () =>
                  _favoriteService.toggleFavorite(worker.id, worker.isFavorite),
              onTap: () => _goToWorkerProfile(worker),
            ),
          )
          .toList(),
    );
  }

  Widget _buildOfferPreview(List<Worker> workers, int count) {
    if (workers.isEmpty) return const _EmptySectionText();
    return Column(
      children: workers
          .take(count)
          .map(
            (worker) => _OfferTile(
              worker: worker,
              travelFeeLabel: _travelFeeLabel(worker),
              offerBadgeLabel: _offerBadgeLabel(worker),
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

class _CategoryData {
  final String label;
  final String imagePath;
  const _CategoryData({required this.label, required this.imagePath});
}

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
                              category.label == 'All' ? 0 : 7,
                            ),
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
            color: selected ? const Color(0xFF4B7DF3) : const Color(0xFFE2E6F0),
            width: 1.5,
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
              size: 14,
              color: selected ? Colors.white : const Color(0xFF777777),
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
  final bool showOfferTag;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  const _WorkerListTile({
    required this.worker,
    required this.travelFeeLabel,
    required this.showOfferTag,
    required this.onFavoriteTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF0F2F8))),
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
                  ? const Icon(Icons.person, size: 26, color: Color(0xFF5B6475))
                  : null,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          worker.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1F2E),
                          ),
                        ),
                      ),
                      if (showOfferTag && worker.hasOffer) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEB),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'OFFER',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE53935),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    worker.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9AA3B4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_car_outlined,
                        size: 12,
                        color: Color(0xFF9AA3B4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Travel fee $travelFeeLabel',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      if (worker.rating > 0) ...[
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          worker.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1F2E),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: Color(0xFFCBD0DC),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        '${worker.distanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9AA3B4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: Color(0xFFCBD0DC),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${worker.travelMinutes} min',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9AA3B4),
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
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: worker.isFavorite
                      ? const Color(0xFFFFEBEB)
                      : const Color(0xFFF4F6FB),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  worker.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: worker.isFavorite
                      ? Colors.redAccent
                      : const Color(0xFFBCC4D4),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final Worker worker;
  final String travelFeeLabel;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  const _WorkerCard({
    required this.worker,
    required this.travelFeeLabel,
    required this.onFavoriteTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEAECEF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EAF3),
                    borderRadius: BorderRadius.circular(14),
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
                            size: 40,
                            color: Color(0xFF677082),
                          ),
                        )
                      : null,
                ),
                Positioned(
                  top: 7,
                  right: 7,
                  child: GestureDetector(
                    onTap: onFavoriteTap,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: worker.isFavorite
                            ? const Color(0xFFFFEBEB)
                            : Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        worker.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 16,
                        color: worker.isFavorite
                            ? Colors.redAccent
                            : const Color(0xFFBCC4D4),
                      ),
                    ),
                  ),
                ),
                if (worker.hasOffer)
                  Positioned(
                    top: 7,
                    left: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'OFFER',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              worker.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1F2E),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              worker.category,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF9AA3B4)),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(
                  Icons.directions_car_outlined,
                  size: 11,
                  color: Color(0xFF9AA3B4),
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    travelFeeLabel,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF555555),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                if (worker.rating > 0) ...[
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                  const SizedBox(width: 3),
                  Text(
                    worker.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1F2E),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '${worker.distanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9AA3B4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferTile extends StatelessWidget {
  final Worker worker;
  final String travelFeeLabel;
  final String offerBadgeLabel;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  const _OfferTile({
    required this.worker,
    required this.travelFeeLabel,
    required this.offerBadgeLabel,
    required this.onFavoriteTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFreeTravel = worker.offerType == 'Free Travel';
    final badgeColor = isFreeTravel
        ? const Color(0xFF2E7D32)
        : const Color(0xFFE53935);
    final badgeBg = isFreeTravel
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFEBEB);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF0F2F8))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor: const Color(0xFFE6EAF7),
              backgroundImage: worker.profilePhotoUrl.isNotEmpty
                  ? NetworkImage(worker.profilePhotoUrl)
                  : null,
              child: worker.profilePhotoUrl.isEmpty
                  ? const Icon(Icons.person, size: 26, color: Color(0xFF5B6475))
                  : null,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker.name,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1F2E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    worker.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9AA3B4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_car_outlined,
                        size: 12,
                        color: Color(0xFF9AA3B4),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Travel fee $travelFeeLabel',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (worker.rating > 0) ...[
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          worker.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1F2E),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: Color(0xFFCBD0DC),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          '${worker.distanceKm.toStringAsFixed(1)} km • ${worker.travelMinutes} min',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9AA3B4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    offerBadgeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onFavoriteTap,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: worker.isFavorite
                          ? const Color(0xFFFFEBEB)
                          : const Color(0xFFF4F6FB),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      worker.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: worker.isFavorite
                          ? Colors.redAccent
                          : const Color(0xFFBCC4D4),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
