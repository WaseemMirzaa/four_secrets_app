import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';

import '../../services/email_service.dart';

class TestEmailScreen extends StatefulWidget {
  const TestEmailScreen({super.key});

  @override
  State<TestEmailScreen> createState() => _TestEmailScreenState();
}

class _TestEmailScreenState extends State<TestEmailScreen> {
  final EmailService _emailService = EmailService();
  bool _isSending = false;
  String _result = '';

  Future<void> _sendRealSubscriptionEmail() async {
    setState(() {
      _isSending = true;
      _result = '';
    });

    try {
      //const testEmail = 'manlen@live.de';
      const testEmail = 'mughalfahad544@gmail.com';
      //const testUserName = 'Elena';
      const testUserName = 'Fahad';
      const testPlanName = 'Premium jährlich';
      const testPrice = '€64,99';
      const testBillingPeriod = 'pro Jahr';

      final response = await _emailService.sendSubscriptionEmail(
        email: testEmail,
        userName: testUserName,
        planName: testPlanName,
        price: testPrice,
        billingPeriod: testBillingPeriod,
        nextBillingDate: '2.1.2027',
        orderId: '${DateTime.now().millisecondsSinceEpoch}',
      );

      setState(() {
        _result = '✅ Echte Test-E-Mail gesendet!\nStatus: ${response.status}';
      });

      SnackBarHelper.showSuccessSnackBar(
        context,
        'Echte Test-E-Mail gesendet an $testEmail',
      );
    } catch (e) {
      setState(() {
        _result = '❌ Fehler: $e';
      });

      SnackBarHelper.showErrorSnackBar(context, 'Fehler: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test E-Mail System'),
        backgroundColor: const Color.fromARGB(255, 107, 69, 106),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test E-Mail Senden',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Empfänger: mughalfahad544@gmail.com\n'
                      'Sprache: Deutsch\n'
                      'Typ: Abonnement Bestätigung',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isSending ? null : _sendRealSubscriptionEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 107, 69, 106),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Echte Abonnement-E-Mail senden'),
            ),

            const SizedBox(height: 20),

            // Loading indicator
            if (_isSending)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Sende E-Mail...', style: TextStyle(color: Colors.grey)),
                ],
              ),

            // Result display
            if (_result.isNotEmpty)
              Card(
                color: _result.contains('✅')
                    ? Colors.green[50]
                    : Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _result,
                    style: TextStyle(
                      color: _result.contains('✅')
                          ? Colors.green[800]
                          : Colors.red[800],
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Email preview
            Expanded(
              child: SingleChildScrollView(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'E-Mail Vorschau:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Betreff: Ihr Abonnement für 4 Secrets Wedding App\n\n'
                          'Sehr geehrte/r Max Mustermann,\n\n'
                          'Herzlichen Glückwunsch! Sie haben erfolgreich das Premium Jahresabo abonniert.\n\n'
                          'Ihre Bestelldetails:\n'
                          '- Abonnement: Premium Jahresabo\n'
                          '- Preis: €59,99 pro Jahr\n'
                          '- Nächste Verlängerung: 15.12.2024\n'
                          '- Bestellnummer: TEST-ORDER-123456\n\n'
                          'Sie erhalten jetzt vollen Zugriff auf alle Premium-Funktionen...',
                          style: TextStyle(color: Colors.grey[700]),
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
    );
  }
}
