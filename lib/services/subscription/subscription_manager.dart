import 'package:firebase_auth/firebase_auth.dart';

import 'revenuecat_subscription_service.dart';

class SubscriptionManager {
  static final SubscriptionManager _instance = SubscriptionManager._internal();
  factory SubscriptionManager() => _instance;
  SubscriptionManager._internal();

  final RevenueCatService _revenueCatService = RevenueCatService();
  bool _hasActiveSubscription = false;

  Future<void> initialize(String userId) async {
    await _revenueCatService.initialize(userId);
    await checkSubscriptionStatus(userId: userId);
  }

  Future<bool> checkSubscriptionStatus({String? userId}) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if ((currentUser?.email ?? "") == "offfahad1@gmail.com") {
        _hasActiveSubscription = true;
        print(
          "✅ Tester override: subscription forced active for ${currentUser?.email}",
        );
        return _hasActiveSubscription;
      }

      // otherwise check normally
      _hasActiveSubscription = await _revenueCatService.hasActiveSubscription();
      return _hasActiveSubscription;
    } catch (e) {
      print('❌ Error checking subscription status: $e');
      return _hasActiveSubscription; // Return cached value on error
    }
  }

  bool get hasActiveSubscription => _hasActiveSubscription;
}
