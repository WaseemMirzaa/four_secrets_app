import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Services
import 'package:four_secrets_wedding_app/services/notification_alaram-service.dart';
import 'package:four_secrets_wedding_app/services/push_notification_service.dart';
import 'package:four_secrets_wedding_app/services/todo_unread_status_service.dart';
import 'package:four_secrets_wedding_app/services/wedding_day_schedule_service.dart';
import 'package:four_secrets_wedding_app/screens/newfeature1/services/wedding_day_schedule_service1.dart';

// Models
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _userKey = 'user_data';

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🟢 Attempting sign in for email: $email');

      // Authenticate with Firebase
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print('🟢 Firebase Auth successful, fetching user data...');

      // Reload user to get latest verification status
      await result.user!.reload();

      // Fetch user data from Firestore
      final userDoc =
          await _firestore.collection('users').doc(result.user!.uid).get();

      if (!userDoc.exists) {
        print('🔴 User document not found in Firestore');
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'User data not found in database.',
        );
      }

      print('🟢 User document found: ${userDoc.data()}');

      // Create UserModel from Firestore data
      final userData = userDoc.data()!;
      userData['uid'] = result.user!.uid; // Ensure UID is included
      userData['emailVerified'] =
          result.user!.emailVerified; // Get latest verification status

      // Update verification status in Firestore if needed
      if (result.user!.emailVerified != (userData['emailVerified'] ?? false)) {
        await updateEmailVerificationStatus(result.user!.emailVerified);
      }

      // Update FCM token after login
      final fcmToken = await PushNotificationService().getFcmTokenDirect();
      print('🟢 FCM token: $fcmToken');
      if (fcmToken != null) {
        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .update({'fcmToken': fcmToken});
        print('🟢 FCM token saved to Firestore');
      }

      final userModel = UserModel.fromMap(userData);
      print('🟢 UserModel created successfully: $userModel');

      // Load both wedding schedule services to set up notifications
      final scheduleService = WeddingDayScheduleService();
      await scheduleService.loadData();
      print('🟢 Original wedding schedule service loaded');

      final scheduleService1 = WeddingDayScheduleService1();
      await scheduleService1.loadData();
      print('🟢 Eigene Dienstleister schedule service loaded');

      // Save user data to SharedPreferences
      await saveUserToPrefs(userModel);
      print('🟢 User data saved to SharedPreferences');
      return userModel;
    } catch (e) {
      print('🔴 Error in signIn: $e');
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String name,
    File? profilePicture,
    String? profilePictureUrl,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if user was previously invited (exists in non_registered_users collection)
      bool wasInvited =
          await TodoUnreadStatusService.wasUserPreviouslyInvited(email);

      if (wasInvited) {
        print('✅ User was previously invited: $email');
        // Clean up the non_registered_users entry since they're now registered
        await TodoUnreadStatusService.cleanupNonRegisteredUser(email);
      } else {
        print('📝 User was NOT previously invited: $email');
      }

      // Create user document with profile picture URL (if available)
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'profilePictureUrl': profilePictureUrl,
        'emailVerified': false,
        'isSubscribed': true, // Set to true for testing
        'todoUnreadStatus': wasInvited, // true if invited, false if not
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('📊 Set todoUnreadStatus = $wasInvited for new user: $email');

      return userCredential;
    } catch (e) {
      print('🔴 Error during sign up: $e');
      rethrow;
    }
  }

  Future<void> saveUserToPrefs(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = user.toMap();
      final userJson = json.encode(userData);
      print('🟢 Saving user data to SharedPreferences: $userJson');
      await prefs.setString(_userKey, userJson);
    } catch (e) {
      print('🔴 Error saving user to SharedPreferences: $e');
      throw Exception('Failed to save user data locally: ${e.toString()}');
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      // Check Firebase Auth current user
      final User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        print('🔴 No current Firebase user');
        return null;
      }

      // Reload user to get latest verification status
      await firebaseUser.reload();

      // Try to get user data from Firestore
      print('🟢 Fetching current user data from Firestore');
      final doc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (!doc.exists || doc.data() == null) {
        print('🔴 No Firestore document for current user');
        return null;
      }

      // Create UserModel from Firestore data
      final userData = doc.data()!;
      userData['uid'] = firebaseUser.uid; // Ensure UID is included
      userData['emailVerified'] =
          firebaseUser.emailVerified; // Get latest verification status

      // Update verification status in Firestore if needed
      if (firebaseUser.emailVerified != (userData['emailVerified'] ?? false)) {
        await updateEmailVerificationStatus(firebaseUser.emailVerified);
      }

      final userModel = UserModel.fromMap(userData);
      print('🟢 UserModel created from Firestore data');

      // Update SharedPreferences
      await saveUserToPrefs(userModel);
      print('🟢 Updated user data in SharedPreferences');

      return userModel;
    } catch (e) {
      print('🔴 Error in getCurrentUser: $e');
      return null;
    }
  }

  Future<UserModel?> getUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (userJson == null) {
        print('🔴 No user data found in SharedPreferences');
        return null;
      }

      final userData = json.decode(userJson) as Map<String, dynamic>;
      final userModel = UserModel.fromMap(userData);
      print('🟢 User data retrieved from SharedPreferences');
      return userModel;
    } catch (e) {
      print('🔴 Error getting user from SharedPreferences: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      print('🟢 Signing out user');

      // Clear FCM token before signing out
      if (_auth.currentUser != null) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({'fcmToken': ''});
        print('🟢 Cleared FCM token');
      }

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      print('🟢 Cleared user data from SharedPreferences');

      // Cancel all notifications
      NotificationService.cancelAllScheduledNotifications();

      // Sign out from Firebase
      await _auth.signOut();
      print('🟢 User signed out from Firebase successfully');
    } catch (e) {
      print('🔴 Error in signOut: $e');
      throw e;
    }
  }

  Future<String?> uploadProfilePicture(File image, String userId) async {
    try {
      final ref = _storage.ref().child('user_profiles').child('$userId.jpg');

      // Upload image
      await ref.putFile(image);

      // Get download URL
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('🔴 Error uploading profile picture: $e');
      return null;
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      print('🟢 Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
      print('🟢 Password reset email sent successfully');
    } catch (e) {
      print('🔴 Error sending password reset email: $e');
      throw _handleAuthException(e);
    }
  }

  Future<void> deleteAccount() async {
    try {
      print('🟢 Deleting user account');
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Delete user data from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();
      print('🟢 Deleted user data from Firestore');

      // Delete the user account
      await user.delete();
      print('🟢 Deleted user account from Firebase Auth');

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      print('🟢 Cleared user data from SharedPreferences');
    } catch (e) {
      print('🔴 Error in deleteAccount: $e');
      throw _handleAuthException(e);
    }
  }

  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account exists with this email. Please check your email or sign up.';
        case 'wrong-password':
          return 'Incorrect password. Please try again or use "Forgot Password".';
        case 'email-already-in-use':
          return 'An account already exists with this email. Please sign in instead.';
        case 'weak-password':
          return 'Password is too weak. Please use at least 6 characters with a mix of letters, numbers, and symbols.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support for help.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please wait a few minutes before trying again.';
        case 'operation-not-allowed':
          return 'This type of login is not enabled. Please contact support.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection and try again.';
        case 'requires-recent-login':
          return 'This operation is sensitive and requires recent authentication. Please log in again.';
        case 'invalid-credential':
          return 'The login credentials are invalid. Please try again.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with the same email but different sign-in credentials.';
        case 'invalid-verification-code':
          return 'Invalid verification code. Please try again.';
        case 'invalid-verification-id':
          return 'Invalid verification. Please try again.';
        case 'expired-action-code':
          return 'The verification code has expired. Please request a new one.';
        default:
          return 'Authentication error: ${e.message ?? e.code}';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  // Add this method to update email verification status
  Future<void> updateEmailVerificationStatus(bool isVerified) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      await _firestore.collection('users').doc(user.uid).update({
        'emailVerified': isVerified,
      });

      print('🟢 Updated email verification status to: $isVerified');
    } catch (e) {
      print('🔴 Error updating email verification status: $e');
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      // Search by name
      final nameResults = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(5)
          .get();

      // Search by email
      final emailResults = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(5)
          .get();

      // Combine and deduplicate results
      final Set<String> seenUids = {};
      final List<Map<String, dynamic>> results = [];

      for (var doc in nameResults.docs) {
        if (!seenUids.contains(doc.id)) {
          seenUids.add(doc.id);
          results.add({
            'uid': doc.id,
            'name': doc.data()['name'] ?? '',
            'email': doc.data()['email'] ?? '',
          });
        }
      }

      for (var doc in emailResults.docs) {
        if (!seenUids.contains(doc.id)) {
          seenUids.add(doc.id);
          results.add({
            'uid': doc.id,
            'name': doc.data()['name'] ?? '',
            'email': doc.data()['email'] ?? '',
          });
        }
      }

      return results;
    } catch (e) {
      throw Exception('Error searching users: $e');
    }
  }

  Future<bool> checkNotificationPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('🔴 Error checking notification permission: $e');
      return false;
    }
  }

  Future<String?> getCurrentUserName() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        return doc.data()?['name'] as String?;
      }
      return null;
    } catch (e) {
      throw Exception('Error getting user name: $e');
    }
  }
}