import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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

  // All raw transactions from Firestore
  List<Map<String, dynamic>> _allTx = [];
  // Latest 5 for the list
  List<Map<String, dynamic>> _recentTx = [];

  @override
  void initState() {
    super.initState();
    _fetchEarnings();
  }

  Future<void> _fetchEarnings() async {
    setState(() => _isLoading = true);
    try {
      final uid = _user?.uid;
      if (uid == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('earnings')
          .orderBy('createdAt', descending: true)
          .get();

      final docs = snapshot.docs;
      final now = DateTime.now();
      double total = 0;
      double thisMonth = 0;
      final List<Map<String, dynamic>> txList = [];

      for (final doc in docs) {
        final data = doc.data();
        final double amount = (data['amount'] ?? 0).toDouble();
        final Timestamp? ts = data['createdAt'];
        final DateTime date = ts?.toDate() ?? DateTime.now();

        total += amount;
        if (date.year == now.year && date.month == now.month) {
          thisMonth += amount;
        }

        txList.add({
          'taskName': data['taskName'] ?? 'Task',
          'amount': amount,
          'date': date,
        });
      }

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

  void _buildChart() {
    if (_selectedTab == 'Daily') {
      _buildDailyChart();
    } else {
      _buildMonthlyChart();
    }
  }

  void _buildDailyChart() {
    final now = DateTime.now();
    final List<String> labels = [];
    final List<double> values = List.filled(7, 0);
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (final tx in _allTx) {
      final date = tx['date'] as DateTime;
      final diff = now.difference(date).inDays;
      if (diff >= 0 && diff < 7) {
        values[6 - diff] += tx['amount'] as double;
      }
    }

    labels.clear();
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      labels.add(dayNames[day.weekday - 1]);
    }

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final List<BarChartGroupData> groups = [];

    for (int i = 0; i < 7; i++) {
      final isLast = i == 6;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: values[i],
              gradient: LinearGradient(
                colors: isLast
                    ? [const Color(0xFF4A2D8F), const Color(0xFF7C4DCC)]
                    : [const Color(0xFF7C4DCC), const Color(0xFFB48FFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              width: 28,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
                bottom: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    _barGroups = groups;
    _barLabels = labels;
    _maxY = maxVal == 0 ? 10000 : maxVal * 1.35;
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

    final List<double> values = List.filled(6, 0);
    final List<String> labels = [];

    // Build month labels for last 6 months
    for (int i = 5; i >= 0; i--) {
      final dt = DateTime(now.year, now.month - i, 1);
      labels.add(monthNames[dt.month - 1]);
    }

    for (final tx in _allTx) {
      final date = tx['date'] as DateTime;
      final monthDiff = (now.year - date.year) * 12 + (now.month - date.month);
      if (monthDiff >= 0 && monthDiff < 6) {
        values[5 - monthDiff] += tx['amount'] as double;
      }
    }

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final List<BarChartGroupData> groups = [];

    for (int i = 0; i < 6; i++) {
      final isLast = i == 5;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: values[i],
              gradient: LinearGradient(
                colors: isLast
                    ? [const Color(0xFF4A2D8F), const Color(0xFF7C4DCC)]
                    : [const Color(0xFF7C4DCC), const Color(0xFFB48FFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              width: 28,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
                bottom: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    _barGroups = groups;
    _barLabels = labels;
    _maxY = maxVal == 0 ? 50000 : maxVal * 1.35;
  }

  String _formatRs(double val) {
    if (val >= 1000) {
      return 'Rs ${(val / 1000).toStringAsFixed(val % 1000 == 0 ? 0 : 1)}K';
    }
    return 'Rs ${val.toStringAsFixed(0)}';
  }

  String _monthName(int month) {
    const names = [
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
    return names[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF7C4DCC)),
              )
            : RefreshIndicator(
                color: const Color(0xFF7C4DCC),
                onRefresh: _fetchEarnings,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Title ──
                        const Text(
                          'Earnings',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF222222),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // ── Profile Card ──
                        _buildProfileCard(),
                        const SizedBox(height: 16),

                        // ── Stats Grid ──
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'This Month',
                                value: 'Rs ${_thisMonth.toStringAsFixed(0)}',
                                badge: '▲ This Month',
                                badgeColor: const Color(0xFF1A8A44),
                                badgeBg: const Color(0xFFD4F7E1),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'Total Earnings',
                                value:
                                    'Rs ${_totalEarnings.toStringAsFixed(0)}',
                                sub: 'Since joining',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _TaskCard(
                                count: _completedTasks.toString(),
                                progress: (_completedTasks % 25) / 25,
                                sub: '${_completedTasks % 25}/25 monthly goal',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'Avg Task Fee',
                                value: 'Rs ${_avgTaskFee.toStringAsFixed(0)}',
                                sub: 'Per task',
                                subColor: const Color(0xFF7C4DCC),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Breakdown Title ──
                        const Text(
                          'Earnings Breakdown',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D1B5E),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Tab Toggle ──
                        _buildTabToggle(),
                        const SizedBox(height: 12),

                        // ── Chart Card ──
                        _buildChartCard(),
                        const SizedBox(height: 20),

                        // ── Recent Transactions ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Recent Transactions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D1B5E),
                              ),
                            ),
                            Text(
                              'View all →',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7C4DCC),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_recentTx.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'No transactions yet',
                                style: TextStyle(
                                  color: Color(0xFF9080B8),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        else
                          ..._recentTx.map((tx) => _buildTransactionItem(tx)),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // ── Profile Card ──
  Widget _buildProfileCard() {
    final name = _user?.displayName ?? 'User';
    final photoUrl = _user?.photoURL;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE5FF)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFC4A0FF),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D1B5E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE5FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 12,
                            color: Color(0xFF7C4DCC),
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Verified',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7C4DCC),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _user?.email ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9080B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Toggle ──
  Widget _buildTabToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EAFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ['Daily', 'Monthly'].map((tab) {
          final isActive = tab == _selectedTab;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedTab = tab);
                _buildChart();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF7C4DCC).withOpacity(0.12),
                            blurRadius: 8,
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
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? const Color(0xFF2D1B5E)
                        : const Color(0xFF9080B8),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Chart Card ──
  Widget _buildChartCard() {
    final total = _selectedTab == 'Daily' ? _thisMonth : _totalEarnings;
    final label = _selectedTab == 'Daily'
        ? '7-Day Overview'
        : '6-Month Overview';
    final highest = _barGroups.isNotEmpty
        ? _barGroups
              .map((g) => g.barRods.first.toY)
              .reduce((a, b) => a > b ? a : b)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE5FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9080B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs ${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D1B5E),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Highest',
                    style: TextStyle(fontSize: 11, color: Color(0xFF9080B8)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatRs(highest),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7C4DCC),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: _barGroups.isEmpty
                ? const Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(color: Color(0xFF9080B8)),
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
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: Color(0xFFEDE5FF),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 44,
                            getTitlesWidget: (value, meta) {
                              if (value == 0 || value == _maxY) {
                                return const SizedBox();
                              }
                              return Text(
                                _formatRs(value),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFF9080B8),
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
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= _barLabels.length) {
                                return const SizedBox();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _barLabels[idx],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF9080B8),
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
                          getTooltipColor: (_) => const Color(0xFF2D1B5E),
                          tooltipRoundedRadius: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              'Rs ${rod.toY.toStringAsFixed(0)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Transaction Item ──
  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    final date = tx['date'] as DateTime;
    final amount = tx['amount'] as double;
    final taskName = tx['taskName'] as String;
    final dateStr =
        '${date.day} ${_monthName(date.month)}, ${date.year} · Completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDE5FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFD4F7E1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🌾', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
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
                    color: Color(0xFF2D1B5E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF9080B8),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+Rs ${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3ECF6A),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Stat Card
// ─────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color? subColor;
  final String? badge;
  final Color? badgeColor;
  final Color? badgeBg;

  const _StatCard({
    required this.label,
    required this.value,
    this.sub,
    this.subColor,
    this.badge,
    this.badgeColor,
    this.badgeBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE5FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9080B8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          if (sub != null && subColor != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                sub!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: subColor,
                ),
              ),
            ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D1B5E),
              letterSpacing: -0.5,
            ),
          ),
          if (sub != null && subColor == null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                sub!,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9080B8)),
              ),
            ),
          if (badge != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: badgeColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Task Card
// ─────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  final String count;
  final double progress;
  final String sub;

  const _TaskCard({
    required this.count,
    required this.progress,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE5FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Completed Tasks',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9080B8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            count,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D1B5E),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFEDE5FF),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF3ECF6A),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            sub,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9080B8)),
          ),
        ],
      ),
    );
  }
}
