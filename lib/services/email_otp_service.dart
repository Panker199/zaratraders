import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailOtpService {
  static const String _baseUrl = 'https://otp-service-beta.vercel.app';
  static const String _orgName = 'ZaraTraders';
  static const String _subject = 'ZaraTraders - OTP Verification';

  Future<String?> sendOtp(String email, {String type = 'numeric'}) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/otp/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'type': type,
          'organization': _orgName,
          'subject': _subject,
        }),
      );
      if (res.statusCode == 200) return null;
      final body = jsonDecode(res.body);
      return body['message'] as String? ?? 'Failed to send OTP';
    } catch (e) {
      return 'Network error: $e';
    }
  }

  Future<String?> verifyOtp(String email, String otp) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/otp/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );
      if (res.statusCode == 200) return null;
      final body = jsonDecode(res.body);
      return body['message'] as String? ?? 'Invalid OTP';
    } catch (e) {
      return 'Network error: $e';
    }
  }
}
