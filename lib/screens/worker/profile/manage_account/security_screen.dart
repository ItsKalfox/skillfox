import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';
import '../../../../widgets/gradient_button.dart';

class CustomerSecurityScreen extends StatefulWidget {
  const CustomerSecurityScreen({super.key});

  @override
  State<CustomerSecurityScreen> createState() => _CustomerSecurityScreenState();
}

class _CustomerSecurityScreenState extends State<CustomerSecurityScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _currentFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isSaving = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showErrorSnack('Please fill in all fields');
      return;
    }

    if (newPassword.length < 6) {
      _showErrorSnack('New password must be at least 6 characters');
      return;
    }

    if (newPassword != confirmPassword) {
      _showErrorSnack('New passwords do not match');
      return;
    }

    setState(() => _isSaving = true);

    final error = await _authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error == null) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _showSuccessSnack('Password updated successfully');
    } else {
      _showErrorSnack(error);
    }
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: const Color(0xFF4B7DF3),
              elevation: 0,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF5AA4F6), Color(0xFF3A6BE8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.35),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Security',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Update your account password',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Body ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section label
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 14),
                      child: Text(
                        'CHANGE PASSWORD',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9AA3B4),
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),

                    // Current Password
                    _PasswordField(
                      label: 'Current Password',
                      hint: 'Enter your current password',
                      icon: Icons.lock_outline_rounded,
                      controller: _currentPasswordController,
                      focusNode: _currentFocus,
                      nextFocus: _newFocus,
                      obscureText: !_showCurrent,
                      onToggleVisibility: () =>
                          setState(() => _showCurrent = !_showCurrent),
                      isVisible: _showCurrent,
                    ),
                    const SizedBox(height: 12),

                    // New Password
                    _PasswordField(
                      label: 'New Password',
                      hint: 'At least 6 characters',
                      icon: Icons.lock_reset_rounded,
                      controller: _newPasswordController,
                      focusNode: _newFocus,
                      nextFocus: _confirmFocus,
                      obscureText: !_showNew,
                      onToggleVisibility: () =>
                          setState(() => _showNew = !_showNew),
                      isVisible: _showNew,
                    ),
                    const SizedBox(height: 12),

                    // Confirm Password
                    _PasswordField(
                      label: 'Confirm New Password',
                      hint: 'Re-enter new password',
                      icon: Icons.check_circle_outline_rounded,
                      controller: _confirmPasswordController,
                      focusNode: _confirmFocus,
                      obscureText: !_showConfirm,
                      onToggleVisibility: () =>
                          setState(() => _showConfirm = !_showConfirm),
                      isVisible: _showConfirm,
                    ),

                    const SizedBox(height: 10),

                    // Password hint
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 13,
                            color: const Color(0xFF9AA3B4),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Minimum 6 characters required',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF9AA3B4),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    GradientButton(
                      text: 'Update Password',
                      onPressed: _updatePassword,
                      isLoading: _isSaving,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Password Field
// ═══════════════════════════════════════════════
class _PasswordField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final bool obscureText;
  final bool isVisible;
  final VoidCallback onToggleVisibility;

  const _PasswordField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.focusNode,
    required this.obscureText,
    required this.isVisible,
    required this.onToggleVisibility,
    this.nextFocus,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _focused
        ? const Color(0xFF4B7DF3)
        : const Color(0xFFE2E6F0);
    final iconColor = _focused
        ? const Color(0xFF4B7DF3)
        : const Color(0xFFADB5C7);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: const Color(0xFF4B7DF3).withOpacity(0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(widget.icon, size: 15, color: iconColor),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _focused
                        ? const Color(0xFF4B7DF3)
                        : const Color(0xFF9AA3B4),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    obscureText: widget.obscureText,
                    textInputAction: widget.nextFocus != null
                        ? TextInputAction.next
                        : TextInputAction.done,
                    onSubmitted: (_) {
                      if (widget.nextFocus != null) {
                        FocusScope.of(context).requestFocus(widget.nextFocus);
                      }
                    },
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1F2E),
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: const TextStyle(
                        color: Color(0xFFCBD0DC),
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.only(top: 6, bottom: 10),
                    ),
                  ),
                ),
                // Eye toggle
                GestureDetector(
                  onTap: widget.onToggleVisibility,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 4),
                    child: Icon(
                      widget.isVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 19,
                      color: const Color(0xFFADB5C7),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
