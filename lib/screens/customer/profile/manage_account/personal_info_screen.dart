import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/user_service.dart';

class CustomerPersonalInfoScreen extends StatefulWidget {
  const CustomerPersonalInfoScreen({super.key});

  @override
  State<CustomerPersonalInfoScreen> createState() =>
      _CustomerPersonalInfoScreenState();
}

class _CustomerPersonalInfoScreenState
    extends State<CustomerPersonalInfoScreen> {
  final UserService _userService = UserService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _userService.getCurrentUserData();

    if (!mounted) return;

    _nameController.text = (user?['name'] ?? '').toString();
    _phoneController.text = (user?['phone'] ?? '').toString();
    _emailController.text = (user?['email'] ?? '').toString();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number cannot be empty')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _userService.updatePersonalInfo(name: name, phone: phone);

      if (!mounted) return;

      await context.read<AuthProvider>().refreshUserData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Personal info updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update info: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Personal Info'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F8FC),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 42,
              backgroundColor: Color(0xFFE6EAF7),
              child: Icon(Icons.person, size: 42, color: Color(0xFF5B6475)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile photo update can be added next'),
                  ),
                );
              },
              child: const Text('Change profile photo'),
            ),
            const SizedBox(height: 12),
            _FieldCard(
              label: 'Full Name',
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Enter your full name',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _FieldCard(
              label: 'Phone Number',
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Enter your phone number',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _FieldCard(
              label: 'Email Address',
              child: TextField(
                controller: _emailController,
                readOnly: true,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Enter your email address',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B7DF3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _isSaving ? 'Saving...' : 'Save Changes',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String label;
  final Widget child;

  const _FieldCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF666666),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
