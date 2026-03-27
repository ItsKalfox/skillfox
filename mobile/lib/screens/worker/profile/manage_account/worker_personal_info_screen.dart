import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../../../services/user_service.dart';
import '../../../../widgets/gradient_button.dart';

class WorkerPersonalInfoScreen extends StatefulWidget {
  const WorkerPersonalInfoScreen({super.key});

  @override
  State<WorkerPersonalInfoScreen> createState() =>
      _WorkerPersonalInfoScreenState();
}

class _WorkerPersonalInfoScreenState extends State<WorkerPersonalInfoScreen>
    with TickerProviderStateMixin {
  final UserService _userService = UserService();
  final ImagePicker _imagePicker = ImagePicker();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _categoryController = TextEditingController();
  final _aboutController = TextEditingController();
  final _certificationController = TextEditingController();
  final _experienceController = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _aboutFocus = FocusNode();
  final _certFocus = FocusNode();
  final _expFocus = FocusNode();

  File? _certificatePdfFile;
  File? _certificateImageFile;
  File? _selectedProfileImageFile;
  String _profilePhotoUrl = '';
  File? _selectedCoverImageFile;
  String _coverPhotoUrl = '';

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  bool _isAvailable = true;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  final List<Map<String, TextEditingController>> _services = [
    {'service': TextEditingController(), 'price': TextEditingController()},
  ];

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
      _categoryController.text = (user?['category'] ?? '').toString();
      _aboutController.text = (user?['about'] ?? '').toString();
      _certificationController.text = (user?['certification'] ?? '').toString();
      _experienceController.text = (user?['experience'] ?? '').toString();
      _isAvailable = user?['isAvailable'] ?? true;
      _profilePhotoUrl =
          (user?['profilePhotoUrl'] ?? user?['profileImageUrl'] ?? '')
              .toString();
      _coverPhotoUrl = (user?['coverPhotoUrl'] ?? '').toString();

      final rawServices = user?['services'];
      if (rawServices is List && rawServices.isNotEmpty) {
        for (final s in _services) {
          s['service']?.dispose();
          s['price']?.dispose();
        }
        _services.clear();
        for (final item in rawServices) {
          _services.add({
            'service': TextEditingController(
              text: (item['service'] ?? '').toString(),
            ),
            'price': TextEditingController(
              text: (item['price'] ?? '').toString(),
            ),
          });
        }
      }

      setState(() => _isLoading = false);
      _fadeController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _fadeController.forward();
      _showErrorSnack('Failed to load info: $e');
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
      setState(() => _selectedProfileImageFile = File(croppedFile.path));
    } catch (e) {
      if (!mounted) return;
      _showErrorSnack('Failed to pick image: $e');
    }
  }

  Future<String?> _uploadProfilePhotoIfNeeded() async {
    if (_selectedProfileImageFile == null) return _profilePhotoUrl;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;
    try {
      setState(() => _isUploadingPhoto = true);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${currentUser.uid}.jpg');
      await storageRef.putFile(_selectedProfileImageFile!);
      final downloadUrl = await storageRef.getDownloadURL();
      await _userService.updateProfilePhoto(downloadUrl);
      return downloadUrl;
    } catch (e) {
      if (!mounted) return null;
      _showErrorSnack('Failed to upload photo: $e');
      return null;
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _pickCoverPhoto() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (pickedFile == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        compressQuality: 85,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Banner Photo',
            toolbarColor: const Color(0xFF4B7DF3),
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Banner Photo',
            aspectRatioLockEnabled: true,
          ),
        ],
      );
      if (croppedFile == null) return;
      setState(() => _selectedCoverImageFile = File(croppedFile.path));
    } catch (e) {
      if (!mounted) return;
      _showErrorSnack('Failed to pick cover image: $e');
    }
  }

  Future<String?> _uploadCoverPhotoIfNeeded() async {
    if (_selectedCoverImageFile == null) return _coverPhotoUrl;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;
    try {
      setState(() => _isUploadingPhoto = true);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('cover_photos')
          .child('${currentUser.uid}.jpg');
      await storageRef.putFile(_selectedCoverImageFile!);
      final downloadUrl = await storageRef.getDownloadURL();
      await _userService.updateCoverPhoto(downloadUrl);
      return downloadUrl;
    } catch (e) {
      if (!mounted) return null;
      _showErrorSnack('Failed to upload banner: $e');
      return null;
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _pickCertificatePdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() => _certificatePdfFile = File(result.files.single.path!));
        _showSuccessSnack('PDF selected: ${result.files.single.name}');
      }
    } catch (e) {
      _showErrorSnack('Failed to pick PDF: $e');
    }
  }

  Future<void> _pickCertificateImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() => _certificateImageFile = File(pickedFile.path));
        _showSuccessSnack('Certificate image selected');
      }
    } catch (e) {
      _showErrorSnack('Failed to pick image: $e');
    }
  }

  void _addServiceField() {
    setState(() {
      _services.add({
        'service': TextEditingController(),
        'price': TextEditingController(),
      });
    });
  }

  void _removeServiceField(int index) {
    if (_services.length == 1) return;
    setState(() {
      _services[index]['service']?.dispose();
      _services[index]['price']?.dispose();
      _services.removeAt(index);
    });
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

    final services = _services.map((item) {
      return {
        'service': item['service']!.text.trim(),
        'price': item['price']!.text.trim(),
      };
    }).toList();

    setState(() => _isSaving = true);

    try {
      final uploadedPhotoUrl = await _uploadProfilePhotoIfNeeded();
      final uploadedCoverUrl = await _uploadCoverPhotoIfNeeded();

      await _userService.updateWorkerInfo(
        name: name,
        phone: phone,
        about: _aboutController.text.trim(),
        certification: _certificationController.text.trim(),
        experience: _experienceController.text.trim(),
        isAvailable: _isAvailable,
        services: services,
      );

      if (!mounted) return;

      setState(() {
        if (uploadedPhotoUrl != null) _profilePhotoUrl = uploadedPhotoUrl;
        if (uploadedCoverUrl != null) _coverPhotoUrl = uploadedCoverUrl;
      });

      _showSuccessSnack('Profile updated successfully');
    } catch (e) {
      if (!mounted) return;
      _showErrorSnack('Failed to update: $e');
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
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  bool get _isSubscriptionCategory {
    final category = _categoryController.text.trim().toLowerCase();
    return category == 'teacher' || category == 'caregiver';
  }

  ImageProvider? _buildProfileImage() {
    if (_selectedProfileImageFile != null) {
      return FileImage(_selectedProfileImageFile!);
    }
    if (_profilePhotoUrl.isNotEmpty) return NetworkImage(_profilePhotoUrl);
    return null;
  }

  ImageProvider? _buildCoverImage() {
    if (_selectedCoverImageFile != null) {
      return FileImage(_selectedCoverImageFile!);
    }
    if (_coverPhotoUrl.isNotEmpty) return NetworkImage(_coverPhotoUrl);
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _categoryController.dispose();
    _aboutController.dispose();
    _certificationController.dispose();
    _experienceController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _aboutFocus.dispose();
    _certFocus.dispose();
    _expFocus.dispose();
    _fadeController.dispose();
    for (final item in _services) {
      item['service']?.dispose();
      item['price']?.dispose();
    }
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
                  coverImage: _buildCoverImage(),
                  isUploadingPhoto: _isUploadingPhoto,
                  onPickPhoto: _isUploadingPhoto ? null : _pickProfilePhoto,
                  onPickCover: _isUploadingPhoto ? null : _pickCoverPhoto,
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
                    // ── Basic Info ──
                    const _SectionLabel(text: 'BASIC INFO'),
                    const SizedBox(height: 14),

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

                    _ProField(
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      controller: _phoneController,
                      focusNode: _phoneFocus,
                      hintText: 'Your phone number',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),

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
                    const SizedBox(height: 12),

                    _ProField(
                      label: 'Category',
                      icon: Icons.work_outline_rounded,
                      controller: _categoryController,
                      hintText: 'Your service category',
                      keyboardType: TextInputType.text,
                      readOnly: true,
                      trailingWidget: const Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Professional Info ──
                    const _SectionLabel(text: 'PROFESSIONAL INFO'),
                    const SizedBox(height: 14),

                    _ProField(
                      label: 'About',
                      icon: Icons.info_outline_rounded,
                      controller: _aboutController,
                      focusNode: _aboutFocus,
                      nextFocus: _expFocus,
                      hintText: 'Write about yourself, your skills...',
                      keyboardType: TextInputType.multiline,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),

                    _ProField(
                      label: 'Experience',
                      icon: Icons.history_rounded,
                      controller: _experienceController,
                      focusNode: _expFocus,
                      hintText: 'e.g. 8+ years in plumbing',
                      keyboardType: TextInputType.text,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),

                    _CertificationCard(
                      controller: _certificationController,
                      focusNode: _certFocus,
                      certificatePdfFile: _certificatePdfFile,
                      certificateImageFile: _certificateImageFile,
                      onPickPdf: _pickCertificatePdf,
                      onPickImage: _pickCertificateImage,
                    ),

                    const SizedBox(height: 28),

                    // ── Services & Pricing ──
                    _SectionLabel(
                      text: _isSubscriptionCategory
                          ? 'CLASSES / CARE PACKAGES'
                          : 'SERVICES & PRICING',
                    ),
                    const SizedBox(height: 14),

                    if (_isSubscriptionCategory)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text(
                          'Add what you teach or offer so customers can subscribe weekly or monthly.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            height: 1.4,
                          ),
                        ),
                      ),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE2E6F0),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ...List.generate(_services.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: _services[index]['service'],
                                      decoration: InputDecoration(
                                        hintText: _isSubscriptionCategory
                                            ? 'Class or package name'
                                            : 'Service name',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFFCBD0DC),
                                          fontSize: 13,
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF4F6FB),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: _services[index]['price'],
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: _isSubscriptionCategory
                                            ? 'Weekly / monthly fee'
                                            : 'Price',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFFCBD0DC),
                                          fontSize: 13,
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF4F6FB),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    onPressed: () => _removeServiceField(index),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Color(0xFFE53935),
                                      size: 20,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: _addServiceField,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add,
                                    color: Color(0xFF4B7DF3),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isSubscriptionCategory
                                        ? 'Add Class / Package'
                                        : 'Add Service',
                                    style: const TextStyle(
                                      color: Color(0xFF4B7DF3),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Availability ──
                    const _SectionLabel(text: 'AVAILABILITY'),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE2E6F0),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _isAvailable
                                  ? const Color(0xFFEAFBF0)
                                  : const Color(0xFFF4F6FB),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isAvailable
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.cancel_outlined,
                              color: _isAvailable
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFF9AA3B4),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Available for jobs',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1F2E),
                                  ),
                                ),
                                Text(
                                  _isAvailable
                                      ? 'Customers can find and book you'
                                      : 'You are hidden from search results',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF9AA3B4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isAvailable,
                            onChanged: (value) =>
                                setState(() => _isAvailable = value),
                            activeColor: const Color(0xFF4B7DF3),
                          ),
                        ],
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
  final ImageProvider? coverImage;
  final bool isUploadingPhoto;
  final VoidCallback? onPickPhoto;
  final VoidCallback? onPickCover;

  const _HeaderBanner({
    required this.profileImage,
    required this.coverImage,
    required this.isUploadingPhoto,
    required this.onPickPhoto,
    required this.onPickCover,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: coverImage == null ? const Color(0xFF5AA4F6) : null,
        gradient: coverImage == null
            ? const LinearGradient(
                colors: [Color(0xFF5AA4F6), Color(0xFF3A6BE8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        image: coverImage != null
            ? DecorationImage(
                image: coverImage!,
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.35),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      child: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(height: 8),
                  Stack(
                    alignment: Alignment.center,
                    children: [
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
                    'Manage your worker profile',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top > 0
                ? MediaQuery.of(context).padding.top + 8
                : 32,
            right: 16,
            child: GestureDetector(
              onTap: onPickCover,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.camera_enhance_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Banner',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Certification Card
// ═══════════════════════════════════════════════
class _CertificationCard extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final File? certificatePdfFile;
  final File? certificateImageFile;
  final VoidCallback onPickPdf;
  final VoidCallback onPickImage;

  const _CertificationCard({
    required this.controller,
    required this.focusNode,
    required this.certificatePdfFile,
    required this.certificateImageFile,
    required this.onPickPdf,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E6F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_outlined, size: 15, color: Color(0xFF9AA3B4)),
              SizedBox(width: 6),
              Text(
                'Certification',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9AA3B4),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          TextField(
            controller: controller,
            focusNode: focusNode,
            maxLines: 3,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1F2E),
            ),
            decoration: const InputDecoration(
              hintText: 'Write your certificates here...',
              hintStyle: TextStyle(
                color: Color(0xFFCBD0DC),
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.only(top: 8, bottom: 10),
            ),
          ),
          const SizedBox(height: 8),
          _UploadTile(
            icon: Icons.picture_as_pdf_rounded,
            iconColor: const Color(0xFFE53935),
            iconBg: const Color(0xFFFFF0F0),
            title: certificatePdfFile == null
                ? 'Upload PDF proof'
                : certificatePdfFile!.path.split('/').last,
            subtitle: certificatePdfFile == null
                ? 'Tap to add certificate PDF'
                : 'PDF selected ✓',
            onTap: onPickPdf,
          ),
          const SizedBox(height: 8),
          _UploadTile(
            icon: Icons.image_outlined,
            iconColor: const Color(0xFF4B7DF3),
            iconBg: const Color(0xFFEEF2FF),
            title: certificateImageFile == null
                ? 'Upload photo proof'
                : 'Image selected ✓',
            subtitle: certificateImageFile == null
                ? 'Tap to add certificate image'
                : certificateImageFile!.path.split('/').last,
            onTap: onPickImage,
          ),
          if (certificateImageFile != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                certificateImageFile!,
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Upload Tile
// ═══════════════════════════════════════════════
class _UploadTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _UploadTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6FB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1F2E),
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9AA3B4),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: Color(0xFF9AA3B4),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Section Label
// ═══════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF9AA3B4),
          letterSpacing: 1.4,
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
  final int maxLines;

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
    this.maxLines = 1,
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
                Icon(widget.icon, size: 15, color: iconColor),
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
              maxLines: widget.maxLines,
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
