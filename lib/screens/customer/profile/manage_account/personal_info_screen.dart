import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart' as app_auth;
import '../../../../services/user_service.dart';
import '../../../../widgets/gradient_button.dart';
import 'package:image_cropper/image_cropper.dart';

class CustomerPersonalInfoScreen extends StatefulWidget {
  const CustomerPersonalInfoScreen({super.key});

  @override
  State<CustomerPersonalInfoScreen> createState() =>
      _CustomerPersonalInfoScreenState();
}

class _CustomerPersonalInfoScreenState extends State<CustomerPersonalInfoScreen>
    with TickerProviderStateMixin {
  final UserService _userService = UserService();
  final ImagePicker _imagePicker = ImagePicker();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  String _profilePhotoUrl = '';
  File? _selectedImageFile;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _userService.getCurrentUserData();
      if (!mounted) return;
      _nameController.text = (user?['name'] ?? '').toString();
      _phoneController.text = (user?['phone'] ?? '').toString();
      _emailController.text = (user?['email'] ?? '').toString();
      _profilePhotoUrl =
          (user?['profilePhotoUrl'] ?? user?['profileImageUrl'] ?? '')
              .toString();
      setState(() => _isLoading = false);
      _fadeController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _fadeController.forward();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load personal info: $e')),
      );
    }
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (pickedFile == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        compressQuality: 85,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Photo',
            toolbarColor: const Color(0xFF4B7DF3),
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Photo',
            aspectRatioLockEnabled: true,
          ),
        ],
      );
      if (croppedFile == null) return;
      setState(() => _selectedImageFile = File(croppedFile.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Future<String?> _uploadProfilePhotoIfNeeded() async {
    if (_selectedImageFile == null) return _profilePhotoUrl;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;
    try {
      setState(() => _isUploadingPhoto = true);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${currentUser.uid}.jpg');
      await storageRef.putFile(_selectedImageFile!);
      final downloadUrl = await storageRef.getDownloadURL();
      await _userService.updateProfilePhoto(downloadUrl);
      return downloadUrl;
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload profile photo: $e')),
      );
      return null;
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _showErrorSnack('Name cannot be empty');
      return;
    }
    if (phone.isEmpty) {
      _showErrorSnack('Phone number cannot be empty');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uploadedPhotoUrl = await _uploadProfilePhotoIfNeeded();
      await _userService.updatePersonalInfo(name: name, phone: phone);
      if (!mounted) return;
      await context.read<app_auth.AuthProvider>().refreshUserData();
      setState(() {
        if (uploadedPhotoUrl != null) _profilePhotoUrl = uploadedPhotoUrl;
      });
      _showSuccessSnack('Profile updated successfully');
    } catch (e) {
      if (!mounted) return;
      _showErrorSnack('Failed to update info: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
            Text(message),
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

  ImageProvider? _buildProfileImage() {
    if (_selectedImageFile != null) return FileImage(_selectedImageFile!);
    if (_profilePhotoUrl.isNotEmpty) return NetworkImage(_profilePhotoUrl);
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F6FB),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4B7DF3)),
        ),
      );
    }

    final profileImage = _buildProfileImage();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 220,
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
                background: _HeaderBanner(
                  profileImage: profileImage,
                  isUploadingPhoto: _isUploadingPhoto,
                  onPickPhoto: _isUploadingPhoto ? null : _pickProfilePhoto,
                  name: _nameController.text,
                ),
              ),
            ),

            // ── Form ────────────────────────────────────────────
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
                        'ACCOUNT DETAILS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9AA3B4),
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),

                    // Name field
                    _ProField(
                      label: 'Full Name',
                      icon: Icons.person_outline_rounded,
                      controller: _nameController,
                      focusNode: _nameFocus,
                      nextFocus: _phoneFocus,
                      hintText: 'Your full name',
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 12),

                    // Phone field
                    _ProField(
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      controller: _phoneController,
                      focusNode: _phoneFocus,
                      hintText: 'Your phone number',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),

                    // Email field (read-only)
                    _ProField(
                      label: 'Email Address',
                      icon: Icons.mail_outline_rounded,
                      controller: _emailController,
                      hintText: 'Your email address',
                      keyboardType: TextInputType.emailAddress,
                      readOnly: true,
                      trailingWidget: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4B7DF3),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    GradientButton(
                      text: 'Save Changes',
                      onPressed: _save,
                      isLoading: _isSaving || _isUploadingPhoto,
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
//  Header Banner
// ═══════════════════════════════════════════════
class _HeaderBanner extends StatelessWidget {
  final ImageProvider? profileImage;
  final bool isUploadingPhoto;
  final VoidCallback? onPickPhoto;
  final String name;

  const _HeaderBanner({
    required this.profileImage,
    required this.isUploadingPhoto,
    required this.onPickPhoto,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5AA4F6), Color(0xFF3A6BE8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const SizedBox(height: 8),
            // Avatar
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.35),
                      width: 3,
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.white.withOpacity(0.22),
                  backgroundImage: profileImage,
                  child: profileImage == null
                      ? const Icon(
                          Icons.person_rounded,
                          size: 44,
                          color: Colors.white,
                        )
                      : null,
                ),
                // Camera button
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: onPickPhoto,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: isUploadingPhoto
                          ? const Padding(
                              padding: EdgeInsets.all(7),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF4B7DF3),
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: Color(0xFF4B7DF3),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Personal Info',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Manage your profile details',
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Professional Field
// ═══════════════════════════════════════════════
class _ProField extends StatefulWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final String hintText;
  final TextInputType keyboardType;
  final bool readOnly;
  final Widget? trailingWidget;

  const _ProField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.hintText,
    required this.keyboardType,
    this.focusNode,
    this.nextFocus,
    this.readOnly = false,
    this.trailingWidget,
  });

  @override
  State<_ProField> createState() => _ProFieldState();
}

class _ProFieldState extends State<_ProField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _focused = widget.focusNode?.hasFocus ?? false);
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
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
        color: widget.readOnly ? const Color(0xFFF9FAFB) : Colors.white,
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
                if (widget.trailingWidget != null) ...[
                  const Spacer(),
                  widget.trailingWidget!,
                ],
              ],
            ),
            TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              readOnly: widget.readOnly,
              keyboardType: widget.keyboardType,
              textInputAction: widget.nextFocus != null
                  ? TextInputAction.next
                  : TextInputAction.done,
              onSubmitted: (_) {
                if (widget.nextFocus != null) {
                  FocusScope.of(context).requestFocus(widget.nextFocus);
                }
              },
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: widget.readOnly
                    ? const Color(0xFF9AA3B4)
                    : const Color(0xFF1A1F2E),
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
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
          ],
        ),
      ),
    );
  }
}
