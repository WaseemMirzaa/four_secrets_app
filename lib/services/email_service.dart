import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/email_send_response.dart';

class EmailService {
  static const String baseUrl = 'http://164.92.175.72';
  static const String sendEndpoint = '/api/email/send';

  Future<EmailSendResponse> sendEmail({
    required String email,
    required String subject,
    required String message,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$sendEndpoint');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'subject': subject,
          'message': message,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        return EmailSendResponse.fromJson(jsonResponse);
      } else {
        throw Exception(
            'Failed to send email: \\${response.statusCode} - \\${response.body}');
      }
    } catch (e) {
      print('Error sending email: $e');
      throw Exception('Failed to send email: $e');
    }
  }
}
