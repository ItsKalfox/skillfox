import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';

class RevenueScreen extends StatefulWidget {
  const RevenueScreen({super.key});

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  String _selectedPeriod = 'Last 30 Days';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payments')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final isLoading =
            snapshot.connectionState == ConnectionState.waiting;

        // Calculate stats
        double totalRevenue = 0;
        double totalCommission = 0;
        double totalRefunds = 0;
        int completedCount = 0;
        int pendingCount = 0;
        int failedCount = 0;

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status']?.toString() ?? '';
          final amount = (data['amount'] ?? 0).toDouble();
          final commission = (data['commission'] ?? 0).toDouble();

          if (status == 'completed') {
            totalRevenue += amount;
            totalCommission += commission;
            completedCount++;
          } else if (status == 'pending') {
            pendingCount++;
          } else if (status == 'failed') {
            failedCount++;
            totalRefunds += amount;
          }
        }

        double netRevenue = totalRevenue - totalRefunds;
        double avgTransaction =
            completedCount > 0 ? totalRevenue / completedCount : 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Revenue Overview',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary)),
                    SizedBox(height: 4),
                    Text('Track and analyze revenue performance',
                        style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPeriod,
                      items: const [
                        'Last 7 Days',
                        'Last 30 Days',
                        'Last 3 Months',
                        'Last Year'
                      ]
                          .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textPrimary))))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedPeriod = v!),
                      icon: const Icon(Icons.calendar_today_outlined,
                          size: 16, color: AppTheme.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats Cards
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      // Total Revenue - Blue card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(Icons.attach_money,
                                      color: Colors.white, size: 24),
                                  Icon(Icons.trending_up,
                                      color: Colors.white70, size: 20),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text('Total Revenue',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                'Rs. ${_formatAmount(totalRevenue)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Text('+12.5% from last month',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Net Revenue
                      Expanded(
                        child: _RevenueCard(
                          label: 'Net Revenue',
                          value: 'Rs. ${_formatAmount(netRevenue)}',
                          change: '+8.2% from last month',
                          changePositive: true,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Total Commission
                      Expanded(
                        child: _RevenueCard(
                          label: 'Total Commission',
                          value: 'Rs. ${_formatAmount(totalCommission)}',
                          change: '-3.1% from last month',
                          changePositive: false,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Avg Transaction
                      Expanded(
                        child: _RevenueCard(
                          label: 'Avg. Transaction',
                          value: 'Rs. ${_formatAmount(avgTransaction)}',
                          change: '+5.4% from last month',
                          changePositive: true,
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 24),

            // Chart + Breakdown Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Revenue Chart
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('Monthly Revenue vs Refunds',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary)),
                                SizedBox(height: 4),
                                Text(
                                    'Comparison of revenue and refunds over time',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: AppTheme.border),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Last 7 Months',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 220,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) =>
                                    FlLine(
                                  color: AppTheme.border,
                                  strokeWidth: 1,
                                  dashArray: [4, 4],
                                ),
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 55,
                                    getTitlesWidget: (value, meta) =>
                                        Text(
                                      '${(value / 1000).toInt()}k',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textHint),
                                    ),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      const months = [
                                        'Jan', 'Feb', 'Mar',
                                        'Apr', 'May', 'Jun', 'Jul'
                                      ];
                                      if (value.toInt() < months.length) {
                                        return Text(
                                            months[value.toInt()],
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color:
                                                    AppTheme.textHint));
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: false)),
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                // Revenue line
                                LineChartBarData(
                                  spots: const [
                                    FlSpot(0, 45000),
                                    FlSpot(1, 52000),
                                    FlSpot(2, 48000),
                                    FlSpot(3, 61000),
                                    FlSpot(4, 55000),
                                    FlSpot(5, 67000),
                                    FlSpot(6, 74000),
                                  ],
                                  isCurved: true,
                                  color: AppTheme.danger,
                                  barWidth: 2.5,
                                  dotData:
                                      const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppTheme.danger
                                        .withOpacity(0.08),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Payment Breakdown
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment Breakdown',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary)),
                        const SizedBox(height: 24),
                        _BreakdownItem(
                          label: 'Completed',
                          count: completedCount,
                          amount: 'Rs. ${_formatAmount(totalRevenue)}',
                          color: AppTheme.success,
                        ),
                        const SizedBox(height: 16),
                        _BreakdownItem(
                          label: 'Pending',
                          count: pendingCount,
                          amount: 'Rs. 0',
                          color: AppTheme.warning,
                        ),
                        const SizedBox(height: 16),
                        _BreakdownItem(
                          label: 'Failed',
                          count: failedCount,
                          amount: 'Rs. ${_formatAmount(totalRefunds)}',
                          color: AppTheme.danger,
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppTheme.border),
                        const SizedBox(height: 16),
                        _BreakdownItem(
                          label: 'Commission Earned',
                          count: completedCount,
                          amount: 'Rs. ${_formatAmount(totalCommission)}',
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Payments Table
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Recent Transactions',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary)),
                  ),
                  const Divider(height: 1, color: AppTheme.border),

                  // Table Header
                  const Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text('CUSTOMER',
                            style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textHint,
                                letterSpacing: 0.5))),
                        Expanded(flex: 2, child: Text('WORKER',
                            style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textHint,
                                letterSpacing: 0.5))),
                        Expanded(flex: 2, child: Text('SERVICE',
                            style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textHint,
                                letterSpacing: 0.5))),
                        Expanded(flex: 1, child: Text('AMOUNT',
                            style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textHint,
                                letterSpacing: 0.5))),
                        Expanded(flex: 1, child: Text('COMMISSION',
                            style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textHint,
                                letterSpacing: 0.5))),
                        Expanded(flex: 1, child: Text('STATUS',
                            style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textHint,
                                letterSpacing: 0.5))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.border),

                  // Table Rows
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (docs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                          child: Text('No transactions found')),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data()
                            as Map<String, dynamic>;
                        final status =
                            data['status']?.toString() ?? 'pending';

                        Color statusColor;
                        Color statusBg;

                        switch (status) {
                          case 'completed':
                            statusColor = AppTheme.success;
                            statusBg = const Color(0xFFECFDF5);
                            break;
                          case 'failed':
                            statusColor = AppTheme.danger;
                            statusBg = const Color(0xFFFEF2F2);
                            break;
                          default:
                            statusColor = AppTheme.warning;
                            statusBg = const Color(0xFFFFFBEB);
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    color: AppTheme.border)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  data['customerName'] ?? 'N/A',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  data['workerName'] ?? 'N/A',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    data['service'] ?? 'N/A',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.primary),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Rs. ${data['amount'] ?? 0}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Rs. ${data['commission'] ?? 0}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status[0].toUpperCase() +
                                        status.substring(1),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: statusColor,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},');
    }
    return amount.toStringAsFixed(0);
  }
}

class _RevenueCard extends StatelessWidget {
  final String label;
  final String value;
  final String change;
  final bool changePositive;

  const _RevenueCard({
    required this.label,
    required this.value,
    required this.change,
    required this.changePositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                changePositive
                    ? Icons.trending_up
                    : Icons.trending_down,
                size: 14,
                color: changePositive
                    ? AppTheme.success
                    : AppTheme.danger,
              ),
              const SizedBox(width: 4),
              Text(change,
                  style: TextStyle(
                      fontSize: 11,
                      color: changePositive
                          ? AppTheme.success
                          : AppTheme.danger)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakdownItem extends StatelessWidget {
  final String label;
  final int count;
  final String amount;
  final Color color;

  const _BreakdownItem({
    required this.label,
    required this.count,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(amount,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            Text('$count transactions',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textHint)),
          ],
        ),
      ],
    );
  }
}