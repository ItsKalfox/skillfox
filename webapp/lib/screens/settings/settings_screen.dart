import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTab = 'Notifications';

  // Notification toggles
  bool _newPayment = true;
  bool _workerApplication = true;
  bool _disputeAlert = true;
  bool _refundRequest = false;
  bool _criticalAlerts = true;
  bool _systemUpdates = false;

  final List<String> _tabs = [
    'Notifications',
    'Security',
    'General',
    'Email Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Text('Settings',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        const Text('Manage your application settings and preferences',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        const SizedBox(height: 24),

        // Content
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Tab Menu
            Container(
              width: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: _tabs.map((tab) => _TabItem(
                  label: tab,
                  icon: _getTabIcon(tab),
                  isSelected: _selectedTab == tab,
                  onTap: () => setState(() => _selectedTab = tab),
                )).toList(),
              ),
            ),
            const SizedBox(width: 24),

            // Right Content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: _buildTabContent(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getTabIcon(String tab) {
    switch (tab) {
      case 'Notifications': return Icons.notifications_outlined;
      case 'Security': return Icons.security_outlined;
      case 'General': return Icons.settings_outlined;
      case 'Email Settings': return Icons.email_outlined;
      default: return Icons.settings_outlined;
    }
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 'Notifications': return _buildNotifications();
      case 'Security': return _buildSecurity();
      case 'General': return _buildGeneral();
      case 'Email Settings': return _buildEmailSettings();
      default: return _buildNotifications();
    }
  }

  Widget _buildNotifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Notification Preferences',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 24),

        const Text('Email Notifications',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 16),

        _ToggleItem(
          title: 'New Payment Received',
          subtitle: 'Get notified when a new payment is processed',
          value: _newPayment,
          onChanged: (v) => setState(() => _newPayment = v),
        ),
        const Divider(color: AppTheme.border),
        _ToggleItem(
          title: 'Worker Application',
          subtitle: 'Get notified about new worker applications',
          value: _workerApplication,
          onChanged: (v) => setState(() => _workerApplication = v),
        ),
        const Divider(color: AppTheme.border),
        _ToggleItem(
          title: 'Dispute Alert',
          subtitle: 'Get notified when a new dispute is filed',
          value: _disputeAlert,
          onChanged: (v) => setState(() => _disputeAlert = v),
        ),
        const Divider(color: AppTheme.border),
        _ToggleItem(
          title: 'Refund Request',
          subtitle: 'Get notified about refund requests',
          value: _refundRequest,
          onChanged: (v) => setState(() => _refundRequest = v),
        ),
        const SizedBox(height: 24),

        const Text('Push Notifications',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 16),

        _ToggleItem(
          title: 'Critical Alerts',
          subtitle: 'Receive push notifications for critical issues',
          value: _criticalAlerts,
          onChanged: (v) => setState(() => _criticalAlerts = v),
        ),
        const Divider(color: AppTheme.border),
        _ToggleItem(
          title: 'System Updates',
          subtitle: 'Get notified about system updates',
          value: _systemUpdates,
          onChanged: (v) => setState(() => _systemUpdates = v),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: 160,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification settings saved!'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save Changes'),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Security Settings',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 24),

        // Change Password Section
        const Text('Change Password',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 16),

        _InputField(label: 'Current Password', hint: '••••••••', obscure: true),
        const SizedBox(height: 16),
        _InputField(label: 'New Password', hint: '••••••••', obscure: true),
        const SizedBox(height: 16),
        _InputField(label: 'Confirm New Password', hint: '••••••••', obscure: true),
        const SizedBox(height: 24),

        SizedBox(
          width: 180,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password updated successfully!'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Update Password'),
          ),
        ),
        const SizedBox(height: 32),
        const Divider(color: AppTheme.border),
        const SizedBox(height: 24),

        // Sign Out Section
        const Text('Session',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 16),

        SizedBox(
          width: 160,
          child: OutlinedButton.icon(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.danger,
              side: const BorderSide(color: AppTheme.danger),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneral() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('General Settings',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 24),

        _InputField(label: 'Platform Name', hint: 'HomeServices'),
        const SizedBox(height: 16),
        _InputField(label: 'Support Email', hint: 'support@skillfox.com'),
        const SizedBox(height: 16),
        _InputField(label: 'Contact Number', hint: '+94 77 123 4567'),
        const SizedBox(height: 16),
        _InputField(label: 'Platform URL', hint: 'https://skillfox.com'),
        const SizedBox(height: 24),

        SizedBox(
          width: 160,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('General settings saved!'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save Changes'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Email Settings',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 24),

        _InputField(label: 'SMTP Host', hint: 'smtp.gmail.com'),
        const SizedBox(height: 16),
        _InputField(label: 'SMTP Port', hint: '587'),
        const SizedBox(height: 16),
        _InputField(label: 'Email Username', hint: 'admin@skillfox.com'),
        const SizedBox(height: 16),
        _InputField(label: 'Email Password', hint: '••••••••', obscure: true),
        const SizedBox(height: 16),
        _InputField(label: 'From Name', hint: 'SkillFox Admin'),
        const SizedBox(height: 24),

        SizedBox(
          width: 160,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email settings saved!'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save Changes'),
          ),
        ),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: isSelected ? Colors.white : AppTheme.textSecondary),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleItem({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final bool obscure;

  const _InputField({
    required this.label,
    required this.hint,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textHint),
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}