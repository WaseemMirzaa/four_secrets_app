import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/email_send_response.dart';

class EmailService {
  static const String baseUrl = 'http://164.92.175.72:8080';
  static const String sendEndpoint = '/api/email/send';
  static const String sendInvitationEndpoint = '/api/email/send-invitation';
  static const String sendDeclinedInvitationEndpoint =
      '/api/email/declined-invitation';
  static const String sendRevokeAccessEndpoint = '/api/email/revoke-access';

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
          'from': "4secrets-wedding@gmx.de",
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        print(jsonResponse['status']);
        print(jsonResponse['message']);
        print(jsonResponse['data']);
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

  Future<EmailSendResponse> sendInvitationEmail({
    required String email,
    required String inviterName,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$sendInvitationEndpoint');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'inviterName': inviterName,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        print(jsonResponse['message']);
        print(jsonResponse['data']);
        print(jsonResponse['status']);
        return EmailSendResponse.fromJson(jsonResponse);
      } else {
        throw Exception(
            'Failed to send invitation email: \\${response.statusCode} - \\${response.body}');
      }
    } catch (e) {
      print('Error sending invitation email: $e');
      throw Exception('Failed to send invitation email: $e');
    }
  }

  Future<EmailSendResponse> sendDeclinedInvitationEmail({
    required String email,
    required String declinerName,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$sendDeclinedInvitationEndpoint');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'declinerName': declinerName,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        print(jsonResponse['message']);
        print(jsonResponse['data']);
        print(jsonResponse['status']);
        return EmailSendResponse.fromJson(jsonResponse);
      } else {
        throw Exception(
            'Failed to send declined invitation email: \\${response.statusCode} - \\${response.body}');
      }
    } catch (e) {
      print('Error sending declined invitation email: $e');
      throw Exception('Failed to send declined invitation email: $e');
    }
  }

  Future<EmailSendResponse> sendRevokeAccessEmail({
    required String email,
    required String inviterName,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$sendRevokeAccessEndpoint');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'inviterName': inviterName,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        print(jsonResponse['message']);
        print(jsonResponse['data']);
        print(jsonResponse['status']);
        return EmailSendResponse.fromJson(jsonResponse);
      } else {
        throw Exception(
            'Failed to send revoke access email: \\${response.statusCode} - \\${response.body}');
      }
    } catch (e) {
      print('Error sending revoke access email: $e');
      throw Exception('Failed to send revoke access email: $e');
    }
  }
}
