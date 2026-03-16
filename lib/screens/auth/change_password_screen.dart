import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/app_text_field.dart';
import 'password_success_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String email;
  const ChangePasswordScreen({super.key, required this.email});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _enabled = false;

  void _checkEnabled() {
    setState(() {
      _enabled = _passCtrl.text.isNotEmpty &&
          _confirmCtrl.text == _passCtrl.text;
    });
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    final passError = Validators.password(_passCtrl.text);
    if (passError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(passError)));
      return;
    }
    setState(() => _loading = true);
    try {
      // Use Firebase password reset flow via email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.email);
      // For direct update, you need the user to be signed in.
      // Storing new password hash is not supported directly — use Admin SDK in backend.
      // Here we assume the OTP verified, so update via Firestore flag and handle on backend.
      await FirebaseFirestore.instance.collection('password_resets').doc(widget.email).set({
        'newPassword': _passCtrl.text, // Handle securely on backend
        'requestedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PasswordSuccessScreen()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to change password. Try again.')),
      );
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppColors.mainGradient)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      ),
                      Expanded(
                        child: Text('Change password',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFFDFF),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30), topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF3629B7).withOpacity(0.07),
                                    blurRadius: 30, offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  AppTextField(
                                    label: 'Type your new password',
                                    placeholder: '••••••••••••',
                                    obscure: true,
                                    controller: _passCtrl,
                                    validator: Validators.password,
                                  ),
                                  const SizedBox(height: 16),
                                  AppTextField(
                                    label: 'Confirm password',
                                    placeholder: '••••••••••••',
                                    obscure: true,
                                    controller: _confirmCtrl,
                                    validator: (v) {
                                      if (v != _passCtrl.text) return 'Passwords do not match';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  GradientButton(
                                    text: 'Change password',
                                    onPressed: _enabled ? _changePassword : null,
                                    isLoading: _loading,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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