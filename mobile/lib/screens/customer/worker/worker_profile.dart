import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../models/worker.dart';
import 'package:skillfox/screens/category_a/inspection_form_screen.dart';
import 'package:skillfox/screens/category_b/request_form_screen.dart';
import 'package:skillfox/screens/category_c/request_form_screen.dart';

class WorkerProfileScreen extends StatefulWidget {
  final Worker worker;
  const WorkerProfileScreen({super.key, required this.worker});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  Worker get w => widget.worker;

  Map<String, dynamic> _doc = {};
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;
  bool _reviewsLoading = true;

  int _page = 0;
  static const _perPage = 3;

  static const _grad = [
    Color(0xFF469FEF),
    Color(0xFF5C75F0),
    Color(0xFF6C56F0),
  ];
  static const _gradStop = [0.0, 0.258, 0.652];
  static const _ink = Color(0xFF000000);
  static const _muted = Color(0xFF727272);
  static const _cardBg = Color(0xFFF2F2F7);
  static const _lineA = Color(0xFFE8E8E8);
  static const _lineB = Color(0xFFE0E0E0);
  static const _white = Colors.white;
  static const _green = Color(0xFF27C840);

  static const _avatarDiameter = 90.0;
  static const _avatarOverlap = _avatarDiameter / 2;

  // ── Field readers ─────────────────────────────────────────────────
  String get _name => _str('name') ?? w.name;
  String get _jobType => _str('jobType') ?? w.category;
  String get _about => _str('about') ?? '';
  String get _experience => _str('experience') ?? '';
  String get _photo =>
      _str('profileImageUrl') ?? _str('profilePhotoUrl') ?? w.profilePhotoUrl;
  String get _coverPhoto => _str('coverPhotoUrl') ?? _photo;

  bool get _isAvailable => (_doc['isAvailable'] as bool?) ?? true;
  double get _rating =>
      (_doc['ratingAverage'] as num?)?.toDouble() ?? // users collection field
      (_doc['averageRating'] as num?)?.toDouble() ?? // workers collection field
      (_doc['rating'] as num?)?.toDouble() ?? // fallback
      w.rating;
  int get _ratingCount =>
      (_doc['ratingCount'] as num?)?.toInt() ?? // users collection field
      (_doc['totalReviews'] as num?)?.toInt() ?? // workers collection field
      w.ratingCount;

  bool get _hasOffer => (_doc['hasOffer'] as bool?) ?? w.hasOffer;
  String get _offerType => _str('offerType') ?? w.offerType;
  String get _offerDetails => _str('offerDetails') ?? w.offerDetails;
  double get _travelFee =>
      (_doc['travelFee'] as num?)?.toDouble() ?? w.travelFee;
  bool get _isFreeTravel => _offerType == 'Free Travel';

  // Firestore categoryType field (A / B / C).
  // Falls back to deriving from category name so existing workers
  // without the field still route correctly.
  String get _categoryType {
    final stored = (_doc['categoryType'] as String?)?.trim().toUpperCase();
    if (stored == 'A' || stored == 'B' || stored == 'C') return stored!;
    return _deriveCategoryType(w.category);
  }

  /// Derive the category type from the job name when the Firestore field
  /// is absent.  Extend these lists as your catalogue grows.
  static String _deriveCategoryType(String category) {
    const catC = {
      'teacher',
      'tutor',
      'caregiver',
      'care giver',
      'baby sitter',
      'babysitter',
      'nurse',
      'nanny',
    };
    const catB = {
      'cleaner',
      'cleaning',
      'handyman',
      'painter',
      'carpenter',
      'gardener',
      'pest control',
    };
    final lower = category.toLowerCase().trim();
    if (catC.contains(lower)) return 'C';
    if (catB.contains(lower)) return 'B';
    return 'A'; // default — inspection-based (plumber, electrician, mechanic, mason, etc.)
  }

  String? _str(String key) {
    final v = _doc[key]?.toString().trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  List<String> get _certUrls {
    final raw = _doc['certificationUrls'];
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  List<_Svc> get _services {
    final raw = _doc['services'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map(
            (m) => _Svc(
              name: (m['service'] as String? ?? '').trim(),
              price: 'LKR ${(m['price'] as String? ?? '').trim()}',
            ),
          )
          .where((s) => s.name.isNotEmpty)
          .toList();
    }
    return [];
  }

  int get _totalPages =>
      _reviews.isEmpty ? 0 : (_reviews.length / _perPage).ceil();

  List<Map<String, dynamic>> get _slice {
    if (_reviews.isEmpty) return [];
    final s = _page * _perPage;
    return _reviews.sublist(s, (s + _perPage).clamp(0, _reviews.length));
  }

  // ── Firestore loading ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadWorkerDoc();
  }

  Future<void> _loadWorkerDoc() async {
    final col = FirebaseFirestore.instance.collection('users');
    Map<String, dynamic>? found;
    String? foundId;

    try {
      final snap = await col
          .doc(w.id)
          .get(const GetOptions(source: Source.server));
      if (snap.exists && snap.data() != null) {
        found = snap.data()!;
        foundId = snap.id;
      }
    } catch (_) {}

    if (found == null) {
      try {
        final q = await col
            .where('uid', isEqualTo: w.id)
            .limit(1)
            .get(const GetOptions(source: Source.server));
        if (q.docs.isNotEmpty) {
          found = q.docs.first.data();
          foundId = q.docs.first.id;
        }
      } catch (_) {}
    }

    if (found == null && w.name.isNotEmpty) {
      try {
        final q = await col
            .where('name', isEqualTo: w.name)
            .limit(1)
            .get(const GetOptions(source: Source.server));
        if (q.docs.isNotEmpty) {
          found = q.docs.first.data();
          foundId = q.docs.first.id;
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _doc = found ?? {};
      _loading = false;
    });

    // _loadReviews queries the top-level 'reviews' collection by w.id
    // (the worker's Firebase Auth UID). foundId is not used for reviews.
    _loadReviews(foundId ?? '');
  }

  Future<void> _loadReviews(String docId) async {
    // The 'reviews' collection stores workerId = the worker's Firebase Auth UID.
    // review_screen.dart writes: 'workerId': requestData['workerId']
    // which is always the worker's UID — so w.id is the correct key to query by.
    // We must NOT fall back to docId (the users collection doc ID) because
    // that could accidentally match a different worker's reviews.
    try {
      final snap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('workerId', isEqualTo: w.id)
          .orderBy('createdAt', descending: true)
          .get(const GetOptions(source: Source.server));
      if (!mounted) return;
      setState(() {
        _reviews = snap.docs
            .map((d) => d.data() as Map<String, dynamic>)
            .toList();
        _reviewsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _reviewsLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFF),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 210,
                pinned: true,
                elevation: 0,
                backgroundColor: const Color(0xFF469FEF),
                automaticallyImplyLeading: false,
                leading: IconButton(
                  padding: const EdgeInsets.only(left: 6),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: _white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(_avatarOverlap),
                  child: Transform.translate(
                    offset: const Offset(0, _avatarOverlap),
                    child: Center(
                      child: Container(
                        width: _avatarDiameter,
                        height: _avatarDiameter,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE6EAF7),
                          border: Border.all(color: _white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _photo.isNotEmpty
                              ? Image.network(
                                  _photo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.person,
                                    size: 44,
                                    color: Color(0xFF677082),
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 44,
                                  color: Color(0xFF677082),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      _coverPhoto.isNotEmpty
                          ? Image.network(
                              _coverPhoto,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _gradBox(),
                            )
                          : _gradBox(),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.6],
                            colors: [
                              Colors.black.withOpacity(0.35),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _loading
                    ? const SizedBox(
                        height: 400,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _buildBody(),
              ),
            ],
          ),
          _buildRequestButton(context),
        ],
      ),
    );
  }

  Widget _gradBox() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: _grad,
        stops: _gradStop,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  );

  // ── Body ──────────────────────────────────────────────────────────
  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileHeader(),
        _hline(),

        if (_about.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(33, 14, 33, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _lbl('About'),
                const SizedBox(height: 6),
                Text(
                  _about,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    height: 1.82,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
          _hline(),
        ],

        if (_hasOffer) ...[_buildOfferSection(), _hline()],

        Padding(
          padding: const EdgeInsets.fromLTRB(33, 14, 33, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _lbl('Certification'),
              const SizedBox(height: 8),
              _certUrls.isEmpty
                  ? _ph('No certifications added.')
                  : SizedBox(
                      height: 88,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _certUrls.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (ctx, i) => GestureDetector(
                          onTap: () => _openCert(ctx, i),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              _certUrls[i],
                              width: 78,
                              height: 88,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, c, p) =>
                                  p == null ? c : _certBox(),
                              errorBuilder: (_, __, ___) => _certBox(),
                            ),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
        _hline(),

        Padding(
          padding: const EdgeInsets.fromLTRB(33, 14, 33, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _lbl('Experience'),
              const SizedBox(height: 4),
              _experience.isNotEmpty
                  ? Text(
                      _experience,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: _muted,
                      ),
                    )
                  : _ph('Not specified.'),
            ],
          ),
        ),
        _hline(),

        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'Services & Pricing',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
              ),
              if (_services.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(44, 0, 44, 16),
                  child: _ph('No services listed yet.'),
                )
              else
                ..._services.asMap().entries.map((e) {
                  final last = e.key == _services.length - 1;
                  return Column(
                    children: [
                      Container(
                        height: 1,
                        color: _lineB,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 44,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.value.name,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  color: _muted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              e.value.price,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (last) const SizedBox(height: 4),
                    ],
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 4),

        Padding(
          padding: const EdgeInsets.fromLTRB(29, 22, 29, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reviews',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ..._stars(_rating, 18),
                  const SizedBox(width: 8),
                  Text(
                    _rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: _muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '$_ratingCount Reviews',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: _muted,
                ),
              ),
              const SizedBox(height: 10),
              if (_reviewsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_reviews.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _ph('No reviews yet.'),
                )
              else ...[
                ..._slice.map(_buildReviewTile),
                if (_totalPages > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _pgBtn(
                        icon: Icons.chevron_left,
                        on: _page > 0,
                        fn: () => setState(() => _page--),
                      ),
                      const SizedBox(width: 8),
                      _pgBtn(
                        icon: Icons.chevron_right,
                        on: _page < _totalPages - 1,
                        fn: () => setState(() => _page++),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 110),
      ],
    );
  }

  // ── Offer section ─────────────────────────────────────────────────
  Widget _buildOfferSection() {
    final badgeColor = _isFreeTravel
        ? const Color(0xFF2E7D32)
        : const Color(0xFFE53935);
    final badgeBg = _isFreeTravel
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFEBEB);
    final borderColor = _isFreeTravel
        ? const Color(0xFFA5D6A7)
        : const Color(0xFFFFCDD2);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: badgeBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isFreeTravel
                        ? Icons.directions_car_outlined
                        : Icons.local_offer_rounded,
                    size: 16,
                    color: badgeColor,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _isFreeTravel ? 'Free Travel Offer' : 'Special Offer',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: borderColor),
            ),
            _OfferDetailRow(
              icon: Icons.directions_car_outlined,
              label: 'Travel Fee',
              value: _isFreeTravel
                  ? 'Free  (LKR 0)'
                  : 'LKR ${_travelFee.toStringAsFixed(0)}',
              valueColor: _isFreeTravel ? const Color(0xFF2E7D32) : _muted,
            ),
            if (!_isFreeTravel && _offerType.isNotEmpty) ...[
              const SizedBox(height: 8),
              _OfferDetailRow(
                icon: Icons.sell_outlined,
                label: 'Offer Type',
                value: _offerType,
                valueColor: badgeColor,
              ),
            ],
            if (_offerDetails.isNotEmpty) ...[
              const SizedBox(height: 8),
              _OfferDetailRow(
                icon: Icons.confirmation_num_outlined,
                label: 'Details',
                value: _offerDetails,
                valueColor: badgeColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Profile header ────────────────────────────────────────────────
  Widget _buildProfileHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          color: _white,
          padding: const EdgeInsets.fromLTRB(16, _avatarOverlap + 14, 16, 16),
          child: Column(
            children: [
              Text(
                _name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _jobType,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: _muted,
                ),
              ),
              // ── Category badge ──────────────────────────────────────
              const SizedBox(height: 8),
              _categoryBadge(_categoryType),
            ],
          ),
        ),
        Positioned(
          top: 10,
          left: 19,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                  const SizedBox(width: 3),
                  Text(
                    _rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: _muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                w.distanceKm < 1
                    ? '${(w.distanceKm * 1000).toStringAsFixed(0)}m away'
                    : '${w.distanceKm.toStringAsFixed(1)} km away',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 10,
          right: 19,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _isAvailable ? _green : const Color(0xFFAAAAAA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isAvailable ? 'Available' : 'Unavailable',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: _white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Small badge showing which category this worker belongs to
  Widget _categoryBadge(String type) {
    final Map<String, _BadgeStyle> styles = {
      'A': _BadgeStyle(
        label: 'Inspection Job',
        icon: Icons.search_rounded,
        bg: const Color(0xFFEFF6FF),
        fg: const Color(0xFF2563EB),
      ),
      'B': _BadgeStyle(
        label: 'One-time Job',
        icon: Icons.handyman_rounded,
        bg: const Color(0xFFECFDF5),
        fg: const Color(0xFF059669),
      ),
      'C': _BadgeStyle(
        label: 'Subscription',
        icon: Icons.repeat_rounded,
        bg: const Color(0xFFF3EEFF),
        fg: const Color(0xFF7C3AED),
      ),
    };
    final s = styles[type] ?? styles['B']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: 12, color: s.fg),
          const SizedBox(width: 5),
          Text(
            s.label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: s.fg,
            ),
          ),
        ],
      ),
    );
  }

  // ── Review tile ───────────────────────────────────────────────────
  // Fields from the top-level 'reviews' collection:
  //   customerName, rating, reviewText, createdAt, category
  Widget _buildReviewTile(Map<String, dynamic> r) {
    // Support both old subcollection field names and new top-level names
    final name =
        ((r['customerName'] as String?) ??
                (r['reviewerName'] as String?) ??
                'Customer')
            .trim();
    final rating = (r['rating'] as num? ?? 0).toDouble();
    final comment =
        ((r['reviewText'] as String?) ?? (r['comment'] as String?) ?? '')
            .trim();
    final category = (r['category'] as String? ?? '').trim();
    final time = _timeAgo(r['createdAt']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: _lineA),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer avatar initial
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF469FEF), Color(0xFF6C56F0)],
                ),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                          ),
                        ),
                      ),
                      Text(
                        time,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Row(children: _stars(rating, 11)),
                      if (category.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 8,
                              color: Color(0xFF6C56F0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (comment.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      comment,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        height: 1.6,
                        color: _ink,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _pgBtn({
    required IconData icon,
    required bool on,
    required VoidCallback fn,
  }) => GestureDetector(
    onTap: on ? fn : null,
    child: Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? const Color(0xFFF1F1F1) : const Color(0xFFEAEAEA),
      ),
      child: Icon(icon, size: 18, color: on ? _ink : _muted.withOpacity(0.35)),
    ),
  );

  // ── Request routing ───────────────────────────────────────────────
  void _openRequestFlow(BuildContext ctx) {
    // Worker must be available
    if (!_isAvailable) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('This worker is currently unavailable.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    switch (_categoryType) {
      case 'A':
        Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => InspectionFormScreen(worker: w)),
        );
        break;

      case 'B':
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => CategoryBRequestFormScreen(worker: w),
          ),
        );
        break;

      case 'C':
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => CategoryCRequestFormScreen(worker: w),
          ),
        );
        break;

      default:
        // Fallback — default to Cat A inspection flow
        Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => InspectionFormScreen(worker: w)),
        );
    }
  }

  // ── Sticky request button ─────────────────────────────────────────
  Widget _buildRequestButton(BuildContext ctx) {
    // Tint the button to match the worker's category
    final List<Color> btnColors = switch (_categoryType) {
      'A' => const [Color(0xFF469FEF), Color(0xFF6C56F0)],
      'B' => const [Color(0xFF10B981), Color(0xFF059669)],
      'C' => const [Color(0xFF8B5CF6), Color(0xFF6C56F0)],
      _ => const [Color(0xFF469FEF), Color(0xFF6C56F0)],
    };

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: _white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(66, 12, 66, 28),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: btnColors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () => _openRequestFlow(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'Request',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Cert viewer ───────────────────────────────────────────────────
  void _openCert(BuildContext ctx, int initial) {
    showDialog(
      context: ctx,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initial),
              itemCount: _certUrls.length,
              itemBuilder: (_, i) => InteractiveViewer(
                child: Center(
                  child: Image.network(_certUrls[i], fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 44,
              right: 14,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.close, color: _white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────
  Widget _hline() => Container(height: 1, color: _lineA);

  Widget _lbl(String t) => Text(
    t,
    style: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: _ink,
    ),
  );

  Widget _ph(String t) => Text(
    t,
    style: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 10,
      color: _muted.withOpacity(0.6),
      fontStyle: FontStyle.italic,
    ),
  );

  Widget _certBox() => Container(
    width: 78,
    height: 88,
    decoration: BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(
      Icons.image_not_supported_outlined,
      color: _muted,
      size: 26,
    ),
  );

  List<Widget> _stars(double r, double size) => List.generate(5, (i) {
    final filled = i < r.floor();
    final half = !filled && i < r;
    return Icon(
      half
          ? Icons.star_half_rounded
          : filled
          ? Icons.star_rounded
          : Icons.star_border_rounded,
      size: size,
      color: Colors.amber[600],
    );
  });

  String _timeAgo(dynamic ts) {
    if (ts is! Timestamp) return '';
    final d = DateTime.now().difference(ts.toDate());
    if (d.inSeconds < 60) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24)
      return '${d.inHours} ${d.inHours == 1 ? "hour" : "hours"} ago';
    if (d.inDays < 7)
      return '${d.inDays} ${d.inDays == 1 ? "day" : "days"} ago';
    if (d.inDays < 30) return '${(d.inDays / 7).floor()} weeks ago';
    if (d.inDays < 365) return '${(d.inDays / 30).floor()} months ago';
    return '${(d.inDays / 365).floor()} years ago';
  }
}

// ── Badge style helper ────────────────────────────────────────────────────────
class _BadgeStyle {
  final String label;
  final IconData icon;
  final Color bg, fg;
  const _BadgeStyle({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
  });
}

// ── Offer Detail Row ──────────────────────────────────────────────────────────
class _OfferDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _OfferDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: valueColor.withOpacity(0.7)),
        const SizedBox(width: 7),
        Text(
          '$label:',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            color: Color(0xFF727272),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _Svc {
  final String name, price;
  const _Svc({required this.name, required this.price});
}
