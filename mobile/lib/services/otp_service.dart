import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'email_service.dart';

class OtpService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String generateOtp() {
    final rand = Random();
    return (1000 + rand.nextInt(9000)).toString();
  }

  /// Sends an OTP for password-reset flow (checks that email exists first).
  Future<String?> sendOtp(String email) async {
    try {
      // Check email exists in users collection
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null; // email not found

      final otp = generateOtp();
      final expiry = DateTime.now().add(const Duration(minutes: 10));

      await _firestore.collection('otp_requests').doc(email).set({
        'otp': otp,
        'expiresAt': Timestamp.fromDate(expiry),
        'email': email,
      });

      // Send styled email
      final sent = await EmailService.sendOtpEmail(
        recipientEmail: email,
        otp: otp,
        purpose: 'Password Reset',
      );
      if (!sent) {
        print('⚠ Email delivery failed for $email — OTP stored in Firestore.');
      }

      return otp;
    } catch (e) {
      return null;
    }
  }

  /// Sends an OTP for signup flows (no prior user check needed).
  Future<String?> sendSignupOtp(String email, {String purpose = 'Sign Up'}) async {
    try {
      final otp = generateOtp();
      final expiry = DateTime.now().add(const Duration(minutes: 10));

      await _firestore.collection('otp_requests').doc(email).set({
        'otp': otp,
        'expiresAt': Timestamp.fromDate(expiry),
        'email': email,
      });

      // Send styled email
      final sent = await EmailService.sendOtpEmail(
        recipientEmail: email,
        otp: otp,
        purpose: purpose,
      );
      if (!sent) {
        print('⚠ Email delivery failed for $email — OTP stored in Firestore.');
      }

      return otp;
    } catch (e) {
      return null;
    }
  }

  Future<bool> verifyOtp(String email, String enteredOtp) async {
    try {
      final doc = await _firestore.collection('otp_requests').doc(email).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final storedOtp = data['otp'] as String;
      final expiry = (data['expiresAt'] as Timestamp).toDate();

      if (DateTime.now().isAfter(expiry)) return false;
      return storedOtp == enteredOtp;
    } catch (e) {
      return false;
    }
  }
}