import 'package:flutter/material.dart';
import '../../../services/job_request_repository.dart';
import '../../customer/requests/job_request_page.dart';
import '../../../models/worker.dart';

// ═══════════════════════════════════════════════════════
//  WORKER PROFILE SCREEN  –  matches Figma node 2101-1448
// ═══════════════════════════════════════════════════════

class WorkerProfileScreen extends StatefulWidget {
  final Worker worker;
  const WorkerProfileScreen({super.key, required this.worker});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  static final JobRequestRepository _jobRequestRepository =
      JobRequestRepository();
  int _reviewPage = 0;
  static const int _perPage = 3;

  Worker get w => widget.worker;

  // ── design tokens ──────────────────────────────────────
  static const _gradientColors = [Color(0xFF469FEF), Color(0xFF5C75F0), Color(0xFF6C56F0)];
  static const _gradientStops  = [0.0, 0.258, 0.652];
  static const _black   = Color(0xFF000000);
  static const _grey    = Color(0xFF727272);
  static const _bgGrey  = Color(0xFFF2F2F7);
  static const _divider = Color(0xFFE0E0E0);
  static const _white   = Colors.white;
  static const _green   = Color(0xFF27C840);

  // ── static sample reviews ──────────────────────────────
  static const _reviews = [
    _Review('Jhon Mayers',    4.0, '9 hours ago',
        'Quick and professional service. He diagnosed the issue within minutes and explained everything clearly before starting the repair. Highly recommended.'),
    _Review('Ryan Mitchell',  4.5, '1 day ago',
        'Very friendly mechanic. Brake replacement was done on time and pricing was fair. Would definitely come back again.'),
    _Review('Olivia Bennett', 5.0, '2 days ago',
        'Amazing service! My car AC is working perfectly now. Honest advice and no unnecessary charges. Really appreciated that.'),
    _Review('Daniel Brooks',  5.0, '5 days ago',
        'Good communication and fast work. The engine diagnostic report was detailed and helpful. Slight delay, but overall great experience.'),
    _Review('Ethan Parker',   5.0, '1 week ago',
        "Best mechanic I've dealt with in a long time. Transparent pricing and quality workmanship. Highly trustworthy."),
  ];

  List<_Service> get _services => _servicesFor(w.category);

  // ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(),
                    _hline(),
                    _buildBio(),
                    _hline(),
                    _buildLabeledSection(
                      title: 'Certification',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _certsFor(w.category)
                            .map((c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Text(c,
                                      style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 10,
                                          color: _grey)),
                                ))
                            .toList(),
                      ),
                    ),
                    _hline(),
                    _buildLabeledSection(
                      title: 'Experience',
                      child: Text(
                        _expFor(w.category),
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: _grey),
                      ),
                    ),
                    _hline(),
                    _buildServicesCard(),
                    _buildReviewsSection(),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ],
          ),
          _buildBottomButton(context),
        ],
      ),
    );
  }

  // ── SliverAppBar with cover image ──────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: const Color(0xFF469FEF),
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // cover / hero image
            w.profilePhotoUrl.isNotEmpty
                ? Image.network(w.profilePhotoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _gradientBox())
                : _gradientBox(),
            // top-fade overlay for status bar legibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.30),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientBox() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: _gradientColors,
            stops: _gradientStops,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );

  // ── Profile header (avatar overlaps hero) ──────────────
  Widget _buildProfileHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // white region behind name/category
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 54, 16, 16),
          color: _white,
          child: Column(
            children: [
              Text(w.name,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _black)),
              const SizedBox(height: 2),
              Text(w.category,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: _grey)),
            ],
          ),
        ),

        // avatar circle sitting over the hero
        Positioned(
          top: -45,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _white, width: 3),
                color: const Color(0xFFE6EAF7),
              ),
              child: ClipOval(
                child: w.profilePhotoUrl.isNotEmpty
                    ? Image.network(w.profilePhotoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.person,
                                size: 44, color: Color(0xFF677082)))
                    : const Icon(Icons.person,
                        size: 44, color: Color(0xFF677082)),
              ),
            ),
          ),
        ),

        // rating + distance – top-left
        Positioned(
          top: 10,
          left: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      color: Colors.amber, size: 14),
                  const SizedBox(width: 3),
                  Text(w.rating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: _grey)),
                ],
              ),
              const SizedBox(height: 2),
              Text('${(w.distanceKm * 1000).toStringAsFixed(0)}M away',
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: _grey)),
            ],
          ),
        ),

        // "Available" badge – top-right
        Positioned(
          top: 10,
          right: 18,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Available',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    color: _white,
                    fontWeight: FontWeight.w500)),
          ),
        ),
      ],
    );
  }

  // ── Bio paragraph ──────────────────────────────────────
  Widget _buildBio() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(29, 14, 29, 16),
      child: Text(
        _bioFor(w.category),
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          height: 1.8,
          color: _black,
        ),
      ),
    );
  }

  // ── Generic section with a bold title ──────────────────
  Widget _buildLabeledSection(
      {required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(29, 14, 29, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _black)),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }

  // ── Services & Pricing grey card ───────────────────────
  Widget _buildServicesCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      decoration: BoxDecoration(
        color: _bgGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text(
              'Services & Pricing',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _black),
            ),
          ),
          ..._services.asMap().entries.map((e) {
            final isLast = e.key == _services.length - 1;
            return Column(
              children: [
                Container(height: 1, color: _divider,
                    margin: const EdgeInsets.symmetric(horizontal: 24)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 44, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(e.value.name,
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                color: _grey)),
                      ),
                      Text(e.value.price,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: _grey)),
                    ],
                  ),
                ),
                if (isLast) const SizedBox(height: 6),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  // ── Reviews section ────────────────────────────────────
  Widget _buildReviewsSection() {
    final totalPages = (_reviews.length / _perPage).ceil();
    final start = _reviewPage * _perPage;
    final end   = (start + _perPage).clamp(0, _reviews.length);
    final visible = _reviews.sublist(start, end);

    return Padding(
      padding: const EdgeInsets.fromLTRB(29, 20, 29, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reviews',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _black)),
          const SizedBox(height: 10),
          // big star row
          Row(
            children: [
              ..._stars(w.rating, 18),
              const SizedBox(width: 8),
              Text(w.rating.toStringAsFixed(1),
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: _grey)),
            ],
          ),
          const SizedBox(height: 2),
          Text('${w.ratingCount} Reviews',
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: _grey)),
          const SizedBox(height: 10),

          ...visible.map(_buildReviewTile).toList(),

          if (totalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.chevron_left,
                      size: 20, color: _grey),
                  onPressed: _reviewPage > 0
                      ? () => setState(() => _reviewPage--)
                      : null,
                ),
                const SizedBox(width: 12),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.chevron_right,
                      size: 20, color: _grey),
                  onPressed: _reviewPage < totalPages - 1
                      ? () => setState(() => _reviewPage++)
                      : null,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildReviewTile(_Review r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: _divider),
        const SizedBox(height: 10),
        Row(
          children: [
            Row(children: _stars(r.rating, 10)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(r.reviewer,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: _grey)),
            ),
            Text(r.timeAgo,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: _grey)),
          ],
        ),
        const SizedBox(height: 6),
        Text(r.comment,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                height: 1.8,
                color: _black)),
        const SizedBox(height: 10),
      ],
    );
  }

  // ── Gradient "Request" button ──────────────────────────
  Widget _buildBottomButton(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: _white,
        padding: const EdgeInsets.fromLTRB(66, 12, 66, 28),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: const LinearGradient(
              colors: _gradientColors,
              stops: _gradientStops,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => _onRequest(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text('Request',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _white)),
            ),
          ),
        ),
      ),
    );
  }

  void _onRequest(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JobRequestPage(
          repository: _jobRequestRepository,
          workerId: w.id,
          workerName: w.name,
          workerCategory: w.category,
          workerPhotoUrl: w.profilePhotoUrl,
          workerAddress: w.address,
          workerRating: w.rating,
          distanceKm: w.distanceKm,
          services: _services
              .map((s) => {'name': s.name, 'price': s.price})
              .toList(),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────
  Widget _hline() => Container(height: 1, color: const Color(0xFFEEEEEE));

  List<Widget> _stars(double rating, double size) {
    return List.generate(5, (i) {
      final filled = i < rating.floor();
      final half   = !filled && i < rating && (rating - i) < 1;
      return Icon(
        half  ? Icons.star_half_rounded
              : filled ? Icons.star_rounded : Icons.star_border_rounded,
        size: size,
        color: Colors.amber[600],
      );
    });
  }

  // ── Content data helpers ────────────────────────────────
  String _bioFor(String cat) {
    const m = {
      'Mechanic':
          'Experienced automotive mechanic specializing in engine diagnostics, brake systems, suspension repairs, and routine vehicle maintenance. Skilled in working with both Japanese and European vehicles. Known for honest assessments, efficient service, and attention to detail. Committed to keeping vehicles safe, reliable, and running at peak performance.',
      'Plumber':
          'Professional plumber with expertise in pipe repairs, leak fixing, bathroom installations, and drainage systems. Fast response time and clean workmanship guaranteed.',
      'Electrician':
          'Licensed electrician offering full wiring, DB panel upgrades, and smart home installations. Known for safe, code-compliant work with zero shortcuts.',
      'Teacher':
          'Qualified private tutor specialising in Mathematics, Science and English. Patient, structured teaching style with a strong track record of exam improvement.',
      'Cleaner':
          'Professional cleaner with a keen eye for detail. Experienced in residential deep cleaning, regular maintenance cleans, and post-renovation cleans.',
      'Caregiver':
          'Compassionate caregiver with experience in elderly and child care. Reliable, patient, and trained in basic first aid.',
    };
    return m[cat] ??
        'Experienced ${cat.toLowerCase()} with a strong track record of quality work and satisfied customers.';
  }

  List<String> _certsFor(String cat) {
    const m = {
      'Mechanic':    ['ASE Certified Technician', 'Hybrid Vehicle Maintenance Certified'],
      'Plumber':     ['City & Guilds Plumbing Level 3'],
      'Electrician': ['NVQ Level 4 – Electrical Installation'],
      'Teacher':     ['B.Ed – University of Colombo', 'Cambridge CELTA Certified'],
      'Cleaner':     ['Professional Cleaning Certificate'],
      'Caregiver':   ['First Aid Certified', 'Caregiving NVQ Level 2'],
    };
    return m[cat] ?? ['Professionally Certified'];
  }

  String _expFor(String cat) {
    const m = {
      'Mechanic': '8+ years', 'Plumber': '5+ years',
      'Electrician': '10+ years', 'Teacher': '6+ years',
      'Cleaner': '4+ years', 'Caregiver': '3+ years',
    };
    return m[cat] ?? '5+ years';
  }

  List<_Service> _servicesFor(String cat) {
    const m = {
      'Mechanic': [
        _Service('Oil Change (Standard Service)',  'LKR 6,500 – 9,500'),
        _Service('Brake Pad Replacement (Front)',  'LKR 12,000 – 18,000'),
        _Service('Engine Diagnostics Scan',        'LKR 5,000'),
        _Service('Battery Replacement',            'LKR 3,500'),
        _Service('Wheel Alignment',                'LKR 4,500'),
        _Service('AC Service & Gas Refill',        'LKR 15,000 – 22,000'),
        _Service('Full Vehicle Inspection',        'LKR 7,500'),
      ],
      'Plumber': [
        _Service('Pipe Leak Repair',  'LKR 2,500 – 6,000'),
        _Service('Tap Replacement',   'LKR 1,500 – 3,000'),
        _Service('Drain Unblocking',  'LKR 3,000 – 5,000'),
        _Service('Toilet Repair',     'LKR 2,000 – 4,500'),
      ],
      'Electrician': [
        _Service('Wiring & Rewiring',     'LKR 8,000 – 25,000'),
        _Service('DB Box Installation',   'LKR 15,000 – 40,000'),
        _Service('Fan / Light Fitting',   'LKR 1,200 – 2,500'),
        _Service('Inverter Installation', 'LKR 5,000 – 12,000'),
      ],
      'Teacher': [
        _Service('Mathematics (Grade 6–11)', 'LKR 1,500 / hr'),
        _Service('Science (Grade 6–9)',      'LKR 1,500 / hr'),
        _Service('English (All levels)',     'LKR 1,200 / hr'),
        _Service('O/L Revision Package',     'LKR 8,000 / month'),
      ],
      'Cleaner': [
        _Service('Deep Clean',    'LKR 4,000 – 8,000'),
        _Service('Regular Clean', 'LKR 2,000 – 3,500'),
        _Service('Carpet Clean',  'LKR 3,000 – 5,000'),
        _Service('Window Clean',  'LKR 1,500 – 2,500'),
      ],
    };
    return m[cat] ?? [const _Service('General Service', 'On request')];
  }
}

// ═══════════════════════════════════════════════════════
//  PRIVATE DATA CLASSES
// ═══════════════════════════════════════════════════════

class _Review {
  final String reviewer;
  final double rating;
  final String timeAgo;
  final String comment;
  const _Review(this.reviewer, this.rating, this.timeAgo, this.comment);
}

class _Service {
  final String name;
  final String price;
  const _Service(this.name, this.price);
}
