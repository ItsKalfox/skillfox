import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../services/dashboard_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String formatNumber(dynamic value) {
    final number = (value is int) ? value : int.tryParse(value.toString()) ?? 0;
    if (number >= 1000) {
      return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    }
    return number.toString();
  }

  String _formatRevenue(dynamic value) {
  final amount = (value is double) ? value : (value as num).toDouble();
  if (amount >= 1000) {
    return amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
  return amount.toStringAsFixed(0);
}

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: DashboardService.getDashboardStats(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            const Text("Welcome back! Here's what's happening today.",
                style: TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary)),
            const SizedBox(height: 24),

            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Revenue',
                          value: 'Rs. ${_formatRevenue(data['totalRevenue'] ?? 0)}',  
                          change: '↑ 12.5%',
                          changePositive: true,
                          icon: Icons.attach_money,
                          iconBg: const Color(0xFFEFF6FF),
                          iconColor: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Pending Requests',
                          value: '${data['pendingPayments'] ?? 0}',
                          change: '↑ 8.2%',
                          changePositive: true,
                          icon: Icons.pending_actions_outlined,
                          iconBg: const Color(0xFFECFDF5),
                          iconColor: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Active Users',
                          value: '${data['activeUsers'] ?? 0}',
                          change: '↑ 3.1%',
                          changePositive: true,
                          icon: Icons.people_outline,
                          iconBg: const Color(0xFFFFFBEB),
                          iconColor: const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Active Disputes',
                          value: '${data['activeDisputes'] ?? 0}',
                          change: '↓ 2.4%',
                          changePositive: false,
                          icon: Icons.error_outline,
                          iconBg: const Color(0xFFFEF2F2),
                          iconColor: AppTheme.danger,
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Revenue Analytics',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary)),
                                SizedBox(height: 4),
                                Text('Monthly revenue overview',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary)),
                              ],
                            ),
                            Text('View Details',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: AppTheme.border,
                                  strokeWidth: 1,
                                  dashArray: [4, 4],
                                ),
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 50,
                                    getTitlesWidget: (value, meta) => Text(
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
                                        'Jan', 'Feb', 'Mar', 'Apr',
                                        'May', 'Jun', 'Jul'
                                      ];
                                      if (value.toInt() < months.length) {
                                        return Text(months[value.toInt()],
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textHint));
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                rightTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
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
                                  color: AppTheme.primary,
                                  barWidth: 2.5,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter:
                                        (spot, percent, barData, index) =>
                                            FlDotCirclePainter(
                                      radius: 4,
                                      color: AppTheme.primary,
                                      strokeWidth: 2,
                                      strokeColor: Colors.white,
                                    ),
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color:
                                        AppTheme.primary.withOpacity(0.05),
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
                        const Text('Request Status',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary)),
                        const SizedBox(height: 24),
                        _StatusItem(
                          label: 'Completed',
                          value: '${data['completedRequests'] ?? 0} requests',
                          subtitle: 'Successfully done',
                          color: AppTheme.success,
                        ),
                        const SizedBox(height: 20),
                        _StatusItem(
                          label: 'Pending',
                          value: '${data['pendingPayments'] ?? 0} requests',
                          subtitle: 'Waiting for action',
                          color: AppTheme.warning,
                        ),
                        const SizedBox(height: 20),
                        _StatusItem(
                          label: 'Cancelled',
                          value: '${data['cancelledRequests'] ?? 0} requests',
                          subtitle: 'Cancelled by user',
                          color: AppTheme.danger,
                        ),
                        const SizedBox(height: 20),
                        _StatusItem(
                          label: 'Total Workers',
                          value: '${data['totalWorkers'] ?? 0} workers',
                          subtitle: 'Registered on platform',
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool changePositive;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.change,
    required this.changePositive,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              Text(change,
                  style: TextStyle(
                      fontSize: 12,
                      color: changePositive
                          ? AppTheme.success
                          : AppTheme.danger,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _StatusItem({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textHint)),
          ],
        ),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ],
    );
  }
}