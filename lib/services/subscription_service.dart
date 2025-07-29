import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/snackbar_helper.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache the subscription status to avoid repeated Firebase calls
  bool? _cachedSubscriptionStatus;
  String? _cachedUserId;

  /// Check if the current user is subscribed
  Future<bool> isUserSubscribed() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('🔴 No authenticated user found');
        return false;
      }

      // Use cached value if available for the same user
      if (_cachedUserId == currentUser.uid &&
          _cachedSubscriptionStatus != null) {
        print(
            '🟢 Using cached subscription status: $_cachedSubscriptionStatus');
        return _cachedSubscriptionStatus!;
      }

      // Fetch from Firestore
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        print('🔴 User document not found in Firestore');
        return false;
      }

      final isSubscribed = userDoc.data()?['isSubscribed'] ??
          true; // Default to true for testing

      // Cache the result
      _cachedSubscriptionStatus = isSubscribed;
      _cachedUserId = currentUser.uid;

      print('🟢 User subscription status: $isSubscribed');
      return isSubscribed;
    } catch (e) {
      print('🔴 Error checking subscription status: $e');
      return false;
    }
  }

  /// Clear the cached subscription status (call when user data changes)
  void clearCache() {
    _cachedSubscriptionStatus = null;
    _cachedUserId = null;
    print('🟢 Subscription cache cleared');
  }

  /// Update user subscription status
  Future<void> updateSubscriptionStatus(bool isSubscribed) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      await _firestore.collection('users').doc(currentUser.uid).update({
        'isSubscribed': isSubscribed,
        'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Update cache
      _cachedSubscriptionStatus = isSubscribed;
      _cachedUserId = currentUser.uid;

      print('🟢 Subscription status updated to: $isSubscribed');
    } catch (e) {
      print('🔴 Error updating subscription status: $e');
      throw e;
    }
  }

  /// Check subscription and show appropriate message if not subscribed
  Future<bool> checkSubscriptionWithDialog(
      BuildContext context, String action) async {
    final isSubscribed = await isUserSubscribed();

    if (!isSubscribed) {
      _showSubscriptionRequiredDialog(context, action);
      return false;
    }

    return true;
  }

  /// Show subscription required dialog
  void _showSubscriptionRequiredDialog(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Abonnement erforderlich'),
          content: Text(
            'Um $action zu können, benötigen Sie ein aktives Abonnement. '
            'Bitte upgraden Sie Ihr Konto, um diese Funktion zu nutzen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Navigate to subscription/upgrade page
                _showUpgradeOptions(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 107, 69, 106),
                foregroundColor: Colors.white,
              ),
              child: Text('Upgraden'),
            ),
          ],
        );
      },
    );
  }

  /// Show upgrade options (placeholder for future implementation)
  void _showUpgradeOptions(BuildContext context) {
    SnackBarHelper.showInfoSnackBar(
        context, 'Upgrade-Optionen werden bald verfügbar sein!');
  }

  /// Check subscription for creating new items
  Future<bool> canCreateNewItems(BuildContext context) async {
    return await checkSubscriptionWithDialog(
        context, 'neue Elemente zu erstellen');
  }

  /// Check subscription for sending invitations
  Future<bool> canSendInvitations(BuildContext context) async {
    return await checkSubscriptionWithDialog(context, 'Einladungen zu senden');
  }

  /// Get subscription status for UI display
  Future<String> getSubscriptionStatusText() async {
    final isSubscribed = await isUserSubscribed();
    return isSubscribed ? 'Premium' : 'Kostenlos';
  }

  /// Check if user can perform action without showing dialog (for UI state)
  Future<bool> canPerformActionSilent() async {
    return await isUserSubscribed();
  }
}
