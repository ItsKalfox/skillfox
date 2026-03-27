import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/worker.dart';
import '../category_a/payment/payment_screen.dart';
import 'customer_quotation_view_screen.dart';
import 'review_screen.dart';

class _C {
  static const gradA = Color(0xFF469FEF);
  static const gradB = Color(0xFF6C56F0);
  static const accent = Color(0xFF6C56F0);
  static const bg = Color(0xFFF4F6FA);
  static const cardBorder = Color(0xFFE2E6F0);
  static const txt1 = Color(0xFF111111);
  static const txt2 = Color(0xFF888888);
  static const muted = Color(0xFFA0A4B0);
  static const green = Color(0xFF16A34A);
  static const greenDark = Color(0xFF1E8449);
  static const orange = Color(0xFFEA580C);
  static const blue = Color(0xFF2563EB);
  static const star = Color(0xFFF59E0B);
  static const reject = Color(0xFFEF4444);
  static const rejectBg = Color(0xFFFEF2F2);
  static const rejectBdr = Color(0xFFFECACA);
}

class WaitingWorkerScreen extends StatefulWidget {
  final String requestId;
  final Worker? worker;

  const WaitingWorkerScreen({super.key, required this.requestId, this.worker});

  @override
  State<WaitingWorkerScreen> createState() => _WaitingWorkerScreenState();
}

class _WaitingWorkerScreenState extends State<WaitingWorkerScreen>
    with TickerProviderStateMixin {
  int _stage = 0;
  bool _rejected = false;
  Map<String, dynamic> _data = {};

  StreamSubscription<DocumentSnapshot>? _reqSub;
  StreamSubscription<DocumentSnapshot>? _workerLocSub;

  late AnimationController _spinCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  GoogleMapController? _mapController;
  LatLng? _workerLatLng;

  Timer? _displayTimer;
  int _elapsedSeconds = 0;

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
    _pulseAnim = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _listenToRequest();
  }

  @override
  void dispose() {
    _reqSub?.cancel();
    _workerLocSub?.cancel();
    _displayTimer?.cancel();
    _spinCtrl.dispose();
    _pulseCtrl.dispose();
    _mapController?.dispose();
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
      case 'paid':
        _rejected = false;
        _stage = 3;
        _startWorkerTracking();
        break;
      case 'arrived':
        _rejected = false;
        _stage = 4;
        _startWorkerTracking();
        _startCustomerTimer();
        break;
      case 'completed':
        _rejected = false;
        _stage = 5;
        _displayTimer?.cancel();
        _workerLocSub?.cancel();
        break;
      case 'quotation_sent':
        _rejected = false;
        _stage = 6;
        break;
      case 'quotation_paid':
        _rejected = false;
        _stage = 7;
        break;
      case 'quotation_declined':
        _rejected = false;
        _stage = 8;
        break;
      case 'cancelled':
        if (mounted) Navigator.pop(context);
        break;
    }
  }

  void _startCustomerTimer() {
    if (_displayTimer != null) return;
    if (_data['arrivedAt'] != null) {
      try {
        final arrivedAt = (_data['arrivedAt'] as Timestamp).toDate();
        _elapsedSeconds = DateTime.now().difference(arrivedAt).inSeconds;
      } catch (_) {}
    }
    _displayTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  String get _timerDisplay {
    final h = _elapsedSeconds ~/ 3600;
    final m = (_elapsedSeconds % 3600) ~/ 60;
    final s = _elapsedSeconds % 60;
    if (h > 0)
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _startWorkerTracking() {
    final workerId = _data['workerId'] as String?;
    if (workerId == null || workerId.isEmpty || _workerLocSub != null) return;
    _workerLocSub = FirebaseFirestore.instance
        .collection('workers')
        .doc(workerId)
        .snapshots()
        .listen((snap) {
          if (!snap.exists || !mounted) return;
          final d = snap.data()!;
          final lat = (d['currentLat'] as num?)?.toDouble();
          final lng = (d['currentLng'] as num?)?.toDouble();
          if (lat == null || lng == null) return;
          setState(() => _workerLatLng = LatLng(lat, lng));
          _mapController?.animateCamera(CameraUpdate.newLatLng(_workerLatLng!));
        });
  }

  Future<void> _handleCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Cancel Request',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Are you sure you want to cancel this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _C.reject),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    _reqSub?.cancel();
    _reqSub = null;
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
            'status': 'cancelled',
            'cancelledBy': 'customer',
            'cancelledAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Cancel error: $e');
    }
    if (mounted) Navigator.pop(context);
  }

  double get _inspectionFee =>
      (_data['inspectionFee'] as num?)?.toDouble() ?? 1500.0;
  double get _distanceFee {
    final stored =
        (_data['distanceFee'] as num?) ?? (_data['travelFee'] as num?);
    if (stored != null && stored > 0) return stored.toDouble();
    var km = (_data['distanceKm'] as num?)?.toDouble() ?? 0.0;
    if (km > 500) km = km / 1000;
    return (km * 50).roundToDouble().clamp(100.0, 3000.0);
  }

  double get _serviceFee =>
      (_data['serviceFee'] as num?)?.toDouble() ??
      ((_inspectionFee + _distanceFee) * 0.05).roundToDouble();
  double get _totalAmount =>
      (_data['totalAmount'] as num?)?.toDouble() ??
      (_inspectionFee + _distanceFee + _serviceFee);
  String get _requestId => widget.requestId;

  String _fmt(num n) {
    final s = n.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  bool get _arcSpin => (_stage == 0 || _stage == 1) && !_rejected;
  bool get _doPulse => _stage <= 4 && !_rejected;
  bool get _showDots => _arcSpin;

  String get _stageTitle {
    if (_rejected) return 'Request Declined';
    switch (_stage) {
      case 0:
        return 'Submitted';
      case 1:
        return 'Waiting for Worker…';
      case 2:
        return 'Worker Accepted!';
      case 3:
        return 'Worker On The Way';
      case 4:
        return 'Worker Has Arrived!';
      case 5:
        return 'Inspection Completed';
      case 6:
        return 'Quotation Received';
      case 7:
        return 'Quotation Paid';
      case 8:
        return 'Quotation Declined';
      case 9:
        return 'Job Completed!';
      default:
        return '';
    }
  }

  String get _stageSub {
    if (_rejected) return 'The worker has declined your request.';
    final name = _data['workerName'] as String? ?? 'The worker';
    switch (_stage) {
      case 0:
        return 'Request submitted successfully.';
      case 1:
        return 'Your request has been sent to nearby workers. Hang tight!';
      case 2:
        return '$name accepted your request. Review the bill and complete payment.';
      case 3:
        return 'Payment confirmed! $name is heading to your location.';
      case 4:
        return '$name has arrived at your location. Work has started!';
      case 5:
        return 'The inspection has been completed. A quotation is being prepared.';
      case 6:
        return '$name has sent you a quotation. Review and accept or decline it.';
      case 7:
        return 'Quotation payment confirmed. Work is in progress.';
      case 8:
        return 'You declined the quotation. Please leave a review.';
      case 9:
        return 'The quotation has been completed successfully!';
      default:
        return '';
    }
  }

  Color get _badgeColor {
    if (_rejected) return _C.rejectBg;
    switch (_stage) {
      case 2:
        return const Color(0xFFFFF7ED);
      case 3:
        return const Color(0xFFEFF6FF);
      case 4:
        return const Color(0xFFF0FDF4);
      case 5:
        return const Color(0xFFECFDF5);
      case 6:
        return const Color(0xFFEFF6FF);
      case 7:
        return const Color(0xFFECFDF5);
      case 8:
        return _C.rejectBg;
      default:
        return const Color(0xFFEEF2FF);
    }
  }

  Color get _badgeTxtColor {
    if (_rejected) return _C.reject;
    switch (_stage) {
      case 2:
        return _C.orange;
      case 3:
        return _C.blue;
      case 4:
        return _C.green;
      case 5:
        return _C.green;
      case 6:
        return _C.blue;
      case 7:
        return _C.green;
      case 8:
        return _C.reject;
      default:
        return _C.accent;
    }
  }

  String get _badgeTxt {
    if (_rejected) return '● Declined by Worker';
    switch (_stage) {
      case 0:
        return '● Submitted';
      case 1:
        return '● Waiting';
      case 2:
        return '● Accepted';
      case 3:
        return '● Worker On Way';
      case 4:
        return '● Worker Arrived';
      case 5:
        return '● Completed';
      case 6:
        return '● Quotation Received';
      case 7:
        return '● Quotation Paid';
      case 8:
        return '● Quotation Declined';
      default:
        return '● Submitted';
    }
  }

  IconData get _blobIcon {
    if (_rejected) return Icons.close_rounded;
    switch (_stage) {
      case 1:
        return Icons.chat_bubble_outline_rounded;
      case 2:
        return Icons.check_circle_outline_rounded;
      case 3:
        return Icons.directions_car_rounded;
      case 4:
        return Icons.build_rounded;
      case 5:
        return Icons.verified_rounded;
      case 6:
        return Icons.receipt_long_rounded;
      case 7:
        return Icons.check_circle_rounded;
      case 8:
        return Icons.cancel_outlined;
      default:
        return Icons.check_rounded;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
                if (_rejected) _buildRejectionBanner(),
                if (_stage == 4) _buildArrivedBanner(),
                _buildSummaryCard(),
                if (_stage >= 2 && !_rejected) _buildWorkerCard(),
                if (_stage >= 2 && !_rejected) _buildBillCard(),
                if (_stage >= 3) _buildPaymentConfirmedBadge(),
                if (_stage == 4) _buildCustomerTimerCard(),
                if (_stage == 3 || _stage == 4) _buildMapSection(),
                if (_stage == 5) _buildCompletedSummary(),
                if (_stage == 6) _buildQuotationReceivedCard(),
                if (_stage == 7) _buildQuotationPaidCard(),
                if (_stage == 8) _buildQuotationDeclinedCard(),
                if (_stage == 9) _buildJobDoneCard(),
              ],
            ),
          ),
        ),
        _buildBottomBar(),
      ],
    ),
  );

  Widget _buildHeader() => Container(
    color: Colors.white,
    padding: EdgeInsets.only(
      top: MediaQuery.of(context).padding.top + 4,
      bottom: 12,
      left: 16,
      right: 16,
    ),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFF0F2F8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 14,
              color: Color(0xFF444444),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Request Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _C.txt1,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '#${_requestId.length >= 6 ? _requestId.substring(0, 6).toUpperCase() : _requestId.toUpperCase()}',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: _C.accent,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildHero() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
    child: Column(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _spinCtrl,
                builder: (_, __) => CustomPaint(
                  size: const Size(100, 100),
                  painter: _ArcPainter(
                    progress: _arcSpin ? null : (_stage / 8.0),
                    spinning: _arcSpin,
                    spinValue: _spinCtrl.value,
                    rejected: _rejected,
                    completed: _stage >= 5,
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _rejected || _stage == 8
                          ? [_C.reject, const Color(0xFFDC2626)]
                          : _stage >= 5
                          ? [_C.green, _C.greenDark]
                          : [_C.gradA, _C.gradB],
                    ),
                    boxShadow: _doPulse
                        ? [
                            BoxShadow(
                              color: (_stage >= 5 ? _C.green : _C.accent)
                                  .withOpacity(0.35),
                              blurRadius: _pulseAnim.value,
                              spreadRadius: _pulseAnim.value * 0.3,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(_blobIcon, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: _badgeColor,
            borderRadius: BorderRadius.circular(20),
            border: (_rejected || _stage == 8)
                ? Border.all(color: _C.rejectBdr, width: 0.5)
                : null,
          ),
          child: Text(
            _badgeTxt,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _badgeTxtColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _stageTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _C.txt1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _stageSub,
          textAlign: TextAlign.center,
          maxLines: 3,
          style: const TextStyle(fontSize: 11, color: _C.txt2, height: 1.7),
        ),
        const SizedBox(height: 12),
        if (_showDots)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) => _BounceDot(delayMs: i * 200)),
          ),
      ],
    ),
  );

  Widget _buildStepBar() {
    const labels = ['Sent', 'Wait', 'Paid', 'Arrived', 'Done'];
    final display = _rejected ? 1 : _stage.clamp(0, 4);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          final isDone = i < display;
          final isActive = i == display;
          final isRej = _rejected && i == 1;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: (isDone || isActive) && !isRej
                          ? const LinearGradient(colors: [_C.gradA, _C.gradB])
                          : null,
                      color: isRej
                          ? _C.reject
                          : (isDone || isActive)
                          ? null
                          : const Color(0xFFE8EAF0),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(
                              Icons.check_rounded,
                              size: 12,
                              color: Colors.white,
                            )
                          : isRej
                          ? const Icon(
                              Icons.close_rounded,
                              size: 12,
                              color: Colors.white,
                            )
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? Colors.white
                                    : const Color(0xFFAAAAAA),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    width: 42,
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 7.5,
                        color: isRej
                            ? _C.reject
                            : isDone
                            ? _C.gradA
                            : isActive
                            ? _C.accent
                            : _C.muted,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
              if (i < 4)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 20,
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    gradient: isDone && !_rejected
                        ? const LinearGradient(colors: [_C.gradA, _C.gradB])
                        : null,
                    color: (isDone && !_rejected)
                        ? null
                        : const Color(0xFFE2E6F0),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildRejectionBanner() => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _C.rejectBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _C.rejectBdr),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _C.reject.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.cancel_outlined, size: 18, color: _C.reject),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Request Declined',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _C.reject,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'The worker has declined your request. Go back and select another worker.',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFFB91C1C),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildArrivedBanner() => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF0FDF4),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFBBF7D0)),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _C.green.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.directions_walk_rounded,
            size: 18,
            color: _C.green,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Worker Has Arrived!',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _C.green,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'The worker is at your location. Inspection has started.',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF166534),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildQuotationReceivedCard() {
    final price = (_data['quotationTotalCost'] as num?)?.toDouble() ?? 0;
    final jobDesc = _data['quotationJobDesc'] as String? ?? '';
    final compTime = _data['quotationCompletionTime'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_rounded, size: 16, color: _C.blue),
              SizedBox(width: 8),
              Text(
                'NEW QUOTATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _C.muted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (jobDesc.isNotEmpty) ...[
            const Text(
              'Work Description',
              style: TextStyle(fontSize: 10, color: _C.muted),
            ),
            const SizedBox(height: 4),
            Text(
              jobDesc,
              style: const TextStyle(fontSize: 12, color: _C.txt1, height: 1.4),
            ),
            const SizedBox(height: 10),
          ],
          if (compTime.isNotEmpty)
            Row(
              children: [
                const Text(
                  'Est. Completion:',
                  style: TextStyle(fontSize: 11, color: _C.txt2),
                ),
                const SizedBox(width: 8),
                Text(
                  compTime,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _C.txt1,
                  ),
                ),
              ],
            ),
          if (compTime.isNotEmpty) const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_C.gradA, _C.gradB]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total Amount',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
                Text(
                  'LKR ${_fmt(price)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationPaidCard() {
    final price = (_data['quotationTotalCost'] as num?)?.toDouble() ?? 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.green.withOpacity(0.08), _C.gradB.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 0.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, size: 44, color: _C.green),
          const SizedBox(height: 8),
          const Text(
            'Quotation Payment Done!',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _C.green,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'LKR ${_fmt(price)} paid successfully',
            style: const TextStyle(fontSize: 12, color: _C.txt2),
          ),
          const SizedBox(height: 8),
          const Text(
            'Work is now in progress. You will be notified when done.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: _C.muted, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationDeclinedCard() => Container(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _C.rejectBg,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _C.rejectBdr),
    ),
    child: Column(
      children: [
        const Icon(Icons.cancel_outlined, size: 44, color: _C.reject),
        const SizedBox(height: 8),
        const Text(
          'Inspection was completed',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _C.reject,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'You declined the quotation. The inspection has been completed.\nWould you like to leave a review?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: Color(0xFFB91C1C), height: 1.5),
        ),
      ],
    ),
  );

  Widget _buildSummaryCard() {
    final category = _data['category'] as String? ?? '—';
    final address = _data['address'] as String? ?? '—';
    final shortId = _requestId.length >= 8
        ? _requestId.substring(0, 8).toUpperCase()
        : _requestId.toUpperCase();
    String estLabel = 'Est. Response', estVal = 'Calculating…';
    Color estColor = _C.accent;
    String statusTxt = 'Submitted';
    Color statusColor = _C.accent;
    if (_rejected) {
      estLabel = 'Status';
      estVal = 'Declined';
      estColor = _C.reject;
      statusTxt = 'Declined';
      statusColor = _C.reject;
    } else {
      switch (_stage) {
        case 1:
          estLabel = 'Est. Response';
          estVal = '~5–10 min';
          estColor = _C.accent;
          statusTxt = 'Pending';
          statusColor = _C.accent;
          break;
        case 2:
          estLabel = 'Worker ETA';
          estVal = '~8 min';
          estColor = _C.orange;
          statusTxt = 'Accepted';
          statusColor = _C.orange;
          break;
        case 3:
          estLabel = 'Work Status';
          estVal = 'On The Way';
          estColor = _C.blue;
          statusTxt = 'Paid';
          statusColor = _C.blue;
          break;
        case 4:
          estLabel = 'Work Status';
          estVal = 'In Progress';
          estColor = _C.orange;
          statusTxt = 'Arrived';
          statusColor = _C.orange;
          break;
        case 5:
          estLabel = 'Work Status';
          estVal = 'Completed';
          estColor = _C.green;
          statusTxt = 'Completed';
          statusColor = _C.green;
          break;
        case 6:
          estLabel = 'Work Status';
          estVal = 'Quotation Sent';
          estColor = _C.blue;
          statusTxt = 'Quotation';
          statusColor = _C.blue;
          break;
        case 7:
          estLabel = 'Work Status';
          estVal = 'Quotation Paid';
          estColor = _C.green;
          statusTxt = 'Paid';
          statusColor = _C.green;
          break;
        case 8:
          estLabel = 'Work Status';
          estVal = 'Declined';
          estColor = _C.reject;
          statusTxt = 'Declined';
          statusColor = _C.reject;
          break;
      }
    }
    return _SumCard(
      title: _stage >= 3 ? 'SERVICE SUMMARY' : 'REQUEST SUMMARY',
      rows: [
        _SumRow(label: 'Request ID', value: '#$shortId'),
        _SumRow(label: 'Category', value: category),
        _SumRow(label: 'Address', value: address),
        _SumRow(label: estLabel, value: estVal, valueColor: estColor),
        if (_stage >= 2)
          _SumRow(
            label: 'Worker',
            value: _data['workerName'] as String? ?? '—',
          ),
        _SumRow(label: 'Status', value: statusTxt, valueColor: statusColor),
      ],
    );
  }

  Widget _buildWorkerCard() {
    final name = _data['workerName'] as String? ?? 'Worker';
    final cat = _data['category'] as String? ?? '';
    final rating = (_data['workerRating'] as num?)?.toDouble() ?? 4.5;
    final initials = name
        .trim()
        .split(' ')
        .map((p) => p.isNotEmpty ? p[0] : '')
        .take(2)
        .join()
        .toUpperCase();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.cardBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [_C.gradA, _C.gradB]),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _C.txt1,
                  ),
                ),
                Text(cat, style: const TextStyle(fontSize: 10, color: _C.txt2)),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 14, color: _C.star),
              const SizedBox(width: 3),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _C.star,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
        Row(
          children: [
            const Icon(Icons.receipt_long_outlined, size: 14, color: _C.green),
            const SizedBox(width: 6),
            Text(
              _stage >= 3 ? 'PAYMENT SUMMARY' : 'BILL SUMMARY',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _C.muted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _billRow('Inspection Fee', _inspectionFee, isFixed: true),
        _billRow('Distance Fee', _distanceFee),
        _billRow('Service Fee (5%)', _serviceFee),
        const Divider(height: 16, color: _C.cardBorder, thickness: 1.5),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Total',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _C.txt1,
                ),
              ),
            ),
            Text(
              'LKR ${_fmt(_totalAmount)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _C.accent,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _billRow(String label, double amount, {bool isFixed = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: _C.txt2),
                  ),
                  if (isFixed) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Fixed',
                        style: TextStyle(
                          fontSize: 8,
                          color: _C.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              'LKR ${_fmt(amount)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _C.txt1,
              ),
            ),
          ],
        ),
      );

  Widget _buildPaymentConfirmedBadge() => Container(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFECFDF5),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFBBF7D0), width: 0.5),
    ),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _C.green.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: _C.green,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Confirmed',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _C.green,
              ),
            ),
            Text(
              'LKR ${_fmt(_totalAmount)} paid successfully',
              style: const TextStyle(fontSize: 10, color: Color(0xFF166534)),
            ),
          ],
        ),
        const Spacer(),
        const Icon(Icons.verified_rounded, size: 18, color: _C.green),
      ],
    ),
  );

  Widget _buildCustomerTimerCard() => Container(
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
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_C.orange, Color(0xFFD14A08)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.timer_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'INSPECTION IN PROGRESS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _C.muted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFED7AA), width: 0.5),
            ),
            child: Text(
              _timerDisplay,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: _C.orange,
                letterSpacing: 2,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Time elapsed since worker arrived',
            style: TextStyle(fontSize: 10, color: _C.muted),
          ),
        ),
      ],
    ),
  );

  Widget _buildMapSection() {
    final custLat = (_data['latitude'] as num?)?.toDouble() ?? 6.9271;
    final custLng = (_data['longitude'] as num?)?.toDouble() ?? 79.8612;
    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('customer'),
        position: LatLng(custLat, custLng),
        infoWindow: const InfoWindow(title: 'Job Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      ),
    };
    if (_workerLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('worker'),
          position: _workerLatLng!,
          infoWindow: const InfoWindow(
            title: 'Your Worker',
            snippet: 'Live location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }
    return Container(
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
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_C.gradA, _C.gradB]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _stage == 4 ? 'WORKER LOCATION' : 'LIVE WORKER TRACKING',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _C.muted,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              _LiveDot(),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 240,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _workerLatLng ?? LatLng(custLat, custLng),
                  zoom: 15,
                ),
                onMapCreated: (c) => _mapController = c,
                markers: markers,
                polylines: _workerLatLng != null && _stage == 3
                    ? {
                        Polyline(
                          polylineId: const PolylineId('route'),
                          points: [_workerLatLng!, LatLng(custLat, custLng)],
                          color: _C.accent,
                          width: 3,
                          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
                        ),
                      }
                    : {},
                myLocationEnabled: false,
                zoomControlsEnabled: false,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _dotLegend(_C.gradB, 'Job Location'),
              const SizedBox(width: 16),
              _dotLegend(_C.gradA, 'Worker (Live)'),
              if (_workerLatLng == null) ...[
                const SizedBox(width: 8),
                const Text(
                  'Locating worker…',
                  style: TextStyle(fontSize: 9, color: _C.muted),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _dotLegend(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 10, color: _C.txt2)),
    ],
  );

  Widget _buildCompletedSummary() {
    final ts = _data['completedAt'] as Timestamp?;
    final paidAt = _data['paidAt'] as Timestamp?;
    final description = _data['description'] as String? ?? '—';
    final address = _data['address'] as String? ?? '—';
    final workerName = _data['workerName'] as String? ?? '—';
    final category = _data['category'] as String? ?? '—';
    final jobDuration = _data['jobDuration'] as int?;
    final imageUrls =
        (_data['imageUrls'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    String durationStr = '';
    if (jobDuration != null) {
      final m = jobDuration ~/ 60;
      final s = jobDuration % 60;
      durationStr = '${m}m ${s}s';
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_C.green.withOpacity(0.08), _C.gradB.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFBBF7D0), width: 0.5),
          ),
          child: Column(
            children: [
              const Icon(Icons.verified_rounded, size: 44, color: _C.green),
              const SizedBox(height: 8),
              const Text(
                'Inspection Complete',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _C.green,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'By $workerName  •  $category',
                style: const TextStyle(fontSize: 10, color: _C.txt2),
              ),
              if (durationStr.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Duration: $durationStr',
                  style: const TextStyle(fontSize: 10, color: _C.muted),
                ),
              ],
              if (ts != null) ...[
                const SizedBox(height: 6),
                Text(
                  _fmtTs(ts),
                  style: const TextStyle(fontSize: 9, color: _C.muted),
                ),
              ],
            ],
          ),
        ),
        _detailCard('WORK DETAILS', [
          _SumRow(label: 'Address', value: address),
          _SumRow(label: 'Description', value: description),
        ]),
        _detailCard('PAYMENT SUMMARY', [
          _SumRow(
            label: 'Inspection Fee',
            value: 'LKR ${_fmt(_inspectionFee)}',
          ),
          _SumRow(label: 'Distance Fee', value: 'LKR ${_fmt(_distanceFee)}'),
          _SumRow(label: 'Service Fee', value: 'LKR ${_fmt(_serviceFee)}'),
          _SumRow(
            label: 'Total Paid',
            value: 'LKR ${_fmt(_totalAmount)}',
            valueColor: _C.green,
          ),
          if (paidAt != null) _SumRow(label: 'Paid At', value: _fmtTs(paidAt)),
        ]),
        if (imageUrls.isNotEmpty)
          Container(
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
                const Text(
                  'INSPECTION PHOTOS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _C.muted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: imageUrls.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(imageUrls[i], fit: BoxFit.cover),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _detailCard(String title, List<_SumRow> rows) => Container(
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _C.muted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        ...rows.map(
          (r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    r.label,
                    style: const TextStyle(fontSize: 11, color: _C.txt2),
                  ),
                ),
                Expanded(
                  child: Text(
                    r.value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: r.valueColor ?? _C.txt1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  String _fmtTs(Timestamp ts) {
    final dt = ts.toDate().toLocal();
    final h = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    final mm = dt.minute.toString().padLeft(2, '0');
    const mo = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${mo[dt.month - 1]} ${dt.day}, ${dt.year}  $h:$mm $ap';
  }

  Widget _buildJobDoneCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF16A34A), Color(0xFF1E8449)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'QUOTATION SUCCESSFULLY COMPLETED!',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16A34A),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBF7D0), width: 0.5),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 14,
                  color: Color(0xFF16A34A),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The worker has marked the job as done. Thank you for using SkillFox!',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF16A34A),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Please take a moment to leave a review for the worker.',
            style: TextStyle(fontSize: 11, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() => Container(
    color: Colors.white,
    padding: EdgeInsets.fromLTRB(
      16,
      14,
      16,
      MediaQuery.of(context).padding.bottom + 20,
    ),
    child: _bottomContent(),
  );

  Widget _bottomContent() {
    if (_rejected)
      return _gradBtn(
        label: 'Go Back',
        colors: [_C.reject, const Color(0xFFDC2626)],
        onTap: () => Navigator.pop(context),
      );
    switch (_stage) {
      case 2:
        return _gradBtn(
          label: 'Pay Now  —  LKR ${_fmt(_totalAmount)}',
          colors: [_C.gradA, _C.gradB],
          onTap: _openPayment,
        );
      case 3:
        return _infoBar(
          icon: Icons.directions_car_rounded,
          text: 'Worker is on the way to your location',
          color: _C.blue,
          bg: const Color(0xFFEFF6FF),
          border: const Color(0xFFBFDBFE),
        );
      case 4:
        return _infoBar(
          icon: Icons.build_rounded,
          text: 'Worker is performing the inspection',
          color: _C.orange,
          bg: const Color(0xFFFFF7ED),
          border: const Color(0xFFFED7AA),
        );
      case 5:
        return _infoBar(
          icon: Icons.receipt_long_rounded,
          text: 'Inspection done. Waiting for quotation from worker...',
          color: _C.blue,
          bg: const Color(0xFFEFF6FF),
          border: const Color(0xFFBFDBFE),
        );
      case 6:
        return _gradBtn(
          label: 'View & Respond to Quotation',
          colors: [_C.gradA, _C.gradB],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerQuotationViewScreen(
                requestId: _requestId,
                requestData: _data,
              ),
            ),
          ),
        );
      case 7:
        return _infoBar(
          icon: Icons.hourglass_top_rounded,
          text: 'Payment confirmed! Waiting for worker to complete the job...',
          color: _C.green,
          bg: const Color(0xFFECFDF5),
          border: const Color(0xFFBBF7D0),
        );
      case 9:
        return _gradBtn(
          label: 'Leave a Review',
          colors: [_C.gradA, _C.gradB],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReviewScreen(
                requestId: _requestId,
                requestData: _data,
                isWorker: false,
              ),
            ),
          ),
        );
      case 8:
        return _gradBtn(
          label: 'Leave a Review',
          colors: [_C.gradA, _C.gradB],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReviewScreen(
                requestId: _requestId,
                requestData: _data,
                isWorker: false,
              ),
            ),
          ),
        );
      default:
        return _outlineBtn(label: 'Cancel Request', onTap: _handleCancel);
    }
  }

  void _openPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          requestId: _requestId,
          totalAmount: _totalAmount,
          inspectionFee: _inspectionFee,
          distanceFee: _distanceFee,
          serviceFee: _serviceFee,
        ),
      ),
    );
  }

  Widget _gradBtn({
    required String label,
    required List<Color> colors,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );

  Widget _infoBar({
    required IconData icon,
    required String text,
    required Color color,
    required Color bg,
    required Color border,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: border, width: 0.5),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _outlineBtn({required String label, required VoidCallback onTap}) =>
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
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _C.txt2,
              ),
            ),
          ),
        ),
      );
}

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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _C.muted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        ...rows.map(
          (r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    r.label,
                    style: const TextStyle(fontSize: 11, color: _C.txt2),
                  ),
                ),
                Text(
                  r.value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: r.valueColor ?? _C.txt1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _a = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _C.green.withOpacity(_a.value),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'LIVE',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: _C.green.withOpacity(_a.value),
          ),
        ),
      ],
    ),
  );
}

class _ArcPainter extends CustomPainter {
  final double? progress;
  final bool spinning, rejected, completed;
  final double spinValue;
  const _ArcPainter({
    this.progress,
    required this.spinning,
    required this.spinValue,
    this.rejected = false,
    this.completed = false,
  });
  @override
  void paint(Canvas canvas, Size size) {
    const cx = 50.0, cy = 50.0, r = 43.0, sw = 5.0;
    canvas.drawCircle(
      const Offset(cx, cy),
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..color = const Color(0xFFE8E6F8),
    );
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..shader =
          (rejected
                  ? const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    )
                  : completed
                  ? const LinearGradient(
                      colors: [Color(0xFF16A34A), Color(0xFF1E8449)],
                    )
                  : const LinearGradient(colors: [_C.gradA, _C.gradB]))
              .createShader(
                Rect.fromCircle(center: const Offset(cx, cy), radius: r),
              );
    if (spinning) {
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(cx, cy), radius: r),
        spinValue * 2 * math.pi,
        math.pi * 1.4,
        false,
        p,
      );
    } else {
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(cx, cy), radius: r),
        -math.pi / 2,
        2 * math.pi * (progress ?? 1.0),
        false,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter o) => true;
}

class _BounceDot extends StatefulWidget {
  final int delayMs;
  const _BounceDot({required this.delayMs});
  @override
  State<_BounceDot> createState() => _BounceDotState();
}

class _BounceDotState extends State<_BounceDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _a = Tween<double>(
      begin: 0,
      end: -6,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Transform.translate(
      offset: Offset(0, _a.value),
      child: Container(
        width: 7,
        height: 7,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [_C.gradA, _C.gradB]),
        ),
      ),
    ),
  );
}