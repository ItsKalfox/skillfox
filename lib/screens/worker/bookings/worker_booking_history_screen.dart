import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkerBookingHistoryScreen extends StatefulWidget {
  const WorkerBookingHistoryScreen({super.key});

  @override
  State<WorkerBookingHistoryScreen> createState() =>
      _WorkerBookingHistoryScreenState();
}

class _WorkerBookingHistoryScreenState extends State<WorkerBookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final User? _user = FirebaseAuth.instance.currentUser;

  // ── Earnings History ──
  List<Map<String, dynamic>> _earnings = [];
  bool _earningsLoading = true;
  String _earningsError = '';

  // ── Completed Tasks ──
  List<Map<String, dynamic>> _tasks = [];
  bool _tasksLoading = true;
  String _tasksError = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchEarnings();
    _fetchCompletedTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Fetch Earnings ──
  Future<void> _fetchEarnings() async {
    setState(() {
      _earningsLoading = true;
      _earningsError = '';
    });
    try {
      final uid = _user?.uid;
      if (uid == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('earnings')
          .orderBy('createdAt', descending: true)
          .get();

      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'taskName': data['taskName'] ?? 'Task',
          'amount': (data['amount'] ?? 0).toDouble(),
          'date': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();

      setState(() {
        _earnings = list;
        _earningsLoading = false;
      });
    } catch (e) {
      setState(() {
        _earningsError = 'Failed to load earnings.';
        _earningsLoading = false;
      });
    }
  }

  // ── Fetch Completed Tasks ──
  Future<void> _fetchCompletedTasks() async {
    setState(() {
      _tasksLoading = true;
      _tasksError = '';
    });
    try {
      final uid = _user?.uid;
      if (uid == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .where('status', isEqualTo: 'completed')
          .orderBy('createdAt', descending: true)
          .get();

      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'taskName': data['taskName'] ?? data['title'] ?? 'Task',
          'status': data['status'] ?? 'completed',
          'amount': (data['amount'] ?? data['pay'] ?? 0).toDouble(),
          'location': data['location'] ?? data['address'] ?? '',
          'description': data['description'] ?? '',
          'date': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();

      setState(() {
        _tasks = list;
        _tasksLoading = false;
      });
    } catch (e) {
      setState(() {
        _tasksError = 'Failed to load tasks.';
        _tasksLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = [
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
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEDE5FF)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: Color(0xFF2D1B5E),
            ),
          ),
        ),
        title: const Text(
          'History',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF222222),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EAFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C4DCC).withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: const Color(0xFF2D1B5E),
                unselectedLabelColor: const Color(0xFF9080B8),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Earnings History'),
                  Tab(text: 'Completed Works'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Earnings History ──
          _earningsLoading
              ? const _LoadingView()
              : _earningsError.isNotEmpty
              ? _ErrorView(message: _earningsError, onRetry: _fetchEarnings)
              : _earnings.isEmpty
              ? const _EmptyView(
                  icon: '💰',
                  message: 'No earnings history yet',
                  sub: 'Your payment records will appear here',
                )
              : RefreshIndicator(
                  color: const Color(0xFF7C4DCC),
                  onRefresh: _fetchEarnings,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      // Summary banner
                      _EarningsSummaryBanner(earnings: _earnings),
                      const SizedBox(height: 16),
                      // List
                      ..._earnings.asMap().entries.map((entry) {
                        final i = entry.key;
                        final tx = entry.value;
                        // Date separator
                        final showSeparator =
                            i == 0 ||
                            !_isSameMonth(
                              (_earnings[i - 1]['date'] as DateTime),
                              tx['date'] as DateTime,
                            );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showSeparator)
                              _MonthSeparator(date: tx['date'] as DateTime),
                            _EarningsItem(tx: tx, formatDate: _formatDate),
                          ],
                        );
                      }),
                    ],
                  ),
                ),

          // ── Tab 2: Completed Works ──
          _tasksLoading
              ? const _LoadingView()
              : _tasksError.isNotEmpty
              ? _ErrorView(message: _tasksError, onRetry: _fetchCompletedTasks)
              : _tasks.isEmpty
              ? const _EmptyView(
                  icon: '✅',
                  message: 'No completed works yet',
                  sub: 'Your finished tasks will appear here',
                )
              : RefreshIndicator(
                  color: const Color(0xFF7C4DCC),
                  onRefresh: _fetchCompletedTasks,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      // Summary banner
                      _TasksSummaryBanner(tasks: _tasks),
                      const SizedBox(height: 16),
                      ..._tasks.asMap().entries.map((entry) {
                        final i = entry.key;
                        final task = entry.value;
                        final showSeparator =
                            i == 0 ||
                            !_isSameMonth(
                              (_tasks[i - 1]['date'] as DateTime),
                              task['date'] as DateTime,
                            );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showSeparator)
                              _MonthSeparator(date: task['date'] as DateTime),
                            _TaskItem(task: task, formatDate: _formatDate),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
}

// ─────────────────────────────────────────
// Earnings Summary Banner
// ─────────────────────────────────────────
class _EarningsSummaryBanner extends StatelessWidget {
  final List<Map<String, dynamic>> earnings;
  const _EarningsSummaryBanner({required this.earnings});

  @override
  Widget build(BuildContext context) {
    final total = earnings.fold<double>(
      0,
      (sum, e) => sum + (e['amount'] as double),
    );
    final now = DateTime.now();
    final thisMonth = earnings
        .where((e) {
          final d = e['date'] as DateTime;
          return d.year == now.year && d.month == now.month;
        })
        .fold<double>(0, (sum, e) => sum + (e['amount'] as double));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A2D8F), Color(0xFF7C4DCC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C4DCC).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Earned',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs ${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 44,
            color: Colors.white24,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This Month',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs ${thisMonth.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                const Text(
                  'Txns',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
                Text(
                  '${earnings.length}',
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
}

// ─────────────────────────────────────────
// Tasks Summary Banner
// ─────────────────────────────────────────
class _TasksSummaryBanner extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;
  const _TasksSummaryBanner({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final totalPay = tasks.fold<double>(
      0,
      (sum, t) => sum + (t['amount'] as double),
    );
    final now = DateTime.now();
    final thisMonth = tasks.where((t) {
      final d = t['date'] as DateTime;
      return d.year == now.year && d.month == now.month;
    }).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A7A4A), Color(0xFF3ECF6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3ECF6A).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Works',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tasks.length} Tasks',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 44,
            color: Colors.white24,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This Month',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$thisMonth Tasks',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                const Text(
                  'Earned',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
                Text(
                  totalPay >= 1000
                      ? 'Rs ${(totalPay / 1000).toStringAsFixed(1)}K'
                      : 'Rs ${totalPay.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
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
}

// ─────────────────────────────────────────
// Month Separator
// ─────────────────────────────────────────
class _MonthSeparator extends StatelessWidget {
  final DateTime date;
  const _MonthSeparator({required this.date});

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Text(
            '${_months[date.month - 1]} ${date.year}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9080B8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: const Color(0xFFEDE5FF))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Earnings Item
// ─────────────────────────────────────────
class _EarningsItem extends StatelessWidget {
  final Map<String, dynamic> tx;
  final String Function(DateTime) formatDate;

  const _EarningsItem({required this.tx, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final date = tx['date'] as DateTime;
    final amount = tx['amount'] as double;

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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFD4F7E1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('💰', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['taskName'] as String,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D1B5E),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 11,
                      color: Color(0xFF9080B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatDate(date),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF9080B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+Rs ${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3ECF6A),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4F7E1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Paid',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A8A44),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Task Item
// ─────────────────────────────────────────
class _TaskItem extends StatelessWidget {
  final Map<String, dynamic> task;
  final String Function(DateTime) formatDate;

  const _TaskItem({required this.task, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final date = task['date'] as DateTime;
    final amount = task['amount'] as double;
    final location = task['location'] as String;
    final description = task['description'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDE5FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE5FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('✅', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['taskName'] as String,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D1B5E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 11,
                          color: Color(0xFF9080B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatDate(date),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF9080B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (amount > 0)
                    Text(
                      'Rs ${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D1B5E),
                      ),
                    ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE5FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Completed',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7C4DCC),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Location row
          if (location.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: const Color(0xFFEDE5FF)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 13,
                  color: Color(0xFF9080B8),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9080B8),
                    ),
                  ),
                ),
              ],
            ),
          ],
          // Description row
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.notes_outlined,
                  size: 13,
                  color: Color(0xFF9080B8),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9080B8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Loading View
// ─────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF7C4DCC)),
    );
  }
}

// ─────────────────────────────────────────
// Error View
// ─────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: Color(0xFF9080B8)),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE5FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7C4DCC),
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
// Empty View
// ─────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  final String icon;
  final String message;
  final String sub;
  const _EmptyView({
    required this.icon,
    required this.message,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 14),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D1B5E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9080B8)),
          ),
        ],
      ),
    );
  }
}
