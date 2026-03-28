// category_b_worker_job_screen.dart
// Category B — Worker job progress tracker.
// Stages: accepted → inprogress (paid) → arrived → job_done
// Worker can also view the hours they spent and confirm completion.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class _C {
  static const gradA = Color(0xFF10B981);
  static const gradB = Color(0xFF059669);
  static const accent = Color(0xFF10B981);
  static const bg = Color(0xFFF4F6FA);
  static const cardBdr = Color(0xFFE2E6F0);
  static const txt1 = Color(0xFF111111);
  static const txt2 = Color(0xFF888888);
  static const muted = Color(0xFFA0A4B0);
  static const green = Color(0xFF16A34A);
  static const greenDk = Color(0xFF1E8449);
  static const orange = Color(0xFFEA580C);
  static const blue = Color(0xFF2563EB);
  static const red = Color(0xFFEF4444);
}

class CategoryBWorkerJobScreen extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const CategoryBWorkerJobScreen({
    super.key,
    required this.requestId,
    required this.requestData,
  });

  @override
  State<CategoryBWorkerJobScreen> createState() =>
      _CategoryBWorkerJobScreenState();
}

class _CategoryBWorkerJobScreenState extends State<CategoryBWorkerJobScreen> {
  late Map<String, dynamic> _data;
  bool _actionLoading = false;

  // elapsed timer
  Timer? _timer;
  int _elapsedSeconds = 0;
  DateTime? _arrivedAt;

  // stage: 0=accepted/pending-payment, 1=paid/inprogress, 2=arrived, 3=done
  int _stage = 0;

  StreamSubscription<DocumentSnapshot>? _sub;

  @override
  void initState() {
    super.initState();
    _data = {...widget.requestData, 'id': widget.requestId};
    _setStage(_data['status'] as String? ?? 'accepted');
    _sub = FirebaseFirestore.instance
        .collection('requests')
        .doc(widget.requestId)
        .snapshots()
        .listen((snap) {
          if (!snap.exists || !mounted) return;
          final d = Map<String, dynamic>.from(snap.data()!);
          d['id'] = snap.id;
          setState(() {
            _data = d;
            _setStage(d['status'] as String? ?? 'accepted');
          });
        });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _setStage(String status) {
    switch (status) {
      case 'quotation_sent':
      case 'accepted':
        _stage = 0;
        break;
      case 'inprogress':
        _stage = 1;
        break;
      case 'arrived':
        _stage = 2;
        if (_arrivedAt == null && _data['arrivedAt'] != null) {
          try {
            _arrivedAt = (_data['arrivedAt'] as dynamic).toDate() as DateTime;
            _elapsedSeconds = DateTime.now().difference(_arrivedAt!).inSeconds;
            _startTimer();
          } catch (_) {}
        }
        break;
      case 'job_done':
      case 'completed':
        _stage = 3;
        _timer?.cancel();
        break;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  String get _timerDisplay {
    final h = _elapsedSeconds ~/ 3600;
    final m = (_elapsedSeconds % 3600) ~/ 60;
    final s = _elapsedSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _markArrived() async {
    setState(() => _actionLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
            'status': 'arrived',
            'arrivedAt': FieldValue.serverTimestamp(),
          });
      final now = DateTime.now();
      setState(() {
        _arrivedAt = now;
        _elapsedSeconds = 0;
        _stage = 2;
      });
      _startTimer();
    } catch (e) {
      _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _markJobDone() async {
    setState(() => _actionLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
            'status': 'job_done',
            'jobDoneAt': FieldValue.serverTimestamp(),
            'actualSeconds': _elapsedSeconds,
          });
      _timer?.cancel();
      // Worker just pops back — the customer will see the status change
      // on their screen and get the "Leave a Review" button.
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? _C.red : _C.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _fmt(num n) {
    final s = n.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  // ── UI ───────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final customerName = _data['customerName'] as String? ?? 'Customer';
    final category = _data['category'] as String? ?? '';
    final address = _data['address'] as String? ?? '';
    final total = (_data['bTotalQuoted'] as num?)?.toDouble() ?? 0;
    final pricingType = _data['bPricingType'] as String? ?? 'fixed';

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          // header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_C.gradA, _C.gradB]),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 4,
              bottom: 16,
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
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Job Progress',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$customerName · $category',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                _stageBadge(),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                children: [
                  // progress stepper
                  _buildStepper(),
                  const SizedBox(height: 16),

                  // timer (only while arrived)
                  if (_stage == 2) ...[
                    _buildTimerCard(),
                    const SizedBox(height: 16),
                  ],

                  // job details card
                  _buildDetailsCard(
                    customerName: customerName,
                    address: address,
                    total: total,
                    pricingType: pricingType,
                  ),
                ],
              ),
            ),
          ),

          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _stageBadge() {
    final labels = ['Accepted', 'Paid', 'On-Site', 'Done'];
    final colors = [_C.orange, _C.blue, _C.accent, _C.green];
    final idx = _stage.clamp(0, 3);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        labels[idx],
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colors[idx],
        ),
      ),
    );
  }

  Widget _buildStepper() {
    final steps = [
      'Accepted',
      'Payment\nReceived',
      'Arrived\nOn-Site',
      'Job\nComplete',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.cardBdr, width: 0.5),
      ),
      child: Row(
        children: List.generate(steps.length, (i) {
          final done = i <= _stage;
          final current = i == _stage;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i <= _stage ? _C.accent : _C.cardBdr,
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? _C.accent : Colors.white,
                        border: Border.all(
                          color: done ? _C.accent : _C.cardBdr,
                          width: 2,
                        ),
                        boxShadow: current
                            ? [
                                BoxShadow(
                                  color: _C.accent.withOpacity(0.35),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                      ),
                      child: done
                          ? const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: current ? FontWeight.w700 : FontWeight.w400,
                        color: done ? _C.accent : _C.muted,
                      ),
                    ),
                  ],
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i < _stage ? _C.accent : _C.cardBdr,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimerCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [_C.gradA, _C.gradB]),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined, size: 14, color: Colors.white70),
            SizedBox(width: 6),
            Text(
              'TIME ON SITE',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _timerDisplay,
          style: const TextStyle(
            fontSize: 42,
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'hours : minutes : seconds',
          style: TextStyle(fontSize: 9, color: Colors.white54),
        ),
      ],
    ),
  );

  Widget _buildDetailsCard({
    required String customerName,
    required String address,
    required double total,
    required String pricingType,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _C.cardBdr, width: 0.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.work_outline_rounded, size: 14, color: _C.accent),
            SizedBox(width: 6),
            Text(
              'JOB DETAILS',
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
        _dRow(Icons.person_outline_rounded, 'Customer', customerName),
        if (address.isNotEmpty)
          _dRow(Icons.location_on_outlined, 'Address', address),
        _dRow(
          Icons.payments_outlined,
          'Pricing',
          pricingType == 'hourly' ? 'Hourly Rate' : 'Fixed Price',
        ),
        const Divider(height: 16, color: _C.cardBdr),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Agreed Amount',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _C.txt1,
                ),
              ),
            ),
            Text(
              'LKR ${_fmt(total)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _C.accent,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _dRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 14, color: _C.muted),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 11, color: _C.txt2)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _C.txt1,
            ),
          ),
        ),
      ],
    ),
  );

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
    switch (_stage) {
      case 0:
        return _infoBar(
          icon: Icons.payments_outlined,
          text: 'Waiting for customer to complete payment',
          color: _C.orange,
          bg: const Color(0xFFFFF7ED),
          border: const Color(0xFFFED7AA),
        );
      case 1:
        return _gradBtn(
          label: _actionLoading ? 'Please wait…' : 'Mark as Arrived',
          icon: Icons.location_on_rounded,
          onTap: _actionLoading ? null : _markArrived,
        );
      case 2:
        return _gradBtn(
          label: _actionLoading ? 'Please wait…' : 'Mark Job as Done',
          icon: Icons.check_circle_rounded,
          onTap: _actionLoading ? null : _markJobDone,
        );
      case 3:
        return _infoBar(
          icon: Icons.celebration_rounded,
          text: 'Job completed successfully! Great work.',
          color: _C.green,
          bg: const Color(0xFFECFDF5),
          border: const Color(0xFFBBF7D0),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _gradBtn({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: onTap == null ? 0.6 : 1.0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_C.gradA, _C.gradB]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _actionLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: border, width: 0.5),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
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
}
