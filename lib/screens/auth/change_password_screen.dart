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

  // ✅ Computed property — no need for _checkEnabled() at all
  bool get _enabled =>
      _passCtrl.text.isNotEmpty &&
      _confirmCtrl.text.isNotEmpty &&
      _confirmCtrl.text == _passCtrl.text;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    final passError = Validators.password(_passCtrl.text);
    if (passError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(passError)));
      return;
    }
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.email);
      await FirebaseFirestore.instance
          .collection('password_resets')
          .doc(widget.email)
          .set({
        'newPassword': _passCtrl.text,
        'requestedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.push(context,
        MaterialPageRoute(builder: (_) => const PasswordSuccessScreen()));
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
      resizeToAvoidBottomInset: false,
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
                            fontSize: 20, fontWeight: FontWeight.w600,
                            color: Colors.white,
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
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24, left: 40, right: 40),
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
                                  // ✅ onChanged calls setState to recompute _enabled
                                  AppTextField(
                                    label: 'Type your new password',
                                    placeholder: '••••••••••••',
                                    obscure: true,
                                    controller: _passCtrl,
                                    validator: Validators.password,
                                    onChanged: (_) => setState(() {}),
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
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 45),
                                  // ✅ _enabled is now a getter — always up to date
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