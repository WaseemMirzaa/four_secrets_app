import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../email_service.dart';

class SubscriptionEmailHelper {
  final EmailService _emailService = EmailService();

  /// Send subscription confirmation after successful purchase
  Future<void> sendSubscriptionConfirmation({
    required CustomerInfo customerInfo,
    required String packageIdentifier,
    required String priceString,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        log('[EMAIL] No user logged in');
        return;
      }

      final userEmail = user.email;
      if (userEmail == null || userEmail.isEmpty) {
        log('[EMAIL] User has no email');
        return;
      }

      // Get user details
      final userName = await _getUserName(user);

      // Parse subscription details
      final subscriptionDetails = _parseSubscriptionDetails(
        packageIdentifier: packageIdentifier,
        priceString: priceString,
        customerInfo: customerInfo,
      );

      // Send German email to user
      await _emailService.sendSubscriptionEmail(
        email: userEmail,
        userName: userName,
        planName: subscriptionDetails['planName']!,
        price: subscriptionDetails['price']!,
        billingPeriod: subscriptionDetails['billingPeriod']!,
        nextBillingDate: subscriptionDetails['nextBillingDate'],
        orderId: subscriptionDetails['orderId'],
      );
    } catch (e) {
      log('[EMAIL] Error sending subscription email: $e');
      // Don't throw - email should not block purchase flow
    }
  }

  /// Get user name from Firebase
  Future<String> _getUserName(User user) async {
    try {
      // Try display name first
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        return user.displayName!;
      }

      // Try Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        final name =
            data?['name'] ?? data?['displayName'] ?? data?['firstName'];
        if (name != null && name.toString().isNotEmpty) {
          return name.toString();
        }
      }

      // Fallback to email prefix
      final emailPrefix = user.email?.split('@').first ?? 'Benutzer';
      return emailPrefix;
    } catch (e) {
      return 'Lieber Benutzer';
    }
  }

  /// Parse subscription details from RevenueCat data
  Map<String, String?> _parseSubscriptionDetails({
    required String packageIdentifier,
    required String priceString,
    required CustomerInfo customerInfo,
  }) {
    String planName;
    String billingPeriod;

    // Determine plan type
    if (packageIdentifier.toLowerCase().contains('month') ||
        packageIdentifier.toLowerCase().contains('monat')) {
      planName = 'Premium monatlich';
      billingPeriod = 'pro Monat';
    } else if (packageIdentifier.toLowerCase().contains('year') ||
        packageIdentifier.toLowerCase().contains('jahr')) {
      planName = 'Premium jährlich';
      billingPeriod = 'pro Jahr';
    } else {
      planName = 'Premium Abonnement';
      billingPeriod = 'pro Monat';
    }

    // Get next billing date - use purchase date + billing period
    String? nextBillingDate;
    final entitlement = customerInfo.entitlements.all['premium'];

    if (entitlement?.latestPurchaseDate != null) {
      final purchaseDate = DateTime.parse(entitlement!.latestPurchaseDate!);

      // Calculate next billing date based on plan type
      DateTime nextDate;
      if (packageIdentifier.toLowerCase().contains('year') ||
          packageIdentifier.toLowerCase().contains('jahr')) {
        // Yearly subscription
        nextDate = DateTime(
          purchaseDate.year + 1,
          purchaseDate.month,
          purchaseDate.day,
        );
      } else {
        // Monthly subscription (default)
        nextDate = DateTime(
          purchaseDate.year,
          purchaseDate.month + 1,
          purchaseDate.day,
        );
      }

      // Format date as dd.mm.yyyy
      nextBillingDate = '${nextDate.day}.${nextDate.month}.${nextDate.year}';
    }

    // Get order ID from latest transaction
    String? orderId;
    final transactions = customerInfo.allPurchaseDates;
    if (transactions.isNotEmpty) {
      orderId = transactions.keys.last;
    }

    return {
      'planName': planName,
      'price': priceString,
      'billingPeriod': billingPeriod,
      'nextBillingDate': nextBillingDate,
      'orderId': orderId,
    };
  }
}
