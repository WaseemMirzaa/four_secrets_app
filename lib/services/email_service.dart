import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/email_send_response.dart';

class EmailService {
  // New Brevo API server base URL
  static const String baseUrl = 'http://164.92.175.72:3001';
  //static const String baseUrl = 'http://localhost:3001';

  /// Get current user's name from Firebase
  static Future<String> _getCurrentUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('[EMAIL_LOG] No authenticated user found');
        return 'Wedding Planner User';
      }

      // Try to get display name first
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        print('[EMAIL_LOG] Using display name: ${user.displayName}');
        return user.displayName!;
      }

      // Try to get name from Firestore user document
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          final name =
              userData?['name'] ??
              userData?['displayName'] ??
              userData?['firstName'];
          if (name != null && name.toString().isNotEmpty) {
            print('[EMAIL_LOG] Using Firestore name: $name');
            return name.toString();
          }
        }
      } catch (e) {
        print('[EMAIL_LOG] Error fetching user from Firestore: $e');
      }

      // Fallback to email prefix
      final emailPrefix = user.email?.split('@').first ?? 'User';
      print('[EMAIL_LOG] Using email prefix as name: $emailPrefix');
      return emailPrefix;
    } catch (e) {
      print('[EMAIL_LOG] Error getting current user name: $e');
      return 'Wedding Planner User';
    }
  }

  static const String sendCustomEndpoint = '/api/email/send';
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
          'Failed to send email: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error sending email: $e');
      throw Exception('Failed to send email: $e');
    }
  }

  /// Send wedding invitation email using Brevo API
  Future<EmailSendResponse> sendInvitationEmail({
    required String email,
    String? inviterName, // Made optional
  }) async {
    // Get current user's name from Firebase if inviterName not provided
    final currentUserName = await _getCurrentUserName();
    print('[EMAIL_LOG] Using inviter name: $currentUserName');

    try {
      final uri = Uri.parse('$baseUrl$sendInvitationEndpoint');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': '4SecretsWeddingApp/1.0',
        },
        body: json.encode({'email': email, 'inviterName': currentUserName}),
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
          'Failed to send invitation email: ${response.statusCode} - ${response.body}',
        );
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
        body: json.encode({'email': email, 'declinerName': declinerName}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        print(
          '[EMAIL_LOG] Declined invitation email sent: ${jsonResponse['message']}',
        );
        return EmailSendResponse.fromJson({
          'message':
              jsonResponse['message'] ??
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
          'Failed to send declined invitation email: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error sending declined invitation email: $e');
      throw Exception('Failed to send declined invitation email: $e');
    }
  }

  /// Send access revoked notification email using Brevo API
  Future<EmailSendResponse?> sendRevokeAccessEmail({
    required String email,
    String? inviterName, // Made optional
  }) async {
    // Get current user's name from Firebase if inviterName not provided
    final currentUserName = inviterName ?? await _getCurrentUserName();
    print('[EMAIL_LOG] Using revoker name: $currentUserName');

    try {
      final uri = Uri.parse('$baseUrl$sendRevokeAccessEndpoint');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': '4SecretsWeddingApp/1.0',
        },
        body: json.encode({'email': email, 'inviterName': currentUserName}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        print(
          '[EMAIL_LOG] Revoke access email sent: ${jsonResponse['message']}',
        );
        return EmailSendResponse.fromJson({
          'message':
              jsonResponse['message'] ??
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
          'Failed to send revoke access email: ${response.statusCode} - ${response.body}',
        );
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
        body: json.encode({'email': email, 'userName': userName}),
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
          'Failed to send welcome email: ${response.statusCode} - ${response.body}',
        );
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

  /// Send subscription confirmation email using existing custom endpoint with HTML formatting
  Future<EmailSendResponse> sendSubscriptionEmail({
    required String email,
    required String userName,
    required String planName,
    required String price,
    required String billingPeriod,
    String? nextBillingDate,
    String? orderId,
  }) async {
    try {
      // Build the email content in German with HTML
      final subject = 'Willkommen bei 4secrets – Wedding Planner';

      final message = buildSubscriptionEmailHtml(
        userName: userName,
        planName: planName,
        price: price,
        billingPeriod: billingPeriod,
        nextBillingDate: nextBillingDate,
      );

      // Call existing sendEmail endpoint
      return await sendEmail(email: email, subject: subject, message: message);
    } catch (e) {
      print('Error creating subscription email: $e');
      rethrow;
    }
  }

  String buildSubscriptionEmailHtml({
    required String userName,
    required String planName,
    required String price,
    required String billingPeriod,
    String? nextBillingDate,
  }) {
    return '<html><body>'
        '<div align="center">'
        '<img src="https://res.cloudinary.com/dhnupmrhv/image/upload/v1767287927/Logo_4secrets_-_Wedding_Planner_App_e4sfqw.jpg" '
        'alt="4secrets – Wedding Planner" width="120">'
        '</div><br>'
        'Liebe/r <b>$userName</b>,<br><br>'
        'Vielen Dank, dass du dich für 4secrets – Wedding Planner entschieden hast.<br>'
        'Wir freuen uns sehr, dich auf dem Weg zu einem der schönsten Tage deines Lebens begleiten zu dürfen.<br><br>'
        'Dein Abonnement wurde erfolgreich aktiviert.<br>'
        'Ab sofort kannst du alle Funktionen unserer App nutzen.<br>'
        'So kannst du deinen Hochzeitstag entspannt, übersichtlich und mit ganz viel Vorfreude planen.<br><br>'
        'Solltest du Fragen haben oder Unterstützung benötigen, sind wir jederzeit gerne für dich da.<br>'
        'Auch für neue Inspirationen kannst du uns jederzeit kontaktieren.<br>'
        'Wir begleiten dich mit Herz und Leidenschaft durch deine Hochzeitsplanung.<br><br>'
        'Wir wünschen dir ganz viel Freude bei der Planung.<br>'
        'Und eine unvergessliche Hochzeitszeit.<br><br>'
        'Herzliche Grüße<br>'
        'Dein 4secrets – Wedding Planner Team 💍<br><br>'
        '<b>Dein Abonnement</b><br>'
        'Abonnement: $planName<br>'
        'Preis: $price $billingPeriod<br>'
        '${nextBillingDate != null ? 'Nächste Verlängerung: $nextBillingDate<br>' : ''}<br>'
        '<b>Kontakt:</b><br>'
        'E-Mail: 4secrets-wedding@gmx.de<br>'
        'Website: https://www.4secrets-wedding-planner.de<br><br>'
        '<br><br><br>'
        '© ${DateTime.now().year} 4secrets – Wedding Planner'
        '</body></html>';
  }
}
