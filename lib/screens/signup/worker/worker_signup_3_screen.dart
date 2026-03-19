import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:skillfox/core/utils/screen_helpers.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import 'worker_signup_4_screen.dart';

class WorkerSignup3Screen extends StatefulWidget {
  final String name, phone, nationalId, jobType;
  const WorkerSignup3Screen({super.key, required this.name, required this.phone,
    required this.nationalId, required this.jobType});
  @override
  State<WorkerSignup3Screen> createState() => _WorkerSignup3ScreenState();
}

class _WorkerSignup3ScreenState extends State<WorkerSignup3Screen> {
  File? _nicFront, _nicBack, _profilePhoto;
  List<File> _certifications = [];
  bool _uploading = false;
  final _picker = ImagePicker();

  Future<void> _pick(String type) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() {
      if (type == 'front') _nicFront = File(picked.path);
      else if (type == 'back') _nicBack = File(picked.path);
      else if (type == 'profile') _profilePhoto = File(picked.path);
    });
  }

  Future<void> _pickCert() async {
    if (_certifications.length >= 5) return;
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() => _certifications.add(File(picked.path)));
  }

  Future<String?> _upload(File file, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (_) { return null; }
  }

  bool get _canProceed =>
      _nicFront != null && _nicBack != null &&
      _certifications.length >= 3 && _profilePhoto != null;

  Future<void> _proceed() async {
    if (!_canProceed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required documents (min 3 certifications)')),
      );
      return;
    }
    setState(() => _uploading = true);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final nicFrontUrl = await _upload(_nicFront!, 'workers/$ts/nic_front.jpg');
    final nicBackUrl = await _upload(_nicBack!, 'workers/$ts/nic_back.jpg');
    final profileUrl = await _upload(_profilePhoto!, 'workers/$ts/profile.jpg');
    final certUrls = <String>[];
    for (int i = 0; i < _certifications.length; i++) {
      final url = await _upload(_certifications[i], 'workers/$ts/cert_$i.jpg');
      if (url != null) certUrls.add(url);
    }
    setState(() => _uploading = false);
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => WorkerSignup4Screen(
        name: widget.name, phone: widget.phone,
        nationalId: widget.nationalId, jobType: widget.jobType,
        nicFrontUrl: nicFrontUrl ?? '',
        nicBackUrl: nicBackUrl ?? '',
        profilePhotoUrl: profileUrl ?? '',
        certificationUrls: certUrls,
      ),
    ));
  }

  Widget _uploadBox(String label, File? file, VoidCallback onTap, {bool small = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: small ? 90 : double.infinity,
        height: small ? 90 : 80,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(12),
          border: file != null ? Border.all(color: AppColors.primary, width: 1.5) : null,
        ),
        child: file != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.file(file, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: AppColors.neutral4, size: 28),
                  if (!small) ...[
                    const SizedBox(height: 4),
                    Text(label,
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.neutral4),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppColors.mainGradient)),
          SafeArea(
            child: Column(
              children: [
                ScreenHelpers.navBar(context, 'Sign up'),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30), topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(left: 45, right: 45, top: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Upload required documents',
                            style: GoogleFonts.poppins(
                              fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // NIC
                          Text('Front and Back of National ID',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500,
                              color: AppColors.neutral1),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _uploadBox('National ID (front)', _nicFront,
                                () => _pick('front'))),
                              const SizedBox(width: 12),
                              Expanded(child: _uploadBox('National ID (back)', _nicBack,
                                () => _pick('back'))),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Color(0xFFF0F0F0)),
                          const SizedBox(height: 12),
                          // Certifications
                          Text('Proof of Skills or Certifications (Minimum 3)',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500,
                              color: AppColors.neutral1),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10, runSpacing: 10,
                            children: [
                              ..._certifications.map((f) => _uploadBox('', f, () {}, small: true)),
                              if (_certifications.length < 5)
                                GestureDetector(
                                  onTap: _pickCert,
                                  child: Container(
                                    width: 90, height: 90,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2F2F2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add, color: AppColors.neutral4, size: 28),
                                        Text('Upload',
                                          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.neutral4)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Color(0xFFF0F0F0)),
                          const SizedBox(height: 12),
                          // Profile photo
                          Text('Profile photo (32 x 32)',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500,
                              color: AppColors.neutral1),
                          ),
                          const SizedBox(height: 10),
                          _uploadBox('Upload', _profilePhoto, () => _pick('profile'), small: true),
                          const SizedBox(height: 32),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: _uploading ? null : _proceed,
                              child: Container(
                                width: 56, height: 56,
                                decoration: const BoxDecoration(
                                  gradient: AppColors.mainGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: _uploading
                                    ? const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.arrow_forward, color: Colors.white, size: 24),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ScreenHelpers.signInLink(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Image.asset(
              'assets/images/bottom-line.png',
              fit: BoxFit.fitWidth,
            ),
          ),
        ],
      ),
    );
  }
}