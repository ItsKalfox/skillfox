import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  // ─── SMTP Configuration ───────────────────────────────────────────
  // TODO: Replace with your actual credentials or load from env/config.
  static const String _smtpHost = 'smtp.gmail.com';
  static const int _smtpPort = 587;
  static const String _smtpUsername = 'skillfox.support@gmail.com';
  static const String _smtpPassword = 'fllx qdxy xwey qxtg';
  static const String _senderName = 'SkillFox';

  /// Sends a stylish OTP email to [recipientEmail].
  /// [otp] is the 4-digit code.
  /// [purpose] describes the context, e.g. "Sign Up", "Password Reset".
  static Future<bool> sendOtpEmail({
    required String recipientEmail,
    required String otp,
    String purpose = 'Verification',
  }) async {
    try {
      final smtpServer = SmtpServer(
        _smtpHost,
        port: _smtpPort,
        username: _smtpUsername,
        password: _smtpPassword,
      );

      final message = Message()
        ..from = Address(_smtpUsername, _senderName)
        ..recipients.add(recipientEmail)
        ..subject = '$purpose Code – $otp'
        ..html = _buildOtpHtml(otp: otp, purpose: purpose, email: recipientEmail);

      await send(message, smtpServer);
      return true;
    } catch (e) {
      print('EmailService.sendOtpEmail error: $e');
      return false;
    }
  }

  /// Builds a modern, stylish HTML email body.
  static String _buildOtpHtml({
    required String otp,
    required String purpose,
    required String email,
  }) {
    // Split OTP into individual digits for the styled boxes
    final digits = otp.split('');

    final digitBoxes = digits.map((d) => '''
      <td style="width:56px;height:64px;background:linear-gradient(135deg,#6C56F0 0%,#469FEF 100%);border-radius:12px;text-align:center;vertical-align:middle;padding:0;margin:0 4px;">
        <span style="font-family:'Helvetica Neue',Arial,sans-serif;font-size:28px;font-weight:700;color:#FFFFFF;letter-spacing:2px;">$d</span>
      </td>
    ''').join('<td style="width:8px;"></td>');

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1.0">
  <title>$purpose Code</title>
</head>
<body style="margin:0;padding:0;background-color:#F4F3FF;font-family:'Helvetica Neue',Arial,sans-serif;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#F4F3FF;padding:40px 20px;">
    <tr>
      <td align="center">
        <table role="presentation" width="480" cellpadding="0" cellspacing="0" style="max-width:480px;width:100%;">

          <!-- LOGO / BRAND HEADER -->
          <tr>
            <td align="center" style="padding-bottom:28px;">
              <table role="presentation" cellpadding="0" cellspacing="0">
                <tr>
                  <td style="background:linear-gradient(135deg,#469FEF 0%,#5C75F0 40%,#6C56F0 100%);border-radius:16px;padding:12px 28px;">
                    <span style="font-family:'Helvetica Neue',Arial,sans-serif;font-size:26px;font-weight:800;color:#FFFFFF;letter-spacing:1px;">Skill</span><span style="font-family:'Helvetica Neue',Arial,sans-serif;font-size:26px;font-weight:800;color:#FFD166;letter-spacing:1px;">Fox</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- MAIN CARD -->
          <tr>
            <td style="background-color:#FFFFFF;border-radius:24px;box-shadow:0 8px 40px rgba(54,41,183,0.10);overflow:hidden;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0">

                <!-- Gradient Banner -->
                <tr>
                  <td style="background:linear-gradient(135deg,#469FEF 0%,#5C75F0 40%,#6C56F0 100%);padding:32px 36px 28px;text-align:center;">
                    <table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 auto 16px;">
                      <tr>
                        <td style="background:rgba(255,255,255,0.18);border-radius:50%;width:64px;height:64px;text-align:center;vertical-align:middle;">
                          <span style="font-size:32px;">🔐</span>
                        </td>
                      </tr>
                    </table>
                    <h1 style="margin:0;font-family:'Helvetica Neue',Arial,sans-serif;font-size:22px;font-weight:700;color:#FFFFFF;letter-spacing:0.5px;">$purpose Code</h1>
                    <p style="margin:8px 0 0;font-family:'Helvetica Neue',Arial,sans-serif;font-size:14px;color:rgba(255,255,255,0.85);">Use the code below to complete your $purpose</p>
                  </td>
                </tr>

                <!-- OTP Digits -->
                <tr>
                  <td style="padding:36px 36px 24px;text-align:center;">
                    <table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 auto;">
                      <tr>
                        $digitBoxes
                      </tr>
                    </table>
                  </td>
                </tr>

                <!-- Expiry Notice -->
                <tr>
                  <td style="padding:0 36px 12px;text-align:center;">
                    <table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 auto;background-color:#FFF8E1;border-radius:10px;padding:10px 20px;">
                      <tr>
                        <td style="font-family:'Helvetica Neue',Arial,sans-serif;font-size:13px;color:#F59E0B;font-weight:600;">
                          ⏱ This code expires in 10 minutes
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>

                <!-- Message Body -->
                <tr>
                  <td style="padding:20px 36px 28px;">
                    <p style="margin:0 0 8px;font-family:'Helvetica Neue',Arial,sans-serif;font-size:15px;color:#343434;line-height:1.6;">
                      Hello,
                    </p>
                    <p style="margin:0 0 8px;font-family:'Helvetica Neue',Arial,sans-serif;font-size:15px;color:#343434;line-height:1.6;">
                      We received a <strong>$purpose</strong> request for <span style="color:#5C75F0;font-weight:600;">$email</span>. Enter the code above in the app to continue.
                    </p>
                    <p style="margin:0;font-family:'Helvetica Neue',Arial,sans-serif;font-size:14px;color:#898989;line-height:1.6;">
                      If you did not request this, you can safely ignore this email. Your account remains secure.
                    </p>
                  </td>
                </tr>

                <!-- Divider -->
                <tr>
                  <td style="padding:0 36px;">
                    <hr style="border:none;height:1px;background-color:#F0F0F0;margin:0;">
                  </td>
                </tr>

                <!-- Footer Inside Card -->
                <tr>
                  <td style="padding:24px 36px 28px;text-align:center;">
                    <p style="margin:0 0 4px;font-family:'Helvetica Neue',Arial,sans-serif;font-size:13px;color:#CACACA;">
                      Need help? Contact us at <span style="color:#5C75F0;">support@skillfox.app</span>
                    </p>
                    <p style="margin:0;font-family:'Helvetica Neue',Arial,sans-serif;font-size:12px;color:#CACACA;">
                      © ${DateTime.now().year} SkillFox. All rights reserved.
                    </p>
                  </td>
                </tr>

              </table>
            </td>
          </tr>

          <!-- OUTER FOOTER -->
          <tr>
            <td align="center" style="padding:24px 0 0;">
              <p style="margin:0;font-family:'Helvetica Neue',Arial,sans-serif;font-size:12px;color:#B0B0B0;">
                This is an automated message — please do not reply.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';
  }
}
