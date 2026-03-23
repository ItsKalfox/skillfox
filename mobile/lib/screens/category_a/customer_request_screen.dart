import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/worker.dart';

class _C {
  static const gradA   = Color(0xFF469FEF);
  static const gradB   = Color(0xFF6C56F0);
  static const accent  = Color(0xFF6C56F0);
  static const bg      = Color(0xFFF4F6FA);
  static const cardBdr = Color(0xFFE2E6F0);
  static const txt1    = Color(0xFF111111);
  static const txt2    = Color(0xFF888888);
  static const muted   = Color(0xFFA0A4B0);
  static const green   = Color(0xFF16A34A);
  static const greenDk = Color(0xFF1E8449);
  static const orange  = Color(0xFFEA580C);
  static const blue    = Color(0xFF2563EB);
  static const star    = Color(0xFFF59E0B);
  static const red     = Color(0xFFEF4444);
  static const redBg   = Color(0xFFFEF2F2);
  static const redBdr  = Color(0xFFFECACA);
}

class CustomerRequestScreen extends StatefulWidget {
  final String  requestId;
  final Worker? worker;

  const CustomerRequestScreen({
    super.key,
    required this.requestId,
    this.worker,
  });

  @override
  State<CustomerRequestScreen> createState() => _CustomerRequestScreenState();
}

class _CustomerRequestScreenState extends State<CustomerRequestScreen>
    with TickerProviderStateMixin {

  int  _stage    = 0;
  bool _rejected = false;
  Map<String, dynamic> _data = {};

  StreamSubscription<DocumentSnapshot>? _reqSub;
  StreamSubscription<DocumentSnapshot>? _workerLocSub;

  late AnimationController _spinCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  GoogleMapController? _mapCtrl;
  LatLng? _workerLatLng;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0, end: 10).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _listenToRequest();
  }

  @override
  void dispose() {
    _reqSub?.cancel();
    _workerLocSub?.cancel();
    _spinCtrl.dispose();
    _pulseCtrl.dispose();
    _mapCtrl?.dispose();
    super.dispose();
  }

  void _listenToRequest() {
    _reqSub = FirebaseFirestore.instance
        .collection('requests')
        .doc(widget.requestId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists || !mounted) return;
      final d = Map<String, dynamic>.from(snap.data()!);
      d['id'] = snap.id;
      setState(() {
        _data = d;
        _applyStatus(d['status'] as String? ?? 'pending');
      });
    });
  }

  void _applyStatus(String status) {
    switch (status) {
      case 'pending':
        _rejected = false;
        if (_stage < 1) _stage = 1;
        break;
      case 'accepted':
        _rejected = false;
        _stage = 2;
        break;
      case 'rejected':
        _rejected = true;
        _stage = 1;
        break;
      case 'inprogress':
        _rejected = false;
        _stage = 3;
        _startWorkerTracking();
        break;
      case 'arrived':
        _rejected = false;
        _stage = 3;
        _startWorkerTracking();
        break;
      case 'completed':
        _rejected = false;
        _stage = 4;
        break;
      case 'quotation_sent':
        _rejected = false;
        _stage = 4;
        break;
      case 'cancelled':
        break;
    }
  }

  void _startWorkerTracking() {
    final workerId = _data['workerId'] as String?;
    if (workerId == null || _workerLocSub != null) return;
    _workerLocSub = FirebaseFirestore.instance
        .collection('workers')
        .doc(workerId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists || !mounted) return;
      final d   = snap.data()!;
      final lat = (d['currentLat'] as num?)?.toDouble();
      final lng = (d['currentLng'] as num?)?.toDouble();
      if (lat == null || lng == null) return;
      setState(() => _workerLatLng = LatLng(lat, lng));
      _mapCtrl?.animateCamera(CameraUpdate.newLatLng(_workerLatLng!));
    });
  }

  static const double _kInspectionFee = 1500.0;
  double get _inspectionFee => _kInspectionFee;
  double get _distanceFee {
    final stored = (_data['distanceFee'] as num?) ?? (_data['travelFee'] as num?);
    if (stored != null && stored > 0) return stored.toDouble();
    var km = (_data['distanceKm'] as num?)?.toDouble() ?? 0.0;
    if (km > 500) km = km / 1000;
    final fee = (km * 50).roundToDouble();
    return fee.clamp(100.0, 3000.0);
  }
  double get _serviceFee => ((_inspectionFee + _distanceFee) * 0.05).roundToDouble();
  double get _totalAmount => _inspectionFee + _distanceFee + _serviceFee;

  String _fmt(num n) {
    final s = n.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  bool get _arcSpin  => (_stage == 0 || _stage == 1) && !_rejected;
  bool get _showDots => _arcSpin;

  String get _stageTitle {
    if (_rejected) return 'Request Declined';
    final status = _data['status'] as String? ?? '';
    if (status == 'arrived') return 'Worker Has Arrived!';
    if (status == 'quotation_sent') return 'Quotation Received';
    const t = ['Submitted', 'Waiting for Worker…', 'Worker Accepted!', 'Work In Progress', 'Inspection Completed'];
    return t[_stage.clamp(0, 4)];
  }

  String get _stageSub {
    if (_rejected) return 'The worker has declined this inspection request.';
    final name   = _data['workerName'] as String? ?? 'The worker';
    final status = _data['status']     as String? ?? '';
    switch (_stage) {
      case 0: return 'Request submitted successfully.';
      case 1: return 'Your request has been sent to nearby workers. Hang tight!';
      case 2: return '$name accepted your request. Review the bill below and proceed to payment.';
      case 3: return status == 'arrived'
          ? '$name has arrived at your location. Work has started!'
          : 'Payment confirmed. Your worker is on the way!';
      case 4: return status == 'quotation_sent'
          ? 'The worker has sent you a quotation. Please review it below.'
          : 'The inspection has been completed. Thank you!';
      default: return '';
    }
  }

  Color get _badgeColor {
    if (_rejected) return _C.redBg;
    switch (_stage) {
      case 2: return const Color(0xFFFFF7ED);
      case 3: return const Color(0xFFEFF6FF);
      case 4: return const Color(0xFFECFDF5);
      default: return const Color(0xFFEEF2FF);
    }
  }

  Color get _badgeTxtColor {
    if (_rejected) return _C.red;
    switch (_stage) {
      case 2: return _C.orange;
      case 3: return _C.blue;
      case 4: return _C.green;
      default: return _C.accent;
    }
  }

  String get _badgeTxt {
    if (_rejected) return '● Declined by Worker';
    final status = _data['status'] as String? ?? '';
    if (status == 'arrived') return '● Worker Arrived';
    if (status == 'quotation_sent') return '● Quotation Received';
    const l = ['● Submitted', '● Waiting', '● Accepted', '● In Progress', '● Completed'];
    return l[_stage.clamp(0, 4)];
  }

  IconData get _blobIcon {
    if (_rejected) return Icons.close_rounded;
    final status = _data['status'] as String? ?? '';
    if (status == 'arrived') return Icons.directions_walk_rounded;
    if (status == 'quotation_sent') return Icons.receipt_long_rounded;
    switch (_stage) {
      case 1: return Icons.chat_bubble_outline_rounded;
      case 2: return Icons.check_circle_outline_rounded;
      case 3: return Icons.build_rounded;
      case 4: return Icons.verified_rounded;
      default: return Icons.check_rounded;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _C.bg,
        body: Column(children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(children: [
                _buildHero(),
                _buildStepBar(),
                if (_rejected) _buildRejectionBanner(),
                if (_stage == 3 && _data['status'] == 'arrived') _buildArrivedBanner(),
                if (_stage == 4 && _data['status'] == 'quotation_sent') _buildQuotationBanner(),
                _buildSummaryCard(),
                if (_stage >= 2 && !_rejected) _buildWorkerCard(),
                if (_stage >= 2 && !_rejected) _buildBillCard(),
                if (_stage >= 3) _buildPaymentBadge(),
                if (_stage == 3) _buildMapSection(),
                if (_stage == 4 && _data['status'] != 'quotation_sent') _buildCompletedCard(),
              ]),
            ),
          ),
          _buildBottomBar(),
        ]),
      );

  Widget _buildHeader() => Container(
        color: Colors.white,
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 4, bottom: 12, left: 16, right: 16),
        child: Row(children: [
          GestureDetector(onTap: () => Navigator.pop(context),
              child: Container(width: 32, height: 32, decoration: const BoxDecoration(color: Color(0xFFF0F2F8), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Color(0xFF444444)))),
          const SizedBox(width: 12),
          const Text('Request Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _C.txt1)),
        ]),
      );

  Widget _buildHero() => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
        child: Column(children: [
          SizedBox(width: 100, height: 100,
            child: Stack(alignment: Alignment.center, children: [
              AnimatedBuilder(animation: _spinCtrl, builder: (_, __) => CustomPaint(
                size: const Size(100, 100),
                painter: _ArcPainter(progress: _arcSpin ? null : (_stage / 4.0), spinning: _arcSpin, spinValue: _spinCtrl.value, rejected: _rejected, completed: _stage == 4),
              )),
              AnimatedBuilder(animation: _pulseAnim, builder: (_, __) => Container(
                width: 58, height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: _rejected ? [_C.red, const Color(0xFFDC2626)] : _stage == 4 ? [_C.green, _C.greenDk] : [_C.gradA, _C.gradB]),
                  boxShadow: (!_rejected && _stage < 4) ? [BoxShadow(color: _C.accent.withOpacity(0.35), blurRadius: _pulseAnim.value, spreadRadius: _pulseAnim.value * 0.3)] : [],
                ),
                child: Icon(_blobIcon, color: Colors.white, size: 24),
              )),
            ]),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: _badgeColor, borderRadius: BorderRadius.circular(20),
                border: _rejected ? Border.all(color: _C.redBdr, width: 0.5) : null),
            child: Text(_badgeTxt, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _badgeTxtColor)),
          ),
          const SizedBox(height: 8),
          Text(_stageTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _C.txt1)),
          const SizedBox(height: 4),
          Text(_stageSub, textAlign: TextAlign.center, maxLines: 3, style: const TextStyle(fontSize: 11, color: _C.txt2, height: 1.7)),
          const SizedBox(height: 12),
          if (_showDots) Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) => _BounceDot(delayMs: i * 200))),
        ]),
      );

  Widget _buildStepBar() {
    const labels  = ['Sent', 'Waiting', 'Accepted', 'Progress', 'Done'];
    final display = _rejected ? 1 : _stage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          final isDone = i < display; final isActive = i == display; final isRejStep = _rejected && i == 1;
          return Row(mainAxisSize: MainAxisSize.min, children: [
            Column(children: [
              AnimatedContainer(duration: const Duration(milliseconds: 300), width: 24, height: 24,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: (isDone || isActive) && !isRejStep ? const LinearGradient(colors: [_C.gradA, _C.gradB]) : null,
                  color: isRejStep ? _C.red : (isDone || isActive) ? null : const Color(0xFFE8EAF0)),
                child: Center(child: isDone ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                    : isRejStep ? const Icon(Icons.close_rounded, size: 12, color: Colors.white)
                    : Text('${i + 1}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: isActive ? Colors.white : const Color(0xFFAAAAAA))))),
              const SizedBox(height: 3),
              SizedBox(width: 42, child: Text(labels[i], textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 7.5, color: isRejStep ? _C.red : isDone ? _C.gradA : isActive ? _C.accent : _C.muted,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal))),
            ]),
            if (i < 4) AnimatedContainer(duration: const Duration(milliseconds: 300), width: 20, height: 2, margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(gradient: isDone && !_rejected ? const LinearGradient(colors: [_C.gradA, _C.gradB]) : null,
                    color: (isDone && !_rejected) ? null : const Color(0xFFE2E6F0), borderRadius: BorderRadius.circular(1))),
          ]);
        }),
      ),
    );
  }

  Widget _buildRejectionBanner() => Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _C.redBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _C.redBdr)),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: _C.red.withOpacity(0.12), shape: BoxShape.circle),
              child: const Icon(Icons.cancel_outlined, size: 18, color: _C.red)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Request Declined', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _C.red)),
            SizedBox(height: 2),
            Text('The worker has declined your request. Go back and select another worker.',
                style: TextStyle(fontSize: 10, color: Color(0xFFB91C1C), height: 1.5)),
          ])),
        ]),
      );

  Widget _buildArrivedBanner() => Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFBBF7D0))),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: _C.green.withOpacity(0.12), shape: BoxShape.circle),
              child: const Icon(Icons.directions_walk_rounded, size: 18, color: _C.green)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Worker Has Arrived!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _C.green)),
            SizedBox(height: 2),
            Text('The worker is at your location. The job has started.', style: TextStyle(fontSize: 10, color: Color(0xFF166534), height: 1.5)),
          ])),
        ]),
      );

  Widget _buildQuotationBanner() {
    final price = _data['quotationPrice'];
    final desc  = _data['quotationDesc'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFBFDBFE))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: _C.blue.withOpacity(0.12), shape: BoxShape.circle),
              child: const Icon(Icons.receipt_long_rounded, size: 18, color: _C.blue)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Quotation Received', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _C.blue)),
            Text('The worker has sent you a quotation', style: TextStyle(fontSize: 10, color: _C.blue)),
          ])),
        ]),
        if (price != null) ...[
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFBFDBFE)),
          const SizedBox(height: 8),
          Row(children: [
            const Text('Quoted Price', style: TextStyle(fontSize: 11, color: _C.txt2)),
            const Spacer(),
            Text('LKR $price', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _C.blue)),
          ]),
        ],
        if (desc.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(fontSize: 11, color: _C.txt2, height: 1.4)),
        ],
      ]),
    );
  }

  Widget _buildSummaryCard() {
    final category = _data['category'] as String? ?? '—';
    final rid      = widget.requestId;
    final shortId  = (rid.length >= 8 ? rid.substring(0, 8) : rid).toUpperCase();
    String estLabel, estVal; Color estColor; String statusTxt; Color statusColor;
    if (_rejected) {
      estLabel = 'Status'; estVal = 'Declined'; estColor = _C.red; statusTxt = 'Declined'; statusColor = _C.red;
    } else {
      final status = _data['status'] as String? ?? '';
      switch (_stage) {
        case 1: estLabel = 'Est. Response'; estVal = '~5–10 min'; estColor = _C.accent; statusTxt = 'Pending'; statusColor = _C.accent; break;
        case 2: estLabel = 'Worker ETA'; estVal = '~8 min'; estColor = _C.orange; statusTxt = 'Accepted'; statusColor = _C.orange; break;
        case 3:
          estLabel = 'Work Status'; estVal = status == 'arrived' ? 'Worker Arrived' : 'In Progress';
          estColor = _C.blue; statusTxt = status == 'arrived' ? 'Arrived' : 'In Progress'; statusColor = _C.blue; break;
        case 4: estLabel = 'Work Status'; estVal = 'Completed'; estColor = _C.green; statusTxt = 'Completed'; statusColor = _C.green; break;
        default: estLabel = 'Est. Response'; estVal = 'Calculating…'; estColor = _C.accent; statusTxt = 'Submitted'; statusColor = _C.accent;
      }
    }
    return _SumCard(
      title: _stage >= 3 ? 'SERVICE SUMMARY' : 'REQUEST SUMMARY',
      rows: [
        _SumRow(label: 'Request ID', value: '#$shortId'),
        _SumRow(label: 'Category',   value: category),
        _SumRow(label: estLabel,     value: estVal, valueColor: estColor),
        if (_stage >= 2) _SumRow(label: 'Worker', value: _data['workerName'] as String? ?? '—'),
        _SumRow(label: 'Status', value: statusTxt, valueColor: statusColor),
      ],
    );
  }

  Widget _buildWorkerCard() {
    final name   = _data['workerName'] as String? ?? 'Worker';
    final cat    = _data['category']   as String? ?? '';
    final rating = (_data['workerRating'] as num?)?.toDouble() ?? 4.5;
    final initials = name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _C.cardBdr, width: 0.5)),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [_C.gradA, _C.gradB])),
            child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _C.txt1)),
          Text(cat, style: const TextStyle(fontSize: 10, color: _C.txt2)),
        ])),
        Row(children: [
          const Icon(Icons.star_rounded, size: 14, color: _C.star), const SizedBox(width: 3),
          Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _C.star)),
        ]),
      ]),
    );
  }

  Widget _buildBillCard() => Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _C.cardBdr, width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.receipt_long_outlined, size: 14, color: _C.green), const SizedBox(width: 6),
            Text(_stage >= 3 ? 'PAYMENT SUMMARY' : 'BILL SUMMARY',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _C.muted, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 10),
          _billRow('Inspection Fee',   _inspectionFee, tag: 'Fixed'),
          _billRow('Distance Fee',     _distanceFee),
          _billRow('Service Fee (5%)', _serviceFee),
          const Divider(height: 16, color: _C.cardBdr, thickness: 1.5),
          Row(children: [
            const Expanded(child: Text('Total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _C.txt1))),
            Text('LKR ${_fmt(_totalAmount)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _C.accent)),
          ]),
        ]),
      );

  Widget _billRow(String label, double amount, {String? tag}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Text(label, style: const TextStyle(fontSize: 11, color: _C.txt2)),
          if (tag != null) ...[
            const SizedBox(width: 5),
            Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(4)),
                child: Text(tag, style: const TextStyle(fontSize: 8, color: _C.green, fontWeight: FontWeight.w600))),
          ],
          const Spacer(),
          Text('LKR ${_fmt(amount)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _C.txt1)),
        ]),
      );

  Widget _buildPaymentBadge() => Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFBBF7D0), width: 0.5)),
        child: Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: _C.green.withOpacity(0.12), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, size: 16, color: _C.green)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Payment Confirmed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _C.green)),
            Text('LKR ${_fmt(_totalAmount)} paid successfully', style: const TextStyle(fontSize: 10, color: Color(0xFF166534))),
          ]),
          const Spacer(),
          const Icon(Icons.verified_rounded, size: 18, color: _C.green),
        ]),
      );

  Widget _buildMapSection() {
    final custLat = (_data['latitude']  as num?)?.toDouble() ?? 6.9271;
    final custLng = (_data['longitude'] as num?)?.toDouble() ?? 79.8612;
    final Set<Marker> markers = {
      Marker(markerId: const MarkerId('customer'), position: LatLng(custLat, custLng),
          infoWindow: const InfoWindow(title: 'Job Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet)),
    };
    if (_workerLatLng != null) {
      markers.add(Marker(markerId: const MarkerId('worker'), position: _workerLatLng!,
          infoWindow: const InfoWindow(title: 'Your Worker', snippet: 'Live'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)));
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _C.cardBdr, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(gradient: const LinearGradient(colors: [_C.gradA, _C.gradB]), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.location_on, size: 14, color: Colors.white)),
          const SizedBox(width: 8),
          const Text('LIVE WORKER TRACKING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _C.muted, letterSpacing: 0.5)),
          const Spacer(),
          _LiveDot(),
        ]),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(height: 240,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: _workerLatLng ?? LatLng(custLat, custLng), zoom: 15),
              onMapCreated: (c) => _mapCtrl = c,
              markers: markers,
              polylines: _workerLatLng != null ? {Polyline(polylineId: const PolylineId('route'), points: [_workerLatLng!, LatLng(custLat, custLng)], color: _C.accent, width: 3, patterns: [PatternItem.dash(20), PatternItem.gap(10)])} : {},
              myLocationEnabled: false, zoomControlsEnabled: false,
            ))),
        const SizedBox(height: 8),
        Row(children: [
          _dotLegend(_C.gradB, 'Job Location'), const SizedBox(width: 16), _dotLegend(_C.gradA, 'Worker (Live)'),
          if (_workerLatLng == null) ...[const SizedBox(width: 8), const Text('Locating worker…', style: TextStyle(fontSize: 9, color: _C.muted))],
        ]),
      ]),
    );
  }

  Widget _dotLegend(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 10, color: _C.txt2)),
      ]);

  Widget _buildCompletedCard() {
    final ts = _data['completedAt'] as Timestamp?;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_C.green.withOpacity(0.08), _C.gradB.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFBBF7D0), width: 0.5)),
      child: Column(children: [
        const Icon(Icons.verified_rounded, size: 40, color: _C.green),
        const SizedBox(height: 10),
        const Text('Inspection Complete', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _C.green)),
        const SizedBox(height: 4),
        const Text('Your inspection has been successfully completed.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: _C.txt2, height: 1.6)),
        if (ts != null) ...[
          const SizedBox(height: 10), const Divider(color: _C.cardBdr), const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.access_time_rounded, size: 12, color: _C.muted), const SizedBox(width: 4),
            Text(_fmtTs(ts), style: const TextStyle(fontSize: 10, color: _C.muted)),
          ]),
        ],
      ]),
    );
  }

  String _fmtTs(Timestamp ts) {
    final dt = ts.toDate().toLocal();
    final h  = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    final mm = dt.minute.toString().padLeft(2, '0');
    const mo = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${mo[dt.month - 1]} ${dt.day}, ${dt.year}  $h:$mm $ap';
  }

  Widget _buildBottomBar() => Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(context).padding.bottom + 20),
        child: _bottomContent(),
      );

  Widget _bottomContent() {
    if (_rejected) return _gradBtn(label: 'Go Back', colors: [_C.red, const Color(0xFFDC2626)], onTap: () => Navigator.pop(context));
    final status = _data['status'] as String? ?? '';
    switch (_stage) {
      case 2: return _gradBtn(label: 'Pay Now  —  LKR ${_fmt(_totalAmount)}', colors: [const Color(0xFF27AE60), _C.greenDk], onTap: _openPaymentScreen);
      case 3: return _infoBar(
          icon: status == 'arrived' ? Icons.build_rounded : Icons.info_outline_rounded,
          text: status == 'arrived' ? 'Worker is working on your inspection' : 'Waiting for worker to arrive',
          color: _C.blue, bg: const Color(0xFFEFF6FF), border: const Color(0xFFBFDBFE));
      case 4: return _gradBtn(label: 'Back to Home', colors: [_C.green, _C.greenDk], onTap: () => Navigator.of(context).popUntil((r) => r.isFirst));
      default: return _outlineBtn(label: 'Cancel Request', onTap: _handleCancel);
    }
  }

  Widget _infoBar({required IconData icon, required String text, required Color color, required Color bg, required Color border}) => Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 0.5)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 14, color: color), const SizedBox(width: 6),
          Flexible(child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color))),
        ]),
      );

  void _openPaymentScreen() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => TempPaymentScreen(
      requestId: widget.requestId, totalAmount: _totalAmount, inspectionFee: _inspectionFee, distanceFee: _distanceFee, serviceFee: _serviceFee,
    )));
  }

  Future<void> _handleCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Cancel Request', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to cancel this request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _C.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    _reqSub?.cancel(); _reqSub = null;
    try {
      await FirebaseFirestore.instance.collection('requests').doc(widget.requestId).update({'status': 'cancelled', 'cancelledBy': 'customer'});
    } catch (e) { debugPrint('Cancel error: $e'); }
    if (mounted) Navigator.pop(context);
  }

  Widget _gradBtn({required String label, required List<Color> colors, required VoidCallback onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)))),
      );

  Widget _outlineBtn({required String label, required VoidCallback onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _C.cardBdr, width: 1.5), borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _C.txt2)))),
      );
}

class TempPaymentScreen extends StatefulWidget {
  final String requestId;
  final double totalAmount, inspectionFee, distanceFee, serviceFee;
  const TempPaymentScreen({super.key, required this.requestId, required this.totalAmount, required this.inspectionFee, required this.distanceFee, required this.serviceFee});
  @override
  State<TempPaymentScreen> createState() => _TempPaymentScreenState();
}
class _TempPaymentScreenState extends State<TempPaymentScreen> {
  bool _loading = false;
  String _fmt(num n) { final s = n.toStringAsFixed(0); final b = StringBuffer(); for (int i = 0; i < s.length; i++) { if (i > 0 && (s.length - i) % 3 == 0) b.write(','); b.write(s[i]); } return b.toString(); }
  Future<void> _markPaymentDone() async {
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection('requests').doc(widget.requestId).update({'status': 'inprogress', 'paymentStatus': 'paid', 'paymentMethod': 'manual', 'paidAt': FieldValue.serverTimestamp(), 'totalPaid': widget.totalAmount});
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error confirming payment: $e'), backgroundColor: _C.red));
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _C.bg,
        body: Column(children: [
          Container(color: Colors.white, padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 4, bottom: 12, left: 16, right: 16),
              child: Row(children: [
                GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 32, height: 32, decoration: const BoxDecoration(color: Color(0xFFF0F2F8), shape: BoxShape.circle), child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Color(0xFF444444)))),
                const SizedBox(width: 12),
                const Text('Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _C.txt1)),
              ])),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
            const SizedBox(height: 16),
            Container(width: 130, height: 130, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF27AE60), _C.greenDk])),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Total Due', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
                  const Text('LKR', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                  Text(_fmt(widget.totalAmount), style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                ])),
            const SizedBox(height: 20),
            Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFED7AA), width: 0.5)),
                child: const Row(children: [Icon(Icons.info_outline_rounded, size: 14, color: _C.orange), SizedBox(width: 8), Expanded(child: Text('Complete your payment via the agreed method, then press "Payment Done" to confirm.', style: TextStyle(fontSize: 10, color: _C.orange, height: 1.5)))])),
            const SizedBox(height: 16),
            Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _C.cardBdr, width: 0.5)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [Icon(Icons.receipt_long_outlined, size: 14, color: _C.green), SizedBox(width: 6), Text('BILL BREAKDOWN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _C.muted, letterSpacing: 0.5))]),
                  const SizedBox(height: 14),
                  _pRow('Inspection Fee', widget.inspectionFee, tag: 'Fixed'), _pRow('Distance Fee', widget.distanceFee), _pRow('Service Fee (5%)', widget.serviceFee),
                  const Divider(height: 20, color: _C.cardBdr, thickness: 1.5),
                  Row(children: [const Expanded(child: Text('Total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _C.txt1))), Text('LKR ${_fmt(widget.totalAmount)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _C.accent))]),
                ])),
          ]))),
          Container(color: Colors.white, padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(context).padding.bottom + 20),
              child: GestureDetector(onTap: _loading ? null : _markPaymentDone, child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF27AE60), _C.greenDk]), borderRadius: BorderRadius.circular(14)),
                  child: Center(child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle_rounded, size: 16, color: Colors.white), SizedBox(width: 8), Text('Payment Done', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))]))
              ))),
        ]),
      );
  Widget _pRow(String label, double amount, {String? tag}) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
        Text(label, style: const TextStyle(fontSize: 11, color: _C.txt2)),
        if (tag != null) ...[const SizedBox(width: 5), Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(4)), child: Text(tag, style: const TextStyle(fontSize: 8, color: _C.green, fontWeight: FontWeight.w600)))],
        const Spacer(), Text('LKR ${_fmt(amount)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _C.txt1)),
      ]));
}

class _SumRow { final String label, value; final Color? valueColor; const _SumRow({required this.label, required this.value, this.valueColor}); }
class _SumCard extends StatelessWidget {
  final String title; final List<_SumRow> rows;
  const _SumCard({required this.title, required this.rows});
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.fromLTRB(16, 8, 16, 0), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _C.cardBdr, width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _C.muted, letterSpacing: 0.5)), const SizedBox(height: 10),
          ...rows.map((r) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Expanded(child: Text(r.label, style: const TextStyle(fontSize: 11, color: _C.txt2))), Text(r.value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: r.valueColor ?? _C.txt1))]))),
        ]));
}
class _LiveDot extends StatefulWidget { @override State<_LiveDot> createState() => _LiveDotState(); }
class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late AnimationController _c; late Animation<double> _a;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true); _a = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: _a, builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: _C.green.withOpacity(_a.value), shape: BoxShape.circle)), const SizedBox(width: 4), Text('LIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _C.green.withOpacity(_a.value)))]));
}
class _ArcPainter extends CustomPainter {
  final double? progress; final bool spinning, rejected, completed; final double spinValue;
  const _ArcPainter({this.progress, required this.spinning, required this.spinValue, this.rejected = false, this.completed = false});
  @override void paint(Canvas canvas, Size size) {
    const cx = 50.0, cy = 50.0, r = 43.0, sw = 5.0;
    canvas.drawCircle(const Offset(cx, cy), r, Paint()..style = PaintingStyle.stroke..strokeWidth = sw..color = const Color(0xFFE8E6F8));
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round..shader = (rejected ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]) : completed ? const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF1E8449)]) : const LinearGradient(colors: [_C.gradA, _C.gradB])).createShader(Rect.fromCircle(center: const Offset(cx, cy), radius: r));
    if (spinning) { canvas.drawArc(Rect.fromCircle(center: const Offset(cx, cy), radius: r), spinValue * 2 * math.pi, math.pi * 1.4, false, p); }
    else { canvas.drawArc(Rect.fromCircle(center: const Offset(cx, cy), radius: r), -math.pi / 2, 2 * math.pi * (progress ?? 1.0), false, p); }
  }
  @override bool shouldRepaint(_ArcPainter o) => true;
}
class _BounceDot extends StatefulWidget { final int delayMs; const _BounceDot({required this.delayMs}); @override State<_BounceDot> createState() => _BounceDotState(); }
class _BounceDotState extends State<_BounceDot> with SingleTickerProviderStateMixin {
  late AnimationController _c; late Animation<double> _a;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200)); _a = Tween<double>(begin: 0, end: -6).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)); Future.delayed(Duration(milliseconds: widget.delayMs), () { if (mounted) _c.repeat(reverse: true); }); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: _a, builder: (_, __) => Transform.translate(offset: Offset(0, _a.value), child: Container(width: 7, height: 7, margin: const EdgeInsets.symmetric(horizontal: 3), decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [_C.gradA, _C.gradB])))));
}
