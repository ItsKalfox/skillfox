import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../services/user_service.dart';

class WorkerPersonalInfoScreen extends StatefulWidget {
  const WorkerPersonalInfoScreen({super.key});

  @override
  State<WorkerPersonalInfoScreen> createState() =>
      _WorkerPersonalInfoScreenState();
}

class _WorkerPersonalInfoScreenState extends State<WorkerPersonalInfoScreen> {
  final UserService _userService = UserService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _aboutController = TextEditingController();
  final _certificationController = TextEditingController();
  final _experienceController = TextEditingController();

  File? _certificatePdfFile;
  File? _certificateImageFile;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAvailable = true;

  final List<Map<String, TextEditingController>> _services = [
    {'service': TextEditingController(), 'price': TextEditingController()},
  ];

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
    _aboutController.text = (user?['about'] ?? '').toString();
    _certificationController.text = (user?['certification'] ?? '').toString();
    _experienceController.text = (user?['experience'] ?? '').toString();
    _isAvailable = user?['isAvailable'] ?? true;

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickCertificatePdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _certificatePdfFile = File(result.files.single.path!);
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF selected: ${result.files.single.name}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick PDF: $e')));
    }
  }

  Future<void> _pickCertificateImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _certificateImageFile = File(pickedFile.path);
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image selected successfully')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
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
    final about = _aboutController.text.trim();
    final certification = _certificationController.text.trim();
    final experience = _experienceController.text.trim();

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

    final services = _services.map((item) {
      return {
        'service': item['service']!.text.trim(),
        'price': item['price']!.text.trim(),
      };
    }).toList();

    setState(() {
      _isSaving = true;
    });

    try {
      await _userService.updateWorkerInfo(
        // ← was updatePersonalInfo
        name: name,
        phone: phone,
        about: about,
        certification: certification,
        experience: experience,
        isAvailable: _isAvailable,
        services: services,
      );

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
    _aboutController.dispose();
    _certificationController.dispose();
    _experienceController.dispose();

    for (final item in _services) {
      item['service']?.dispose();
      item['price']?.dispose();
    }

    super.dispose();
  }

  Widget _buildUploadBox({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD9DFEA)),
          color: const Color(0xFFF9FAFC),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4B7DF3)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
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
            const SizedBox(height: 12),

            _FieldCard(
              label: 'About',
              child: TextField(
                controller: _aboutController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Write about yourself, your skills, background...',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            _FieldCard(
              label: 'Certification',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _certificationController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Write your certificates here',
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildUploadBox(
                    icon: Icons.picture_as_pdf,
                    title: 'Upload PDF proof',
                    subtitle: _certificatePdfFile == null
                        ? 'Add certificate PDF file'
                        : 'PDF selected',
                    onTap: _pickCertificatePdf,
                  ),

                  if (_certificatePdfFile != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Selected PDF: ${_certificatePdfFile!.path.split('/').last}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  _buildUploadBox(
                    icon: Icons.image,
                    title: 'Upload photo proof',
                    subtitle: _certificateImageFile == null
                        ? 'Add certificate image/photo'
                        : 'Image selected',
                    onTap: _pickCertificateImage,
                  ),

                  if (_certificateImageFile != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _certificateImageFile!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            _FieldCard(
              label: 'Experience',
              child: TextField(
                controller: _experienceController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Example: 8+ years experience in plumbing',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            _FieldCard(
              label: 'Services & Pricing',
              child: Column(
                children: [
                  ...List.generate(_services.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _services[index]['service'],
                              decoration: const InputDecoration(
                                hintText: 'Service name',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Color(0xFFF7F8FC),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _services[index]['price'],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Base price',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Color(0xFFF7F8FC),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _removeServiceField(index),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addServiceField,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Service'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            _FieldCard(
              label: 'Availability',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isAvailable ? 'Available' : 'Not Available',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Switch(
                    value: _isAvailable,
                    onChanged: (value) {
                      setState(() {
                        _isAvailable = value;
                      });
                    },
                  ),
                ],
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
      width: double.infinity,
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
