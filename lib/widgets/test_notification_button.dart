import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/services/push_notification_service.dart';

class TestNotificationButton extends StatelessWidget {
  const TestNotificationButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final pushService = PushNotificationService();
        await pushService.sendTestNotification();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification sent! Check your notification panel.'),
            backgroundColor: Colors.green,
          ),
        );
      },
      icon: const Icon(Icons.notifications_active),
      label: const Text('Test Notification'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }
}
