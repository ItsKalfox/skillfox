import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'quotation_screen.dart';

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
  static const red     = Color(0xFFEF4444);
}

class WorkerJobProgressScreen extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const WorkerJobProgressScreen({
    super.key,
    required this.requestId,
    required this.requestData,
  });

  @override
  State<WorkerJobProgressScreen> createState() => _WorkerJobProgressScreenState();
}

class _WorkerJobProgressScreenState extends State<WorkerJobProgressScreen>
    with TickerProviderStateMixin {

  int _stage = 0;
  Map<String, dynamic> _data = {};
  StreamSubscription<DocumentSnapshot>? _sub;

  Timer? _timer;
  int _elapsedSeconds = 0;
  DateTime? _arrivedAt;

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  GoogleMapController? _mapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSub;

  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0, end: 10).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _data = {...widget.requestData, 'id': widget.requestId};
    _setStageFromStatus(_data['status'] as String? ?? 'accepted');
    _listenToRequest();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _positionSub?.cancel();
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _listenToRequest() {
    _sub = FirebaseFirestore.instance.collection('requests').doc(widget.requestId).snapshots().listen((snap) {
      if (!snap.exists || !mounted) return;
      final d = Map<String, dynamic>.from(snap.data()!);
      d['id'] = snap.id;
      setState(() { _data = d; _setStageFromStatus(d['status'] as String? ?? 'accepted'); });
    });
  }

  void _setStageFromStatus(String status) {
    switch (status) {
      case 'accepted':
        _stage = 0;
        break;
      case 'inprogress':
      case 'paid':
        _stage = 1;
        break;
      case 'arrived':
        _stage = 2;
        if (_arrivedAt == null && _data['arrivedAt'] != null) {
          try {
            _arrivedAt = (_data['arrivedAt'] as Timestamp).toDate();
            _elapsedSeconds = DateTime.now().difference(_arrivedAt!).inSeconds;
            _startTimer();
          } catch (_) {}
        }
        break;
      case 'completed':
        _stage = 3;
        _timer?.cancel();
        break;
      case 'quotation_sent':
        _stage = 4;
        _timer?.cancel();
        break;
      case 'quotation_paid':
        _stage = 5;
        break;
      case 'quotation_declined':
        _stage = 6;
        break;
      case 'job_done':
        _stage = 7;
        break;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() => _elapsedSeconds++); });
  }

  String get _timerDisplay {
    final h = _elapsedSeconds ~/ 3600;
    final m = (_elapsedSeconds % 3600) ~/ 60;
    final s = _elapsedSeconds % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _startLocationTracking() async {
    if (_positionSub != null) return;
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) { perm = await Geolocator.requestPermission(); if (perm == LocationPermission.denied) return; }
      if (perm == LocationPermission.deniedForever) return;
      _positionSub = Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)).listen((pos) {
        if (!mounted) return;
        setState(() => _currentPosition = pos);
        _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)));
      });
    } catch (_) {}
  }

  Future<void> _markArrived() async {
    if (_actionLoading) return;
    setState(() => _actionLoading = true);
    try {
      final now = DateTime.now();
      await FirebaseFirestore.instance.collection('requests').doc(widget.requestId)
          .update({'status': 'arrived', 'arrivedAt': FieldValue.serverTimestamp()});
      setState(() { _arrivedAt = now; _elapsedSeconds = 0; _stage = 2; });
      _startTimer();
      _startLocationTracking();
    } catch (e) { _showSnack('Error: $e', isError: true); }
    finally { if (mounted) setState(() => _actionLoading = false); }
  }

  Future<void> _markCompleted() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('Mark as Completed', style: TextStyle(fontWeight: FontWeight.w700)),
      content: const Text('Are you sure the inspection is completed? You can then send a quotation.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _C.green), onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Completed', style: TextStyle(color: Colors.white))),
      ],
    ));
    if (ok != true || !mounted) return;
    setState(() => _actionLoading = true);
    try {
      _timer?.cancel();
      await FirebaseFirestore.instance.collection('requests').doc(widget.requestId)
          .update({'status': 'completed', 'completedAt': FieldValue.serverTimestamp(), 'jobDuration': _elapsedSeconds});
      setState(() => _stage = 3);
    } catch (e) { _showSnack('Error: $e', isError: true); }
    finally { if (mounted) setState(() => _actionLoading = false); }
  }

  void _openQuotation() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => QuotationScreen(requestId: widget.requestId, requestData: _data)));
  }

  Future<void> _markAsDone() async {
    if (_actionLoading) return;
    setState(() => _actionLoading = true);
    try {
      await FirebaseFirestore.instance.collection('requests').doc(widget.requestId).update({
        'status':    'job_done',
        'jobDoneAt': FieldValue.serverTimestamp(),
      });
      setState(() => _stage = 7);
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: isError ? _C.red : _C.green,
      behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16),
    ));
  }

  String _fmt(num n) {
    final s = n.toStringAsFixed(0); final b = StringBuffer();
    for (int i = 0; i < s.length; i++) { if (i > 0 && (s.length - i) % 3 == 0) b.write(','); b.write(s[i]); }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _C.bg,
        body: Column(children: [
          _buildHeader(),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(children: [
              _buildHero(),
              _buildStepBar(),
              _buildSummaryCard(),
              if (_stage >= 1) _buildPaymentConfirmedCard(),
              if (_stage >= 2) _buildTimerCard(),
              if (_stage >= 1 && _stage <= 4) _buildMapSection(),
              if (_stage == 4) _buildQuotationSentCard(),
              if (_stage == 5) _buildQuotationPaidCard(),
              if (_stage == 6) _buildQuotationDeclinedCard(),
              if (_stage == 7) _buildJobDoneCard(),
            ]),
          )),
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
          const Text('Job Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _C.txt1)),
        ]),
      );

  Widget _buildHero() {
    final titles = ['Waiting for Payment', 'Head to Job Location', 'Job In Progress', 'Job Completed!', 'Quotation Sent', 'Quotation Accepted!', 'Quotation Declined', 'Quotation Completed'];
    final subs   = [
      'Customer needs to complete payment before you head over.',
      'Customer paid! Head to the job location and tap "Mark as Arrived".',
      'Timer is running. Tap "Mark as Completed" when done.',
      'Great work! Send a quotation to the customer.',
      'Quotation sent. Waiting for customer to accept or decline.',
      'Customer accepted and paid the quotation. Job is done!',
      'Customer declined the quotation.',
      'Quotation successfully completed. Great work!',
    ];
    final icons  = [Icons.hourglass_top_rounded, Icons.directions_car_rounded, Icons.build_rounded, Icons.check_circle_rounded, Icons.receipt_long_rounded, Icons.verified_rounded, Icons.cancel_outlined, Icons.celebration_rounded];
    final cols   = [
      [_C.gradA, _C.gradB],
      [_C.orange, const Color(0xFFD14A08)],
      [_C.orange, const Color(0xFFD14A08)],
      [_C.green, _C.greenDk],
      [_C.blue, const Color(0xFF1D4ED8)],
      [_C.green, _C.greenDk],
      [_C.red, const Color(0xFFDC2626)],
      [_C.green, _C.greenDk],
    ];
   final idx = _stage.clamp(0, 7);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
      child: Column(children: [
        AnimatedBuilder(animation: _pulseAnim, builder: (_, __) => Container(width: 80, height: 80,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: cols[idx]),
            boxShadow: [BoxShadow(color: cols[idx][0].withOpacity(0.35), blurRadius: _pulseAnim.value, spreadRadius: _pulseAnim.value * 0.3)]),
          child: Icon(icons[idx], color: Colors.white, size: 36))),
        const SizedBox(height: 14),
        Text(titles[idx], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _C.txt1)),
        const SizedBox(height: 4),
        Text(subs[idx], textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: _C.txt2, height: 1.7)),
      ]),
    );
  }

  Widget _buildStepBar() {
    const labels = ['Accepted', 'Paid', 'Arrived', 'Completed', 'Quotation'];
    final display = _stage.clamp(0, 4);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          final isDone = i < display; final isActive = i == display;
          return Row(mainAxisSize: MainAxisSize.min, children: [
            Column(children: [
              AnimatedContainer(duration: const Duration(milliseconds: 300), width: 24, height: 24,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: (isDone || isActive) ? const LinearGradient(colors: [_C.gradA, _C.gradB]) : null,
                  color: (isDone || isActive) ? null : const Color(0xFFE8EAF0)),
                child: Center(child: isDone ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                    : Text('${i + 1}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: isActive ? Colors.white : const Color(0xFFAAAAAA))))),
              const SizedBox(height: 3),
              SizedBox(width: 46, child: Text(labels[i], textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 7.0, color: isDone ? _C.gradA : isActive ? _C.accent : _C.muted,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal))),
            ]),
            if (i < 4) AnimatedContainer(duration: const Duration(milliseconds: 300), width: 14, height: 2, margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(gradient: isDone ? const LinearGradient(colors: [_C.gradA, _C.gradB]) : null,
                    color: isDone ? null : const Color(0xFFE2E6F0), borderRadius: BorderRadius.circular(1))),
          ]);
        }),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final category = _data['category']    as String? ?? '—';
    final custName = _data['customerName'] as String? ?? '—';
    final address  = _data['address']      as String? ?? '—';
    final shortId  = widget.requestId.length >= 8 ? widget.requestId.substring(0, 8).toUpperCase() : widget.requestId.toUpperCase();
    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _Label('JOB SUMMARY'), const SizedBox(height: 10),
      _Row(label: 'Request ID', value: '#$shortId'),
      _Row(label: 'Category',   value: category),
      _Row(label: 'Customer',   value: custName),
      _Row(label: 'Address',    value: address, valueColor: _C.blue),
    ]));
  }

  Widget _buildPaymentConfirmedCard() {
    final total = (_data['totalPaid'] as num?)?.toDouble() ?? (_data['totalAmount'] as num?)?.toDouble() ?? 0.0;
    return _Card(child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: _C.green.withOpacity(0.12), shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_rounded, size: 20, color: _C.green)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Payment Confirmed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _C.green)),
        Text(total > 0 ? 'LKR ${_fmt(total)} paid by customer' : 'Customer payment received', style: const TextStyle(fontSize: 10, color: _C.txt2)),
      ])),
      const Icon(Icons.verified_rounded, size: 18, color: _C.green),
    ]));
  }

  Widget _buildTimerCard() => _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(gradient: const LinearGradient(colors: [_C.orange, Color(0xFFD14A08)]), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.timer_rounded, size: 14, color: Colors.white)),
          const SizedBox(width: 8), const _Label('TIME TRACKING'),
        ]),
        const SizedBox(height: 14),
        Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFED7AA), width: 0.5)),
          child: Text(_timerDisplay, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: _C.orange, letterSpacing: 2, fontFeatures: [FontFeature.tabularFigures()])),
        )),
        const SizedBox(height: 8),
        Center(child: Text(_stage == 2 ? 'Timer started when you arrived' : 'Total job duration', style: const TextStyle(fontSize: 10, color: _C.muted))),
      ]));

  Widget _buildMapSection() {
    final custLat = (_data['latitude']  as num?)?.toDouble() ?? 0.0;
    final custLng = (_data['longitude'] as num?)?.toDouble() ?? 0.0;
    if (custLat == 0.0 && custLng == 0.0) return const SizedBox.shrink();
    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(gradient: const LinearGradient(colors: [_C.gradA, _C.gradB]), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.location_on, size: 14, color: Colors.white)),
        const SizedBox(width: 8), const _Label('JOB LOCATION'),
      ]),
      const SizedBox(height: 10),
      ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(height: 200,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
                target: _currentPosition != null ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) : LatLng(custLat, custLng), zoom: 15),
            onMapCreated: (c) => _mapController = c,
            markers: {
              Marker(markerId: const MarkerId('customer'), position: LatLng(custLat, custLng),
                  infoWindow: const InfoWindow(title: 'Job Location'), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet)),
              if (_currentPosition != null)
                Marker(markerId: const MarkerId('worker'), position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    infoWindow: const InfoWindow(title: 'You'), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)),
            },
            zoomControlsEnabled: false, myLocationEnabled: true, myLocationButtonEnabled: false,
          ))),
    ]));
  }

  Widget _buildQuotationSentCard() {
    final total    = (_data['quotationTotalCost'] as num?)?.toDouble() ?? 0;
    final jobDesc  = _data['quotationJobDesc']    as String? ?? '';
    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(gradient: const LinearGradient(colors: [_C.blue, Color(0xFF1D4ED8)]), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.receipt_long_rounded, size: 14, color: Colors.white)),
        const SizedBox(width: 8), const _Label('QUOTATION SENT'),
        const Spacer(),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
            child: const Text('Pending ●', style: TextStyle(fontSize: 9, color: _C.blue, fontWeight: FontWeight.w700))),
      ]),
      if (jobDesc.isNotEmpty) ...[const SizedBox(height: 10), Text(jobDesc, style: const TextStyle(fontSize: 11, color: _C.txt2, height: 1.4))],
      if (total > 0) ...[
        const SizedBox(height: 10),
        Row(children: [
          const Expanded(child: Text('Quoted Amount', style: TextStyle(fontSize: 11, color: _C.txt2))),
          Text('LKR ${_fmt(total)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _C.blue)),
        ]),
      ],
      const SizedBox(height: 10),
      Container(padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFBFDBFE), width: 0.5)),
          child: const Row(children: [
            Icon(Icons.hourglass_top_rounded, size: 12, color: _C.blue), SizedBox(width: 6),
            Expanded(child: Text('Waiting for customer to accept or decline the quotation.', style: TextStyle(fontSize: 10, color: _C.blue, height: 1.4))),
          ])),
    ]));
  }

  Widget _buildQuotationPaidCard() {
    final total    = (_data['quotationTotalCost']    as num?)?.toDouble() ?? 0;
    final jobDesc  = _data['quotationJobDesc']       as String? ?? '';
    final labour   = (_data['quotationLabourCost']   as num?)?.toDouble() ?? 0;
    final material = (_data['quotationMaterialCost'] as num?)?.toDouble() ?? 0;
    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(gradient: const LinearGradient(colors: [_C.green, _C.greenDk]), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white)),
        const SizedBox(width: 8), const _Label('QUOTATION ACCEPTED & PAID'),
        const Spacer(),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
            child: const Text('Paid ✓', style: TextStyle(fontSize: 9, color: _C.green, fontWeight: FontWeight.w700))),
      ]),
      const SizedBox(height: 12),
      if (jobDesc.isNotEmpty) ...[
        const Text('Work Description', style: TextStyle(fontSize: 10, color: _C.muted)),
        const SizedBox(height: 4),
        Text(jobDesc, style: const TextStyle(fontSize: 12, color: _C.txt1, height: 1.4)),
        const SizedBox(height: 12),
      ],
      if (labour > 0) _Row(label: 'Labour Cost',   value: 'LKR ${_fmt(labour)}'),
      if (material > 0) _Row(label: 'Material Cost', value: 'LKR ${_fmt(material)}'),
      const Divider(height: 16, color: _C.cardBdr),
      _Row(label: 'Total Received', value: 'LKR ${_fmt(total)}', valueColor: _C.green),
      const SizedBox(height: 10),
      Container(padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_C.green.withOpacity(0.1), _C.gradB.withOpacity(0.05)]),
            borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFBBF7D0), width: 0.5)),
          child: const Row(children: [
            Icon(Icons.verified_rounded, size: 14, color: _C.green), SizedBox(width: 6),
            Expanded(child: Text('Customer has paid. The job is now complete!', style: TextStyle(fontSize: 10, color: _C.green, height: 1.4))),
          ])),
    ]));
  }

  Widget _buildQuotationDeclinedCard() => _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(color: _C.red.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.cancel_outlined, size: 14, color: _C.red)),
          const SizedBox(width: 8), const _Label('QUOTATION DECLINED'),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
              child: const Text('Declined ✗', style: TextStyle(fontSize: 9, color: _C.red, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 10),
        Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFECACA), width: 0.5)),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded, size: 12, color: _C.red), SizedBox(width: 6),
              Expanded(child: Text('The customer has declined your quotation. The inspection work has been completed.', style: TextStyle(fontSize: 10, color: _C.red, height: 1.4))),
            ])),
      ]));

  Widget _buildJobDoneCard() => _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 28, height: 28,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [_C.green, _C.greenDk]), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.celebration_rounded, size: 14, color: Colors.white)),
          const SizedBox(width: 8), const _Label('JOB SUCCESSFULLY COMPLETED'),
        ]),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [_C.green.withOpacity(0.1), _C.gradB.withOpacity(0.05)]),
              borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFBBF7D0), width: 0.5)),
            child: const Row(children: [
              Icon(Icons.verified_rounded, size: 14, color: _C.green), SizedBox(width: 6),
              Expanded(child: Text('The quotation has been completed and paid. Great work!',
                  style: TextStyle(fontSize: 11, color: _C.green, height: 1.5))),
            ])),
      ]));

  Widget _buildBottomBar() => Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(context).padding.bottom + 20),
        child: _bottomContent(),
      );

  Widget _bottomContent() {
    switch (_stage) {
      case 0:
        return _infoBar(icon: Icons.payment_rounded, text: 'Waiting for customer to complete payment', color: _C.orange, bg: const Color(0xFFFFF7ED), border: const Color(0xFFFED7AA));
      case 1:
        return _gradBtn(label: _actionLoading ? 'Please wait…' : 'Mark as Arrived', colors: [_C.gradA, _C.gradB], icon: Icons.location_on_rounded, onTap: _actionLoading ? null : _markArrived);
      case 2:
        return _gradBtn(label: _actionLoading ? 'Please wait…' : 'Mark as Completed', colors: [_C.green, _C.greenDk], icon: Icons.check_circle_rounded, onTap: _actionLoading ? null : _markCompleted);
      case 3:
        return _gradBtn(label: 'Send Quotation', colors: [_C.gradA, _C.gradB], icon: Icons.receipt_long_rounded, onTap: _openQuotation);
      case 4:
        final qStatus = _data['quotationStatus'] as String? ?? 'pending';
        if (qStatus == 'accepted') {
          return _infoBar(icon: Icons.check_circle_outline_rounded, text: 'Customer accepted the quotation! Waiting for payment...', color: _C.green, bg: const Color(0xFFECFDF5), border: const Color(0xFFBBF7D0));
        }
        return _infoBar(icon: Icons.hourglass_top_rounded, text: 'Waiting for customer to accept or decline the quotation', color: _C.blue, bg: const Color(0xFFEFF6FF), border: const Color(0xFFBFDBFE));
      case 5:
        return _gradBtn(
          label: _actionLoading ? 'Please wait...' : 'Mark as Done',
          colors: [_C.green, _C.greenDk],
          icon: Icons.done_all_rounded,
          onTap: _actionLoading ? null : _markAsDone,
        );
case 7:
  return _infoBar(
    icon: Icons.celebration_rounded,
    text: 'Quotation successfully completed! Great work.',
    color: _C.green,
    bg: const Color(0xFFECFDF5),
    border: const Color(0xFFBBF7D0),
  );
      case 6:
        return _infoBar(icon: Icons.info_outline_rounded, text: 'Customer declined the quotation. Inspection was completed.', color: _C.red, bg: const Color(0xFFFEF2F2), border: const Color(0xFFFECACA));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _gradBtn({required String label, required List<Color> colors, required IconData icon, required VoidCallback? onTap}) =>
      GestureDetector(onTap: onTap,
        child: AnimatedOpacity(duration: const Duration(milliseconds: 200), opacity: onTap == null ? 0.6 : 1.0,
          child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(14)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _actionLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ]))));

  Widget _infoBar({required IconData icon, required String text, required Color color, required Color bg, required Color border}) =>
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 0.5)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 14, color: color), const SizedBox(width: 8),
          Flexible(child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color))),
        ]));
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _C.cardBdr, width: 0.5)),
        child: child);
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _C.muted, letterSpacing: 0.5));
}

class _Row extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _Row({required this.label, required this.value, this.valueColor});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: _C.txt2))),
          Flexible(child: Text(value, textAlign: TextAlign.end, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: valueColor ?? _C.txt1))),
        ]));
}

class _ArcPainter extends CustomPainter {
  final double? progress; final bool spinning; final double spinValue;
  const _ArcPainter({this.progress, required this.spinning, required this.spinValue});
  @override
  void paint(Canvas canvas, Size size) {
    const cx = 50.0, cy = 50.0, r = 43.0, sw = 5.0;
    canvas.drawCircle(const Offset(cx, cy), r, Paint()..style = PaintingStyle.stroke..strokeWidth = sw..color = const Color(0xFFE8E6F8));
    final grad = Paint()..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(colors: [_C.gradA, _C.gradB]).createShader(Rect.fromCircle(center: const Offset(cx, cy), radius: r));
    if (spinning) { canvas.drawArc(Rect.fromCircle(center: const Offset(cx, cy), radius: r), spinValue * 2 * math.pi, math.pi * 1.4, false, grad); }
    else { canvas.drawArc(Rect.fromCircle(center: const Offset(cx, cy), radius: r), -math.pi / 2, 2 * math.pi * (progress ?? 1.0), false, grad); }
  }
  @override bool shouldRepaint(_ArcPainter o) => true;
}