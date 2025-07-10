import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/email_send_response.dart';

class EmailService {
  // New Brevo API server base URL
  static const String baseUrl = 'http://164.92.175.72:3001';
  static const String sendCustomEndpoint = '/api/email/send-custom';
  static const String sendInvitationEndpoint = '/api/email/send-invitation';
  static const String sendDeclinedInvitationEndpoint =
      '/api/email/declined-invitation';
  static const String sendRevokeAccessEndpoint = '/api/email/revoke-access';
  static const String sendWelcomeEndpoint = '/api/email/send-welcome';
  static const String healthEndpoint = '/health';
  static const String statusEndpoint = '/api/email/status';

  /// Send custom email using Brevo API
  Future<EmailSendResponse> sendEmail({
    required String email,
    required String subject,
    required String message,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$sendCustomEndpoint');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': '4SecretsWeddingApp/1.0',
        },
        body: json.encode({
          'email': email,
          'subject': subject,
          'message': message,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        print('[EMAIL_LOG] Custom email sent: ${jsonResponse['message']}');
        return EmailSendResponse.fromJson({
          'message':
              jsonResponse['message'] ?? 'Custom email sent successfully',
          'status': jsonResponse['success'] == true ? 'success' : 'error',
          'data': {
            'messageId': jsonResponse['messageId'],
            'service': jsonResponse['service'],
            'timestamp': jsonResponse['timestamp'],
          },
        });
      } else {
        throw Exception(
            'Failed to send email: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error sending email: $e');
      throw Exception('Failed to send email: $e');
    }
  }

  /// Send wedding invitation email using Brevo API
  Future<EmailSendResponse> sendInvitationEmail({
    required String email,
    required String inviterName,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$sendInvitationEndpoint');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': '4SecretsWeddingApp/1.0',
        },
        body: json.encode({
          'email': email,
          'inviterName': inviterName,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        print('[EMAIL_LOG] Invitation email sent: ${jsonResponse['message']}');
        return EmailSendResponse.fromJson({
          'message':
              jsonResponse['message'] ?? 'Wedding invitation sent successfully',
          'status': jsonResponse['success'] == true ? 'success' : 'error',
          'data': {
            'messageId': jsonResponse['messageId'],
            'service': jsonResponse['service'],
            'timestamp': jsonResponse['timestamp'],
          },
        });
      } else {
        throw Exception(
            'Failed to send invitation email: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error sending invitation email: $e');
      throw Exception('Failed to send invitation email: $e');
    }
  }

  /// Send declined invitation notification email using Brevo API
  Future<EmailSendResponse> sendDeclinedInvitationEmail({
    required String email,
    required String declinerName,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$sendDeclinedInvitationEndpoint');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': '4SecretsWeddingApp/1.0',
        },
        body: json.encode({
          'email': email,
          'declinerName': declinerName,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        print(
            '[EMAIL_LOG] Declined invitation email sent: ${jsonResponse['message']}');
        return EmailSendResponse.fromJson({
          'message': jsonResponse['message'] ??
              'Declined invitation notification sent successfully',
          'status': jsonResponse['success'] == true ? 'success' : 'error',
          'data': {
            'messageId': jsonResponse['messageId'],
            'service': jsonResponse['service'],
            'timestamp': jsonResponse['timestamp'],
          },
        });
      } else {
        throw Exception(
            'Failed to send declined invitation email: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error sending declined invitation email: $e');
      throw Exception('Failed to send declined invitation email: $e');
    }
  }

  /// Send access revoked notification email using Brevo API
  Future<EmailSendResponse?> sendRevokeAccessEmail({
    required String email,
    required String inviterName,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$sendRevokeAccessEndpoint');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': '4SecretsWeddingApp/1.0',
        },
        body: json.encode({
          'email': email,
          'inviterName': inviterName,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        print(
            '[EMAIL_LOG] Revoke access email sent: ${jsonResponse['message']}');
        return EmailSendResponse.fromJson({
          'message': jsonResponse['message'] ??
              'Access revoked notification sent successfully',
          'status': jsonResponse['success'] == true ? 'success' : 'error',
          'data': {
            'messageId': jsonResponse['messageId'],
            'service': jsonResponse['service'],
            'timestamp': jsonResponse['timestamp'],
          },
        });
      } else {
        print(
            'Failed to send revoke access email: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error sending revoke access email: $e');
      return null;
    }
  }

  /// Send welcome email using Brevo API
  Future<EmailSendResponse> sendWelcomeEmail({
    required String email,
    required String userName,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$sendWelcomeEndpoint');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': '4SecretsWeddingApp/1.0',
        },
        body: json.encode({
          'email': email,
          'userName': userName,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        print('[EMAIL_LOG] Welcome email sent: ${jsonResponse['message']}');
        return EmailSendResponse.fromJson({
          'message':
              jsonResponse['message'] ?? 'Welcome email sent successfully',
          'status': jsonResponse['success'] == true ? 'success' : 'error',
          'data': {
            'messageId': jsonResponse['messageId'],
            'service': jsonResponse['service'],
            'timestamp': jsonResponse['timestamp'],
          },
        });
      } else {
        throw Exception(
            'Failed to send welcome email: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error sending welcome email: $e');
      throw Exception('Failed to send welcome email: $e');
    }
  }

  /// Check email service health
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final uri = Uri.parse('$baseUrl$healthEndpoint');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('[EMAIL_LOG] Health check: ${jsonResponse['status']}');
        return jsonResponse;
      } else {
        throw Exception('Health check failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking email service health: $e');
      throw Exception('Failed to check health: $e');
    }
  }

  /// Check email service status
  Future<Map<String, dynamic>> checkStatus() async {
    try {
      final uri = Uri.parse('$baseUrl$statusEndpoint');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('[EMAIL_LOG] Status check: ${jsonResponse['status']}');
        return jsonResponse;
      } else {
        throw Exception('Status check failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking email service status: $e');
      throw Exception('Failed to check status: $e');
    }
  }
}
