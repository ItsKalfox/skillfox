import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// ── Colour palette ──────────────────────────────────────────────────────────
class _K {
  static const bg = Color(0xFFF5F6FA);
  static const navy = Color(0xFF1A1D2E);
  static const indigo = Color(0xFF4B5FD6);
  static const indigoLt = Color(0xFF7B8FFF);
  static const green = Color(0xFF22C55E);
  static const greenDk = Color(0xFF16A34A);
  static const amber = Color(0xFFF59E0B);
  static const muted = Color(0xFF8E95AA);
  static const cardBg = Colors.white;
  static const divider = Color(0xFFEEF0F6);
}

class Earnings extends StatefulWidget {
  const Earnings({super.key});

  @override
  State<Earnings> createState() => _EarningsState();
}

class _EarningsState extends State<Earnings> {
  String _selectedTab = 'Daily';
  bool _isLoading = true;

  final User? _user = FirebaseAuth.instance.currentUser;

  List<BarChartGroupData> _barGroups = [];
  List<String> _barLabels = [];
  double _maxY = 0;

  double _thisMonth = 0;
  double _totalEarnings = 0;
  int _completedTasks = 0;
  double _avgTaskFee = 0;

  List<Map<String, dynamic>> _allTx = [];
  List<Map<String, dynamic>> _recentTx = [];

  static const _paidStatuses = [
    'completed',
    'quotation_sent',
    'quotation_paid',
    'job_done',
  ];

  @override
  void initState() {
    super.initState();
    _fetchEarnings();
  }

  // ── Data ────────────────────────────────────────────────────────────────
  Future<void> _fetchEarnings() async {
    setState(() => _isLoading = true);
    try {
      final uid = _user?.uid;
      if (uid == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('workerId', isEqualTo: uid)
          .where('status', whereIn: _paidStatuses)
          .get();

      final docs = snapshot.docs;
      final now = DateTime.now();
      double total = 0, thisMonth = 0;
      final List<Map<String, dynamic>> txList = [];

      for (final doc in docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';

        double amount = 0;
        if (status == 'job_done' || status == 'quotation_paid') {
          final labour =
              (data['quotationLabourCost'] ?? data['labourCost'] ?? 0)
                  .toDouble();
          final material =
              (data['quotationMaterialCost'] ?? data['materialCost'] ?? 0)
                  .toDouble();
          final quotTotal = (data['quotationTotalCost'] ?? 0).toDouble();
          amount = quotTotal > 0 ? quotTotal : (labour + material);
        } else {
          amount =
              (data['totalPaid'] ??
                      data['totalAmount'] ??
                      data['quotationPrice'] ??
                      0)
                  .toDouble();
        }

        Timestamp? ts = status == 'job_done'
            ? (data['jobDoneAt'] ?? data['completedAt'] ?? data['createdAt'])
            : (data['completedAt'] ?? data['paidAt'] ?? data['createdAt']);
        final DateTime date = ts?.toDate() ?? DateTime.now();
        final String taskName = data['category'] ?? data['service'] ?? 'Task';

        total += amount;
        if (date.year == now.year && date.month == now.month)
          thisMonth += amount;

        txList.add({
          'taskName': taskName,
          'amount': amount,
          'date': date,
          'status': status,
        });
      }

      txList.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
      );

      _totalEarnings = total;
      _thisMonth = thisMonth;
      _completedTasks = docs.length;
      _avgTaskFee = docs.isNotEmpty ? total / docs.length : 0;
      _allTx = txList;
      _recentTx = txList.take(5).toList();

      _buildChart();
    } catch (e) {
      debugPrint('Error fetching earnings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _buildChart() =>
      _selectedTab == 'Daily' ? _buildDailyChart() : _buildMonthlyChart();

  void _buildDailyChart() {
    final now = DateTime.now();
    final values = List.filled(7, 0.0);
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (final tx in _allTx) {
      final diff = now.difference(tx['date'] as DateTime).inDays;
      if (diff >= 0 && diff < 7) values[6 - diff] += tx['amount'] as double;
    }
    final labels = List.generate(
      7,
      (i) => dayNames[now.subtract(Duration(days: 6 - i)).weekday - 1],
    );
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    _barGroups = _buildBars(values);
    _barLabels = labels;
    _maxY = maxVal == 0 ? 10000 : maxVal * 1.4;
  }

  void _buildMonthlyChart() {
    final now = DateTime.now();
    const monthNames = [
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
    final values = List.filled(6, 0.0);
    final labels = List.generate(
      6,
      (i) => monthNames[DateTime(now.year, now.month - (5 - i)).month - 1],
    );
    for (final tx in _allTx) {
      final date = tx['date'] as DateTime;
      final diff = (now.year - date.year) * 12 + (now.month - date.month);
      if (diff >= 0 && diff < 6) values[5 - diff] += tx['amount'] as double;
    }
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    _barGroups = _buildBars(values);
    _barLabels = labels;
    _maxY = maxVal == 0 ? 50000 : maxVal * 1.4;
  }

  List<BarChartGroupData> _buildBars(List<double> values) {
    return List.generate(values.length, (i) {
      final isLast = i == values.length - 1;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: values[i],
            gradient: LinearGradient(
              colors: isLast
                  ? [_K.indigo, _K.indigoLt]
                  : [_K.indigo.withOpacity(0.35), _K.indigoLt.withOpacity(0.5)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 22,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    });
  }

  String _fmt(double val) {
    if (val >= 1000) return 'Rs ${(val / 1000).toStringAsFixed(1)}K';
    return 'Rs ${val.toStringAsFixed(0)}';
  }

  String _monthName(int m) => [
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
  ][m - 1];

  String _statusLabel(String s) {
    switch (s) {
      case 'job_done':
        return 'Job Done';
      case 'quotation_paid':
        return 'Quotation Paid';
      case 'completed':
        return 'Inspection Done';
      default:
        return 'Completed';
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _K.bg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _K.indigo))
          : RefreshIndicator(
              color: _K.indigo,
              onRefresh: _fetchEarnings,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildHeroHeader(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildStatsRow(),
                          const SizedBox(height: 20),
                          _buildBreakdownCard(),
                          const SizedBox(height: 20),
                          _buildTransactionsSection(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Hero header with gradient + summary ─────────────────────────────────
  Widget _buildHeroHeader() {
    final name = _user?.displayName ?? 'Worker';
    final photoUrl = _user?.photoURL;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'W';

    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3B4FCA), Color(0xFF5B6FE8), Color(0xFF7B8FFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── App bar row ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Earnings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage: photoUrl != null
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl == null
                          ? Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Total earnings big number ──
              Text(
                'Rs ${_totalEarnings.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Total Earnings',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 28),

              // ── Two quick stats inside header ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _heroStat(
                        'This Month',
                        'Rs ${_thisMonth.toStringAsFixed(0)}',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    Expanded(
                      child: _heroStat(
                        'Avg per Job',
                        'Rs ${_avgTaskFee.toStringAsFixed(0)}',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Curved bottom edge ──
              Container(
                height: 28,
                decoration: const BoxDecoration(
                  color: _K.bg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroStat(String label, String value) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Colors.white.withOpacity(0.65),
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  // ── Stats row ────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            icon: Icons.check_circle_rounded,
            iconColor: _K.green,
            iconBg: const Color(0xFFEAFBF0),
            label: 'Completed',
            value: _completedTasks.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStat(
            icon: Icons.trending_up_rounded,
            iconColor: _K.amber,
            iconBg: const Color(0xFFFEF3C7),
            label: 'This Month',
            value: _fmt(_thisMonth),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStat(
            icon: Icons.receipt_long_rounded,
            iconColor: _K.indigo,
            iconBg: const Color(0xFFEEF0FF),
            label: 'Avg Fee',
            value: _fmt(_avgTaskFee),
          ),
        ),
      ],
    );
  }

  // ── Breakdown card (tab toggle + chart) ─────────────────────────────────
  Widget _buildBreakdownCard() {
    final highest = _barGroups.isNotEmpty
        ? _barGroups
              .map((g) => g.barRods.first.toY)
              .reduce((a, b) => a > b ? a : b)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: _K.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Breakdown',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _K.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedTab == 'Daily' ? 'Last 7 days' : 'Last 6 months',
                      style: const TextStyle(fontSize: 11, color: _K.muted),
                    ),
                  ],
                ),
                const Spacer(),
                if (highest > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF0FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_upward_rounded,
                          size: 11,
                          color: _K.indigo,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Peak ${_fmt(highest)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _K.indigo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Tab toggle ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: _K.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: ['Daily', 'Monthly'].map((tab) {
                  final active = tab == _selectedTab;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedTab = tab);
                        _buildChart();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          tab,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: active ? _K.navy : _K.muted,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Chart ──
          SizedBox(
            height: 180,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _barGroups.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bar_chart_rounded,
                            size: 40,
                            color: _K.muted.withOpacity(0.3),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No data yet',
                            style: TextStyle(color: _K.muted, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        maxY: _maxY,
                        minY: 0,
                        barGroups: _barGroups,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) =>
                              FlLine(color: _K.divider, strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 46,
                              getTitlesWidget: (v, _) {
                                if (v == 0 || v == _maxY)
                                  return const SizedBox();
                                return Text(
                                  _fmt(v),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: _K.muted,
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, _) {
                                final idx = v.toInt();
                                if (idx < 0 || idx >= _barLabels.length)
                                  return const SizedBox();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    _barLabels[idx],
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: _K.muted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => _K.navy,
                            getTooltipItem: (_, __, rod, ___) => BarTooltipItem(
                              _fmt(rod.toY),
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Transactions section ─────────────────────────────────────────────────
  Widget _buildTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _K.navy,
              ),
            ),
            Text(
              '${_recentTx.length} of ${_allTx.length}',
              style: const TextStyle(fontSize: 12, color: _K.muted),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_recentTx.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: _K.cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 44,
                  color: _K.muted.withOpacity(0.35),
                ),
                const SizedBox(height: 10),
                const Text(
                  'No transactions yet',
                  style: TextStyle(color: _K.muted, fontSize: 13),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: _K.cardBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: List.generate(_recentTx.length, (i) {
                final tx = _recentTx[i];
                final isLast = i == _recentTx.length - 1;
                return Column(
                  children: [
                    _buildTransactionItem(tx),
                    if (!isLast)
                      const Divider(
                        height: 1,
                        indent: 68,
                        endIndent: 20,
                        color: _K.divider,
                      ),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    final date = tx['date'] as DateTime;
    final amount = tx['amount'] as double;
    final taskName = tx['taskName'] as String;
    final status = tx['status'] as String;

    final Color iconBg;
    final Color iconColor;
    final IconData iconData;

    switch (status) {
      case 'job_done':
        iconBg = const Color(0xFFEAFBF0);
        iconColor = _K.green;
        iconData = Icons.handyman_rounded;
        break;
      case 'quotation_paid':
        iconBg = const Color(0xFFEEF0FF);
        iconColor = _K.indigo;
        iconData = Icons.receipt_rounded;
        break;
      default:
        iconBg = const Color(0xFFFEF3C7);
        iconColor = _K.amber;
        iconData = Icons.search_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  taskName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _K.navy,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${date.day} ${_monthName(date.month)} ${date.year}  ·  ${_statusLabel(status)}',
                  style: const TextStyle(fontSize: 11.5, color: _K.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+Rs ${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _K.green,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini stat card ──────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _K.navy,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: _K.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
