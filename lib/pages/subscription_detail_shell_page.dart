import 'package:flutter/material.dart';

import 'invoice_page.dart';
import 'manage_subscription_page.dart';
import 'session_tracking_page.dart';
import 'sessions_list_page.dart';
import 'subscription_confirmation_page.dart';
import 'work_progress_page.dart';

class SubscriptionDetailShellPage extends StatefulWidget {
  const SubscriptionDetailShellPage({
    required this.subscriptionId,
    this.initialIndex = 0,
    super.key,
  });

  final String subscriptionId;
  final int initialIndex;

  @override
  State<SubscriptionDetailShellPage> createState() =>
      _SubscriptionDetailShellPageState();
}

class _SubscriptionDetailShellPageState extends State<SubscriptionDetailShellPage> {
  late int _index;
  String? _selectedSessionId;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      SubscriptionConfirmationPage(subscriptionId: widget.subscriptionId),
      SessionsListPage(
        subscriptionId: widget.subscriptionId,
        onTrackSession: (sessionId) {
          setState(() {
            _selectedSessionId = sessionId;
            _index = 2;
          });
        },
      ),
      SessionTrackingPage(
        subscriptionId: widget.subscriptionId,
        initialSessionId: _selectedSessionId,
      ),
      WorkProgressPage(subscriptionId: widget.subscriptionId),
      ManageSubscriptionPage(subscriptionId: widget.subscriptionId),
      InvoicePage(subscriptionId: widget.subscriptionId),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Workspace')),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            label: 'Confirm',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Sessions',
          ),
          NavigationDestination(
            icon: Icon(Icons.track_changes),
            label: 'Track',
          ),
          NavigationDestination(
            icon: Icon(Icons.timeline),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Manage',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'Invoices',
          ),
        ],
      ),
    );
  }
}
