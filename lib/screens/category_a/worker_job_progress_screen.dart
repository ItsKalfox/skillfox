// ════════════════════════════════════════════════════════════════════════════
//  lib/screens/category_a/waiting_worker_screen.dart
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'payment_options_screen.dart';
import '../../models/worker.dart';
import 'worker_job_progress_screen.dart';

// ─── Palette ─────────────────────────────────────────────────────────────────
class _C {
  static const gradA      = Color(0xFF469FEF);
  static const gradB      = Color(0xFF6C56F0);
  static const accent     = Color(0xFF6C56F0);
  static const bg         = Color(0xFFF4F6FA);
  static const cardBorder = Color(0xFFE2E6F0);
  static const txt1       = Color(0xFF111111);
  static const txt2       = Color(0xFF888888);
  static const muted      = Color(0xFFA0A4B0);
  static const green      = Color(0xFF16A34A);
  static const greenDark  = Color(0xFF1E8449);
  static const orange     = Color(0xFFEA580C);
  static const blue       = Color(0xFF2563EB);
  static const star       = Color(0xFFF59E0B);
  static const chip       = Color(0xFFEEF0F8);
  static const reject     = Color(0xFFEF4444);
}

// ════════════════════════════════════════════════════════════════════════════
class WorkerJobProgressScreen extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const WorkerJobProgressScreen({
    super.key,
    required this.requestId,
    required this.requestData,
  });

  @override
  State<WorkerJobProgressScreen> createState() =>
      _WorkerJobProgressScreenState();
}
class _WorkerJobProgressScreenState extends State<WorkerJobProgressScreen>
    with TickerProviderStateMixin {

  int _stage = 0;
  Map<String, dynamic> _data = {};
  StreamSubscription<DocumentSnapshot>? _sub;

  // animations
  late AnimationController _spinCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  // map (stage 4)
  GoogleMapController? _mapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSub;

  // panel button loading state
  bool _panelLoading = false;

  // ── init ──────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0, end: 10)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _listenToRequest();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _positionSub?.cancel();
    _spinCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Firestore listener ────────────────────────────────────────────────────
  void _listenToRequest() {
    final id = widget.requestId;
    if (id.isEmpty) return;

    _sub = FirebaseFirestore.instance
        .collection('requests')
        .doc(id)
        .snapshots()
        .listen((snap) {
      if (!snap.exists || !mounted) return;
      final d = snap.data() as Map<String, dynamic>;
      final prevStage = _stage;
      setState(() {
        _data = {...d, 'id': id};
        _setStageFromStatus(d['status'] as String? ?? 'pending');
      });
      // Start location tracking when entering stage 4
      if (prevStage < 4 && _stage == 4) _startLocationTracking();
    });
  }

  void _setStageFromStatus(String status) {
    switch (status) {
      case 'accepted':   _stage = 2; break;
      case 'payment':    _stage = 3; break;
      case 'inprogress': _stage = 4; break;
      case 'pending':
      default:
        if (_stage < 1) _stage = 1;
    }
  }

  // ── Location tracking for stage 4 ─────────────────────────────────────────
  Future<void> _startLocationTracking() async {
    if (_positionSub != null) return;
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }
      if (perm == LocationPermission.deniedForever) return;

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((pos) {
        if (!mounted) return;
        setState(() => _currentPosition = pos);
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
        );
      });
    } catch (_) {}
  }

  // ── Computed ──────────────────────────────────────────────────────────────
  String get _requestId => widget.requestId;

  bool get _arcSpin  => _stage == 1 || _stage == 4;
  bool get _doPulse  => _stage == 1 || _stage == 2 || _stage == 4;
  bool get _showDots => _stage == 1 || _stage == 4;

  String get _stageTitle {
    const t = ['Submitted', 'Waiting for Worker…', 'Worker Accepted!', 'Payment Required', 'Work In Progress'];
    return t[_stage.clamp(0, 4)];
  }

  String get _stageSub {
    final name = _data['workerName'] as String? ?? 'The worker';
    switch (_stage) {
      case 0: return 'Request submitted successfully.';
      case 1: return 'Your request has been sent to nearby workers. Hang tight!';
      case 2: return '$name has accepted your request and is on the way.';
      case 3: return 'Review your bill and complete payment to proceed.';
      case 4: return 'Your worker is currently working on your task.';
      default: return '';
    }
  }

  Color get _badgeColor {
    switch (_stage) {
      case 2: return const Color(0xFFFFF7ED);
      case 3: return const Color(0xFFECFDF5);
      case 4: return const Color(0xFFEFF6FF);
      default: return const Color(0xFFEEF2FF);
    }
  }

  Color get _badgeTxtColor {
    switch (_stage) {
      case 2: return _C.orange;
      case 3: return _C.green;
      case 4: return _C.blue;
      default: return _C.accent;
    }
  }

  String get _badgeTxt {
    const l = ['● Submitted', '● Waiting', '● Accepted', '● Payment', '● In Progress'];
    return l[_stage.clamp(0, 4)];
  }

  IconData get _blobIcon {
    switch (_stage) {
      case 1: return Icons.chat_bubble_outline_rounded;
      case 3: return Icons.credit_card_rounded;
      case 4: return Icons.build_rounded;
      default: return Icons.check_rounded;
    }
  }

  // ── Bill calculation ──────────────────────────────────────────────────────
  num get _inspectionFee  => (_data['inspectionFee'] as num?) ?? 1500;
  num get _distanceFee    => (_data['distanceFee']   as num?) ?? (_data['travelFee'] as num?) ?? 500;
  num get _serviceFee     => ((_inspectionFee + _distanceFee) * 0.05).round();
  num get _totalAmount    => _inspectionFee + _distanceFee + _serviceFee;

  String _fmt(num n) {
    final s = n.toStringAsFixed(0);
    final r = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) r.write(',');
      r.write(s[i]);
    }
    return r.toString();
  }

  // ── Proceed to Payment (Panel button at stage 2) ──────────────────────────
  // Updates Firestore status to 'payment' which triggers stage 3 via listener.
  Future<void> _proceedToPayment() async {
    if (_panelLoading) return;
    setState(() => _panelLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(_requestId)
          .update({'status': 'payment'});
      // Firestore listener will auto-advance _stage to 3
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: _C.reject,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _panelLoading = false);
    }
  }

  // ── Cancel request ────────────────────────────────────────────────────────
  // Writes 'cancelled' to Firestore, then pops all routes back to the first
  // route (home screen) and shows a success snackbar there.
  Future<void> _handleCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Cancel Request',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to cancel this request?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _C.reject),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      if (_requestId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('requests')
            .doc(_requestId)
            .update({'status': 'cancelled', 'cancelledBy': 'customer'});
      }
      if (!mounted) return;

      // Navigate all the way back to the home screen (first route in stack)
      Navigator.of(context).popUntil((route) => route.isFirst);

      // Show success snackbar on the home screen after returning
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Request cancelled successfully.',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to cancel: $e'),
          backgroundColor: _C.reject,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  _buildHero(),
                  _buildStepBar(),
                  _buildSummaryCard(),
                  if (_stage >= 2) _buildWorkerCard(),
                  // Bill shown at stage 2 (Accepted) AND stage 3 (Payment)
                  if (_stage >= 2) _buildBillCard(),
                  if (_stage >= 4) _buildMapSection(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Container(
        color: Colors.white,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 4,
          bottom: 12, left: 16, right: 16,
        ),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                  color: Color(0xFFF0F2F8), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 14, color: Color(0xFF444444)),
            ),
          ),
          const SizedBox(width: 12),
          const Text('Request Status',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: _C.txt1)),
        ]),
      );

  // ── Hero ──────────────────────────────────────────────────────────────────
  Widget _buildHero() => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
        child: Column(children: [
          SizedBox(
            width: 100, height: 100,
            child: Stack(alignment: Alignment.center, children: [
              AnimatedBuilder(
                animation: _spinCtrl,
                builder: (_, __) => CustomPaint(
                  size: const Size(100, 100),
                  painter: _ArcPainter(
                    progress: _arcSpin ? null : (_stage / 4.0),
                    spinning: _arcSpin,
                    spinValue: _spinCtrl.value,
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Container(
                  width: 58, height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _stage == 3
                          ? [const Color(0xFF27AE60), _C.greenDark]
                          : [_C.gradA, _C.gradB],
                    ),
                    boxShadow: _doPulse
                        ? [BoxShadow(
                            color: (_stage == 3 ? _C.green : _C.accent)
                                .withOpacity(0.35),
                            blurRadius: _pulseAnim.value,
                            spreadRadius: _pulseAnim.value * 0.3,
                          )]
                        : [],
                  ),
                  child: Icon(_blobIcon, color: Colors.white, size: 24),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _badgeColor, borderRadius: BorderRadius.circular(20)),
            child: Text(_badgeTxt,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _badgeTxtColor)),
          ),
          const SizedBox(height: 8),
          Text(_stageTitle,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600, color: _C.txt1)),
          const SizedBox(height: 4),
          Text(_stageSub,
              textAlign: TextAlign.center, maxLines: 2,
              style: const TextStyle(
                  fontSize: 11, color: _C.txt2, height: 1.7)),
          const SizedBox(height: 12),
          if (_showDots)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _BounceDot(delayMs: i * 200)),
            ),
        ]),
      );

  // ── Step bar ──────────────────────────────────────────────────────────────
  Widget _buildStepBar() {
    const labels = ['Submitted', 'Waiting', 'Accepted', 'Payment', 'Progress'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          final isDone   = i < _stage;
          final isActive = i == _stage;
          return Row(mainAxisSize: MainAxisSize.min, children: [
            Column(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 24, height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: (isDone || isActive)
                      ? const LinearGradient(colors: [_C.gradA, _C.gradB])
                      : null,
                  color: (isDone || isActive) ? null : const Color(0xFFE8EAF0),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                      : Text('${i + 1}',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.white : const Color(0xFFAAAAAA))),
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                width: 42,
                child: Text(labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 7.5,
                        color: isDone ? _C.gradA : isActive ? _C.accent : _C.muted,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
              ),
            ]),
            if (i < 4)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 20, height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  gradient: isDone ? const LinearGradient(colors: [_C.gradA, _C.gradB]) : null,
                  color: isDone ? null : const Color(0xFFE2E6F0),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ]);
        }),
      ),
    );
  }

  // ── Summary card ──────────────────────────────────────────────────────────
  Widget _buildSummaryCard() {
    final category = _data['category'] as String? ?? '—';
    final shortId  = _requestId.length >= 8
        ? _requestId.substring(0, 8).toUpperCase()
        : _requestId.toUpperCase();

    String estLabel, estVal; Color estColor;
    String statusTxt;        Color statusColor;

    switch (_stage) {
      case 1:
        estLabel = 'Est. Response'; estVal = '~5 – 10 min'; estColor = _C.accent;
        statusTxt = 'Pending';         statusColor = _C.accent; break;
      case 2:
        estLabel = 'Worker ETA';   estVal = '~8 min';       estColor = _C.orange;
        statusTxt = 'Accepted';        statusColor = _C.orange; break;
      case 3:
        estLabel = 'Worker ETA';   estVal = 'Arrived';      estColor = _C.green;
        statusTxt = 'Payment Pending'; statusColor = _C.green;  break;
      case 4:
        estLabel = 'Work Status';  estVal = 'In Progress';  estColor = _C.blue;
        statusTxt = 'In Progress';     statusColor = _C.blue;   break;
      default:
        estLabel = 'Est. Response'; estVal = 'Calculating…'; estColor = _C.accent;
        statusTxt = 'Submitted';        statusColor = _C.accent;
    }

    return _SumCard(
      title: _stage >= 3 ? 'SERVICE SUMMARY' : 'REQUEST SUMMARY',
      rows: [
        _SumRow(label: 'Request ID', value: '#$shortId'),
        _SumRow(label: 'Category',   value: category),
        _SumRow(label: estLabel,     value: estVal,    valueColor: estColor),
        if (_stage >= 2)
          _SumRow(label: 'Worker',
              value: _data['workerName'] as String? ?? '—'),
        if (_stage >= 1)
          _SumRow(label: 'Status', value: statusTxt, valueColor: statusColor),
      ],
    );
  }

  // ── Worker card ───────────────────────────────────────────────────────────
  Widget _buildWorkerCard() {
    final name     = _data['workerName'] as String? ?? 'Worker';
    final category = _data['category']   as String? ?? '';
    final initials = name.trim().split(' ')
        .map((p) => p.isNotEmpty ? p[0] : '')
        .take(2).join().toUpperCase();
    final rating   = (_data['workerRating'] as num?)?.toDouble() ?? 4.5;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.cardBorder, width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [_C.gradA, _C.gradB]),
          ),
          child: Center(
            child: Text(initials,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: _C.txt1)),
            Text(category,
                style: const TextStyle(fontSize: 10, color: _C.txt2)),
          ]),
        ),
        Row(children: [
          const Icon(Icons.star_rounded, size: 14, color: _C.star),
          const SizedBox(width: 3),
          Text(rating.toStringAsFixed(1),
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: _C.star)),
        ]),
      ]),
    );
  }

  // ── Bill card ─────────────────────────────────────────────────────────────
  // Shown at stage 2 (Accepted) and stage 3 (Payment).
  // At stage 2 the "Proceed to Payment" panel button appears below.
  Widget _buildBillCard() => Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.cardBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(
                _stage == 2
                    ? Icons.receipt_outlined
                    : Icons.receipt_long_outlined,
                size: 14,
                color: _stage == 2 ? _C.orange : _C.green,
              ),
              const SizedBox(width: 6),
              Text(
                'ESTIMATED BILL',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _C.muted,
                    letterSpacing: 0.5),
              ),
              if (_stage == 2) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Preview',
                      style: TextStyle(
                          fontSize: 9,
                          color: _C.orange,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ]),
            const SizedBox(height: 10),
            _billRow('Inspection Fee',   _inspectionFee),
            _billRow('Distance Fee',     _distanceFee),
            _billRow('Service Fee (5%)', _serviceFee),
            const Divider(height: 16, color: _C.cardBorder, thickness: 1.5),
            Row(children: [
              const Expanded(
                  child: Text('Total',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _C.txt1))),
              Text('LKR ${_fmt(_totalAmount)}',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _stage == 2 ? _C.orange : _C.accent)),
            ]),
          ],
        ),
      );

  Widget _billRow(String label, num amount) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 11, color: _C.txt2))),
          Text('LKR ${_fmt(amount)}',
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500, color: _C.txt1)),
        ]),
      );

  // ── Map section (stage 4) ─────────────────────────────────────────────────
  Widget _buildMapSection() {
    final customerLat = (_data['latitude']  as num?)?.toDouble() ?? 0.0;
    final customerLng = (_data['longitude'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.cardBorder, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.location_on, size: 14, color: _C.accent),
          SizedBox(width: 6),
          Text('LIVE LOCATION',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _C.muted,
                  letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 240,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition != null
                    ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                    : LatLng(customerLat, customerLng),
                zoom: 15,
              ),
              onMapCreated: (c) => _mapController = c,
              markers: {
                Marker(
                  markerId: const MarkerId('customer'),
                  position: LatLng(customerLat, customerLng),
                  infoWindow: const InfoWindow(title: 'Job Location', snippet: 'Customer'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
                ),
                if (_currentPosition != null)
                  Marker(
                    markerId: const MarkerId('worker'),
                    position: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    infoWindow: const InfoWindow(title: 'Your Worker', snippet: 'Live location'),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                  ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          _dotLegend(_C.gradB, 'Job Location'),
          const SizedBox(width: 16),
          _dotLegend(_C.gradA, 'Worker (Live)'),
        ]),
      ]),
    );
  }

  Widget _dotLegend(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 10, color: _C.txt2)),
        ],
      );

  // ── Bottom bar ────────────────────────────────────────────────────────────
  Widget _buildBottomBar() => Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(
            16, 14, 16, MediaQuery.of(context).padding.bottom + 20),
        child: _stage == 2
            // ── Stage 2: "Proceed to Payment" panel button ──
            ? _gradBtn(
                label: _panelLoading
                    ? 'Please wait…'
                    : 'Proceed to Payment  —  LKR ${_fmt(_totalAmount)}',
                colors: [_C.orange, const Color(0xFFD14A08)],
                onTap: _panelLoading ? null : _proceedToPayment,
                leading: _panelLoading
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
              )
            : _stage == 3
                // ── Stage 3: "Pay Now" button ──
                ? _gradBtn(
                    label: 'Pay Now  —  LKR ${_fmt(_totalAmount)}',
                    colors: [const Color(0xFF27AE60), _C.greenDark],
                    onTap: _openPaymentOptions,
                    leading: const Icon(Icons.credit_card_rounded,
                        color: Colors.white, size: 18),
                  )
                : _stage == 4
                    // ── Stage 4: Live tracking hint ──
                    ? _gradBtn(
                        label: 'View Live Tracking',
                        colors: [_C.gradA, _C.gradB],
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Map is shown above ↑'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        leading: const Icon(Icons.location_on_rounded,
                            color: Colors.white, size: 18),
                      )
                    // ── Stage 0/1: Cancel button ──
                    : _outlineBtn(
                        label: 'Cancel Request',
                        onTap: _handleCancel,
                      ),
      );

  // ── Open PaymentOptionsScreen ─────────────────────────────────────────────
  // PaymentOptionsScreen handles the full payment flow. On payment confirmation
  // it must write to Firestore:  requests/{requestId} → { status: 'inprogress' }
  // then call Navigator.pop(context).
  //
  // The Firestore stream listener (_listenToRequest) automatically picks up
  // 'inprogress' and advances _stage → 4 (Work In Progress). No extra code needed.
  Future<void> _openPaymentOptions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentOptionsScreen(
          requestId:     _requestId,
          totalAmount:   _totalAmount,
          inspectionFee: _inspectionFee,
          distanceFee:   _distanceFee,
        ),
      ),
    );
    // After pop: Firestore listener fires if status changed → _stage auto-updates.
  }

  Widget _gradBtn({
    required String label,
    required List<Color> colors,
    required VoidCallback? onTap,
    Widget? leading,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: onTap == null ? 0.6 : 1.0,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leading != null) ...[leading, const SizedBox(width: 8)],
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );

  Widget _outlineBtn({
    required String label,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _C.cardBorder, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _C.txt2)),
          ),
        ),
      );
}

// ════════════════════════════════════════════════════════════════════════════
//  Helpers
// ════════════════════════════════════════════════════════════════════════════

class _SumRow {
  final String label, value;
  final Color? valueColor;
  const _SumRow({required this.label, required this.value, this.valueColor});
}

class _SumCard extends StatelessWidget {
  final String title;
  final List<_SumRow> rows;
  const _SumCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.cardBorder, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _C.muted,
                  letterSpacing: 0.5)),
          const SizedBox(height: 10),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Expanded(
                      child: Text(r.label,
                          style: const TextStyle(fontSize: 11, color: _C.txt2))),
                  Text(r.value,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: r.valueColor ?? _C.txt1)),
                ]),
              )),
        ]),
      );
}

// ── Arc painter ───────────────────────────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  final double? progress;
  final bool spinning;
  final double spinValue;

  const _ArcPainter({
    this.progress,
    required this.spinning,
    required this.spinValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const cx = 50.0; const cy = 50.0;
    const r  = 43.0; const sw = 5.0;

    canvas.drawCircle(
      const Offset(cx, cy), r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..color = const Color(0xFFE8E6F8),
    );

    final grad = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(colors: [_C.gradA, _C.gradB])
          .createShader(Rect.fromCircle(
              center: const Offset(cx, cy), radius: r));

    if (spinning) {
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(cx, cy), radius: r),
        spinValue * 2 * math.pi,
        math.pi * 1.4,
        false, grad,
      );
    } else {
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(cx, cy), radius: r),
        -math.pi / 2,
        2 * math.pi * (progress ?? 1.0),
        false, grad,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter o) => true;
}

// ── Bouncing dot ──────────────────────────────────────────────────────────────
class _BounceDot extends StatefulWidget {
  final int delayMs;
  const _BounceDot({required this.delayMs});
  @override
  State<_BounceDot> createState() => _BounceDotState();
}

class _BounceDotState extends State<_BounceDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = Tween<double>(begin: 0, end: -6)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _anim.value),
          child: Container(
            width: 7, height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [_C.gradA, _C.gradB]),
            ),
          ),
        ),
      );
}
