import 'package:flutter/material.dart';

import '../../../../services/user_service.dart';
import '../../../../widgets/gradient_button.dart';

class WorkerOfferScreen extends StatefulWidget {
  const WorkerOfferScreen({super.key});

  @override
  State<WorkerOfferScreen> createState() => _WorkerOfferScreenState();
}

class _WorkerOfferScreenState extends State<WorkerOfferScreen> {
  final UserService _userService = UserService();
  
  bool _isLoading = true;
  bool _isSaving = false;

  bool _hasOffer = false;
  String? _selectedOfferType;
  final _offerDetailsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOfferData();
  }

  Future<void> _loadOfferData() async {
    try {
      final user = await _userService.getCurrentUserData();
      if (!mounted) return;

      if (user != null) {
        _hasOffer = user['hasOffer'] ?? false;
        _selectedOfferType = user['offerType']?.toString();
        _offerDetailsController.text = (user['offerDetails'] ?? '').toString();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnack('Failed to load offer settings: $e');
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await _userService.updateUserOffers(
        hasOffer: _hasOffer,
        offerType: _selectedOfferType,
        offerDetails: _offerDetailsController.text.trim(),
      );

      if (!mounted) return;
      _showSuccessSnack('Special offers updated successfully');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnack('Failed to update offers: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
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
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
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

  @override
  void dispose() {
    _offerDetailsController.dispose();
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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text(
          'Special Offers',
          style: TextStyle(
            color: Color(0xFF1A1F2E),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1A1F2E)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'YOUR PROMOTIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9AA3B4),
                  letterSpacing: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E6F0), width: 1.5),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF0F0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_offer_outlined,
                          color: Color(0xFFE53935),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Available for offers',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1F2E),
                              ),
                            ),
                            Text(
                              _hasOffer
                                  ? 'Promotional offers are visible'
                                  : 'No special offers running',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF9AA3B4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _hasOffer,
                        onChanged: (value) => setState(() => _hasOffer = value),
                        activeColor: const Color(0xFF4B7DF3),
                      ),
                    ],
                  ),
                  if (_hasOffer) ...[
                    const Divider(height: 24, color: Color(0xFFE2E6F0)),
                    DropdownButtonFormField<String>(
                      value: _selectedOfferType,
                      hint: const Text('Select an offer type'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Free Traveling Fee',
                          child: Text('Free Traveling Fee'),
                        ),
                        DropdownMenuItem(
                          value: 'Percentage Discount',
                          child: Text('Percentage Discount'),
                        ),
                        DropdownMenuItem(
                          value: 'Fixed Amount Discount',
                          child: Text('Fixed Amount Discount'),
                        ),
                        DropdownMenuItem(
                          value: 'Special Promotion',
                          child: Text('Special Promotion'),
                        ),
                      ],
                      onChanged: (val) => setState(() => _selectedOfferType = val),
                      decoration: InputDecoration(
                        labelText: 'Offer Type',
                        labelStyle: const TextStyle(
                          color: Color(0xFF9AA3B4),
                          fontSize: 14,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFE2E6F0), width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFE2E6F0), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF4B7DF3), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _OfferTextField(
                      controller: _offerDetailsController,
                      label: 'Offer Details',
                      hintText: 'e.g. 10% off for first-time customers',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            GradientButton(
              text: 'Save Changes',
              onPressed: _save,
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;

  const _OfferTextField({
    required this.controller,
    required this.label,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9AA3B4),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1F2E),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFFCBD0DC),
              fontSize: 14,
            ),
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E6F0), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E6F0), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4B7DF3), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
