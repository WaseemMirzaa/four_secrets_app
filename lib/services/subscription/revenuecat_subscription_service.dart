import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:four_secrets_wedding_app/constants/revenuecat_consts.dart';
import 'package:four_secrets_wedding_app/services/subscription/revenucecat_purchase_result.dart';
import 'package:four_secrets_wedding_app/services/subscription/revenuecat_purchase_exception.dart';
import 'package:four_secrets_wedding_app/services/subscription/subscription_email_helper.dart';
import 'package:purchases_flutter/purchases_flutter.dart' hide PurchaseResult;

import '../email_service.dart';

class RevenueCatService {
  static const String _iosApiKey = RevenuecatConsts.appleRevenueCatId;
  static const String _androidApiKey = RevenuecatConsts.androidRevenueCatId;

  Future<void> initialize(String userID) async {
    try {
      String apiKey;

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        apiKey = _iosApiKey;
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        apiKey = _androidApiKey;
      } else {
        throw UnsupportedError('Unsupported platform');
      }

      await Purchases.setLogLevel(LogLevel.debug); // Optional for debugging

      final config = PurchasesConfiguration(apiKey)..appUserID = userID;
      await Purchases.configure(config);

      log('RevenueCat initialized successfully');
    } catch (e, stackTrace) {
      log('RevenueCat initialization failed: $e', stackTrace: stackTrace);
      // Optionally rethrow or handle error (e.g. show toast/snackbar)
    }
  }

  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;

  Future<CustomerInfo> getCustomerInfo() async {
    return await Purchases.getCustomerInfo();
  }

  Future<Offerings?> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current == null) {
        debugPrint('⚠️ No current offering found.');
      } else {
        debugPrint('✅ Current offering: ${offerings.current!.identifier}');
        // 🔥 Print all available packages inside the current offering
        for (final package in offerings.current!.availablePackages) {
          final product = package.storeProduct;
          debugPrint('📦 Package: ${package.identifier}');
          debugPrint('   Title: ${product.title}');
          debugPrint('   Description: ${product.description}');
          debugPrint('   Price: ${product.priceString}');
          debugPrint('   Currency: ${product.currencyCode}');
          debugPrint('   Identifier: ${product.identifier}');
          debugPrint(
            '   Trial/Intro: ${product.introductoryPrice?.priceString ?? "None"}',
          );
        }
      }
      return offerings;
    } catch (e, st) {
      debugPrint('❌ Error fetching offerings: $e\n$st');
      return null;
    }
  }

  Future<PurchaseResult> purchasePackage(Package package) async {
    try {
      final purchaserInfo = await Purchases.purchase(
        PurchaseParams.package(package),
      );

      // Update Firebase after successful purchase
      await updateSubscriptionStatusInFirebase(purchaserInfo.customerInfo);
      // Send subscription confirmation email
      _sendSubscriptionEmail(
        customerInfo: purchaserInfo.customerInfo,
        package: package,
      );

      return PurchaseResult(info: purchaserInfo.customerInfo);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      String errorMessage;

      switch (errorCode) {
        case PurchasesErrorCode.purchaseCancelledError:
          errorMessage = "Kauf wurde vom Nutzer abgebrochen.";
          debugPrint("Purchase cancelled by user.");
          break;

        case PurchasesErrorCode.purchaseNotAllowedError:
          errorMessage = "Kauf ist nicht erlaubt.";
          debugPrint("Purchase not allowed.");
          break;

        case PurchasesErrorCode.paymentPendingError:
          errorMessage = "Zahlung ist noch ausstehend.";
          debugPrint("Payment is pending already.");
          break;

        case PurchasesErrorCode.storeProblemError:
          errorMessage = "Es gab ein Problem mit dem Store.";
          debugPrint("Problem with the store.");
          break;

        default:
          errorMessage = "Etwas ist schiefgelaufen. (${e.message})";
          debugPrint("Something went wrong. (${e.message})");
      }

      throw PurchaseException(errorMessage);
    } catch (e) {
      throw PurchaseException("Unexpected error: $e");
    }
  }

  // Add this private helper method
  Future<void> _sendSubscriptionEmail({
    required CustomerInfo customerInfo,
    required Package package,
  }) async {
    try {
      final emailHelper = SubscriptionEmailHelper();
      await emailHelper.sendSubscriptionConfirmation(
        customerInfo: customerInfo,
        packageIdentifier: package.identifier,
        priceString: package.storeProduct.priceString,
      );
      log('[REVENUECAT] Subscription email sent successfully');
    } catch (e) {
      log('[REVENUECAT] Failed to send subscription email: $e');
      // Don't throw - email failure should not affect purchase
    }
  }

  Future<bool> hasActiveSubscription() async {
    final customerInfo = await getCustomerInfo();
    return customerInfo
            .entitlements
            .all[RevenuecatConsts.entitlementsName]
            ?.isActive ??
        false;
  }

  Future<bool> hasPurchasedProduct(String productId) async {
    final customerInfo = await getCustomerInfo();
    return customerInfo.allPurchasedProductIdentifiers.contains(productId);
  }

  // Add method to check subscription status on app start
  Future<void> checkSubscriptionStatus() async {
    try {
      final customerInfo = await getCustomerInfo();
      await updateSubscriptionStatusInFirebase(customerInfo);
    } catch (e) {
      print('❌ Error checking subscription status: $e');
    }
  }

  Future<CustomerInfo> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();

      // Update Firebase after restore
      await updateSubscriptionStatusInFirebase(customerInfo);

      // Send email if subscription was restored
      await _sendRestoredSubscriptionEmail(customerInfo);
      return customerInfo;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      String errorMessage;

      switch (errorCode) {
        case PurchasesErrorCode.purchaseNotAllowedError:
          errorMessage =
              "Wiederherstellung ist auf diesem Gerät nicht erlaubt.";
          debugPrint("Restore not allowed on this device.");
          break;

        case PurchasesErrorCode.purchaseInvalidError:
          errorMessage = "Ungültiger Wiederherstellungsversuch.";
          debugPrint("Invalid restore attempt.");
          break;

        case PurchasesErrorCode.storeProblemError:
          errorMessage = "Es gab ein Problem mit dem Store.";
          debugPrint("There was a problem with the store.");
          break;

        case PurchasesErrorCode.networkError:
          errorMessage = "Netzwerkfehler bei der Wiederherstellung.";
          debugPrint("Network error while restoring purchases.");
          break;

        case PurchasesErrorCode.configurationError:
          errorMessage = "RevenueCat ist nicht richtig konfiguriert.";
          debugPrint("RevenueCat is not configured properly.");
          break;

        default:
          errorMessage = "Wiederherstellung fehlgeschlagen: ${e.message}";
          debugPrint("Failed to restore purchases: ${e.message}");
      }

      throw Exception(errorMessage);
    } catch (e) {
      debugPrint("Unexpected error while restoring purchases: $e");
      throw Exception("Unerwarteter Fehler bei der Wiederherstellung.");
    }
  }

  Future<void> _sendRestoredSubscriptionEmail(CustomerInfo customerInfo) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) return;

      final hasActiveSub =
          customerInfo.entitlements.all['premium']?.isActive ?? false;

      if (hasActiveSub) {
        final EmailService _emailService = EmailService();
        await _emailService.sendSubscriptionEmail(
          email: user!.email!,
          userName: user.displayName ?? 'Benutzer',
          planName: 'Wiederhergestelltes Abonnement',
          price: 'Restored',
          billingPeriod: 'wiederhergestellt',
          nextBillingDate: null,
          orderId: 'Restored: ${DateTime.now()}',
        );
        log('[REVENUECAT] Restore confirmation email sent');
      }
    } catch (e) {
      log('[REVENUECAT] Failed to send restore email: $e');
    }
  }

  String _getPlatform() {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }

  Future<void> updateSubscriptionStatusInFirebase(
    CustomerInfo customerInfo,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final entitlement =
          customerInfo.entitlements.all[RevenuecatConsts.entitlementsName];
      final isActive = entitlement?.isActive ?? false;

      DateTime? expiryDate;
      String? planIdentifier;

      if (isActive && entitlement?.expirationDate != null) {
        expiryDate = DateTime.parse(entitlement!.expirationDate!);

        // Determine plan type based on active entitlement
        if (entitlement.identifier.contains('monthly') ||
            entitlement.productIdentifier.contains('monthly')) {
          planIdentifier = 'monthly';
        } else if (entitlement.identifier.contains('yearly') ||
            entitlement.productIdentifier.contains('yearly')) {
          planIdentifier = 'yearly';
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'isSubscribed': isActive,
            'subscriptionExpiryDate': expiryDate?.toIso8601String(),
            'subscriptionPlan': planIdentifier,
            'lastSubscriptionCheck': FieldValue.serverTimestamp(),
            'subscriptionPlatform': _getPlatform(),
          });

      print('✅ Subscription status updated in Firebase: $isActive');
    } catch (e) {
      print('❌ Error updating subscription in Firebase: $e');
    }
  }
}
