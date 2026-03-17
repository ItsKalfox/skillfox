import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/worker.dart';
import '../../services/location_service.dart';
import '../../services/worker_service.dart';
import 'section_workers_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  final WorkerService _workerService = WorkerService();

  String selectedCategory = 'All';
  bool offersOnly = false;
  bool under30Min = false;
  bool highestRatedOnly = false;

  Future<Position?>? _locationFuture;

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
  ];

  @override
  void initState() {
    super.initState();
    _locationFuture = _locationService.getCurrentLocation();
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Position?>(
      future: _locationFuture,
      builder: (context, locationSnapshot) {
        if (locationSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final customerPosition = locationSnapshot.data;

        if (customerPosition == null) {
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Location permission is required to show nearby workers and travel fees.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return StreamBuilder<List<Worker>>(
          stream: _workerService.getWorkersForCustomerLocation(
            customerLat: customerPosition.latitude,
            customerLng: customerPosition.longitude,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
                body: Center(child: Text('Error: ${snapshot.error}')),
              );
            }

            final allWorkers = snapshot.data ?? [];

            final featured = applyFilters(
              allWorkers.where((worker) => worker.isFeatured).toList(),
            );

            final bookAgain = applyFilters(const <Worker>[]);

            final nearby = applyFilters(
              allWorkers.where((worker) => worker.distanceKm <= 10).toList()
                ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm)),
            );

            final offers = applyFilters(
              allWorkers.where((worker) => worker.hasOffer).toList(),
            );

            final highestRated = applyFilters(
              [...allWorkers]..sort((a, b) => b.rating.compareTo(a.rating)),
            ).where((worker) => worker.rating >= 4.8).toList();

            final categoryListResults = applyFilters(
              [...allWorkers]
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
                                  (worker) => _WorkerListTile(worker: worker),
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
            onTap: () {
              setState(() {
                offersOnly = !offersOnly;
              });
            },
          ),
          const SizedBox(width: 10),
          _FilterChipWidget(
            label: 'Under 30 min',
            icon: Icons.access_time,
            selected: under30Min,
            onTap: () {
              setState(() {
                under30Min = !under30Min;
              });
            },
          ),
          const SizedBox(width: 10),
          _FilterChipWidget(
            label: 'Highest rated',
            icon: Icons.person_search_outlined,
            selected: highestRatedOnly,
            onTap: () {
              setState(() {
                highestRatedOnly = !highestRatedOnly;
              });
            },
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
      children: preview
          .map((worker) => _WorkerListTile(worker: worker))
          .toList(),
    );
  }

  Widget _buildOfferPreview(List<Worker> workers, int count) {
    if (workers.isEmpty) {
      return const _EmptySectionText();
    }

    final preview = workers.take(count).toList();
    return Column(
      children: preview.map((worker) => _OfferTile(worker: worker)).toList(),
    );
  }

  Widget _buildGridPreview(List<Worker> workers, int count) {
    if (workers.isEmpty) {
      return const _EmptySectionText();
    }

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
      itemBuilder: (_, index) => _WorkerCard(worker: preview[index]),
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

  const _HomeHeaderCard({
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5AA4F6), Color(0xFF4B7DF3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Row(
              children: const [
                Text(
                  'Home',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                Spacer(),
                Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F7FA),
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
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final bool isSelected = selectedCategory == category.label;

                  return GestureDetector(
                    onTap: () => onCategoryTap(category.label),
                    child: SizedBox(
                      width: 66,
                      child: Column(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            padding: EdgeInsets.all(
                              category.label == 'All' ? 0 : 7,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFEFF3FF)
                                  : const Color(0xFFF3F3F6),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF6B8EFF)
                                    : const Color(0xFFE1E3EA),
                                width: 1.2,
                              ),
                            ),
                            child: category.label == 'All'
                                ? Icon(
                                    Icons.grid_view_rounded,
                                    size: 24,
                                    color: isSelected
                                        ? const Color(0xFF5C7FFF)
                                        : const Color(0xFF909090),
                                  )
                                : Image.asset(
                                    category.imagePath,
                                    fit: BoxFit.contain,
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF5C7FFF)
                                  : const Color(0xFF444444),
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
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF222222),
            ),
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F1F1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: Color(0xFF666666),
            ),
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
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAE6FF) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFF7B61FF) : const Color(0xFFE6E8F0),
          ),
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
                color: selected
                    ? const Color(0xFF6F5CFF)
                    : const Color(0xFF444444),
                fontWeight: FontWeight.w600,
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

  const _WorkerListTile({required this.worker});

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
                  'LKR ${worker.price} • Travel fee LKR ${worker.travelFee.toStringAsFixed(0)} • ${worker.travelMinutes} min',
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
          Icon(
            worker.isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
            color: worker.isFavorite ? Colors.redAccent : Colors.black45,
            size: 28,
          ),
        ],
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final Worker worker;

  const _WorkerCard({required this.worker});

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
            'Fee LKR ${worker.travelFee.toStringAsFixed(0)} • ${worker.travelMinutes} min',
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
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'LKR ${worker.price}',
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

  const _OfferTile({required this.worker});

  @override
  Widget build(BuildContext context) {
    final oldPrice = worker.oldPrice ?? worker.price;

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
                Row(
                  children: [
                    Text(
                      'LKR ${worker.price}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LKR $oldPrice',
                      style: const TextStyle(
                        fontSize: 11,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Travel fee LKR ${worker.travelFee.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'OFFER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.redAccent,
              ),
            ),
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
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF8A8A8A),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
