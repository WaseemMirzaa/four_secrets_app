import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:four_secrets_wedding_app/models/drawer_model.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/services/auth_service.dart';
import 'package:four_secrets_wedding_app/services/email_service.dart';
import 'package:four_secrets_wedding_app/services/push_notification_service.dart';
import 'package:four_secrets_wedding_app/services/subscription/subscription_manager.dart';
import 'package:four_secrets_wedding_app/services/todo_unread_status_service.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';

import 'services/menu_service.dart';
import 'utils/snackbar_helper.dart';

export 'menue.dart' show MenueState;

class Menue extends StatefulWidget {
  Menue({Key? key}) : super(key: key);

  // Static method to get the singleton menu instance
  static Widget getInstance() {
    return MenuService().getMenu();
  }

  // Static method to preload user data
  static Future<void> preloadUserData() async {
    await MenuService().preloadUserData();
  }

  // Static method to refresh user data
  static Future<void> refreshUserData() async {
    await MenuService().refreshUserData();
  }

  @override
  State<Menue> createState() => MenueState();
}

class MenueState extends State<Menue> {
  final AuthService _authService = AuthService();
  String? _userName;
  String? _profilePictureUrl;
  bool _isLoading = true;
  // Initialize later in initState()
  late Map<String, bool> _pressedStates;
  String? currentSelected;

  Set<String> premiumFeatures = {
    "Eigene Dienstleister",
    "Budget",
    "Gästeliste",
    "Tischverwaltung",
    "Tagesablauf",
    "Inspirationen",
    "Hochzeitskit",
    "Mitgestalter",
    "KI-Assistent",
    "Abonnement",
  };

  /// Features that are free but should NOT show "Gratis"
  Set<String> hideGratisLabel = {"Home", "Profile bearbeiten"};

  // Use shared notification stream from PushNotificationService
  Stream<bool> get _hasNewCollabNotificationStream =>
      PushNotificationService.hasNewCollabNotificationStream;

  // Use todoUnreadStatus stream from TodoUnreadStatusService
  Stream<bool> get _todoUnreadStatusStream =>
      TodoUnreadStatusService.getCurrentUserUnreadStatusStream();

  @override
  void initState() {
    super.initState();

    // Check if data is already loaded in the service
    final menuService = MenuService();
    _pressedStates = {
      for (var item in listDrawerModel) item.name: false,
      'Profil bearbeiten': false,
      'Logout': false,
    };
    _loadUserData();

    // Load saved selection from MenuService or default to Home
    currentSelected = menuService.selectedItem ?? listDrawerModel[0].name;
    _pressedStates[currentSelected!] = true;

    if (menuService.isDataLoaded) {
      _userName = menuService.userName;
      _profilePictureUrl = menuService.profilePictureUrl;
      _isLoading = false;
    } else {
      _loadUserData();
    }

    // Clear any invalid notifications on app start
    _clearInvalidNotifications();

    // Force check notifications on startup
    Future.delayed(Duration(seconds: 2), () {
      // Also try to clear any invalid notifications
      _clearInvalidNotifications();
    });
    // Refresh subscription status when menu is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SubscriptionManager().checkSubscriptionStatus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _select(String name) {
    if (!mounted) return;
    setState(() {
      _pressedStates.updateAll((_, __) => false);
      _pressedStates[name] = true;
      currentSelected = name;
      if (name != 'Logout') {
        MenuService().selectedItem = name; // Save only non-logout selections
      }
    });
  }

  // Method to update user data from outside
  void updateUserData(String? userName, String? profilePictureUrl) {
    if (mounted) {
      setState(() {
        _userName = userName;
        _profilePictureUrl = profilePictureUrl;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (mounted) {
          setState(() {
            _userName = _capitalizeFirstLetter(userData.data()?['name']);
            _profilePictureUrl = userData.data()?['profilePictureUrl'];
            _isLoading = false;

            // Update the service with the loaded data
            final menuService = MenuService();
            menuService.userName = _userName;
            menuService.profilePictureUrl = _profilePictureUrl;
            menuService.isDataLoaded = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Add this method to your MenueState class
  Future<void> _handleNavigation(String itemName) async {
    // Define which menu items require active subscription

    final isPremiumFeature = premiumFeatures.contains(itemName);

    final hasSubscription = SubscriptionManager().hasActiveSubscription;

    if (isPremiumFeature && !hasSubscription) {
      Navigator.of(context).pushNamed(RouteManager.subscriptionPreviewScreen);
    } else {
      // Proceed with normal navigation
      _select(itemName);
      _navigateTo(_getRouteForItem(itemName));
    }
  }

  // Add this helper method to get route for menu item
  String _getRouteForItem(String itemName) {
    switch (itemName) {
      case "Home":
        return RouteManager.homePage;
      case "Münchner Geheimtipp":
        return RouteManager.muenchnerGeheimtippPage;
      case "Budget":
        return RouteManager.budgetPage;
      case "Checkliste":
        return RouteManager.checklistPage;
      case "Gästeliste":
        return RouteManager.gaestelistPage;
      case "Tischverwaltung":
        return RouteManager.tablesManagementPage;
      case "Showroom":
        return RouteManager.showroomEventPage;
      case "Über mich":
        return RouteManager.aboutMePage;
      case "Kontakt":
        return RouteManager.kontakt;
      case "KI-Assistent":
        return RouteManager.chatbotPage;
      case "Mitgestalter":
        return RouteManager.collaborationPage;
      case "Impressum":
        return RouteManager.impressum;
      case "Hochzeitskit":
        return RouteManager.toDoPage;
      case "Inspirationen":
        return RouteManager.inspirationFolderPage;
      case "Tagesablauf":
        return RouteManager.weddingSchedulePage;
      case "Abonnement":
        return RouteManager.subscriptionManagementScreen;
      case "Eigene Dienstleister":
        return RouteManager.weddingSchedulePage1;
      default:
        return RouteManager.homePage;
    }
  }

  // Optimized navigation method to eliminate Timer delays
  void _navigateTo(String routeName) {
    if (!mounted) return;
    // Close the drawer first
    Navigator.of(context).pop();
    // Then navigate to the new screen
    Navigator.of(context).pushNamed(routeName);
  }

  Future<void> _navigateToEditProfile() async {
    // Close the drawer first
    Navigator.of(context).pop();

    final result = await Navigator.pushNamed(
      context,
      RouteManager.editProfilePage,
      arguments: {
        'currentName': _userName,
        'currentProfilePicUrl': _profilePictureUrl,
      },
    );

    if (result == true) {
      // Reload user data after successful update
      await _loadUserData();
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      // 3. Sign out
      await _authService.signOut();
      MenuService().selectedItem = null;

      // 4. Clear all routes and go to login
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(RouteManager.signinPage, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          'Logout failed: ${e.toString()}',
        );
      }
    }
  }

  // Helper method to capitalize the first letter of a string
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Clear any invalid notifications that might cause the red dot to appear
  Future<void> _clearInvalidNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final fcmToken = await FirebaseMessaging.instance.getToken();
      final userEmail = user.email;
      if (fcmToken == null && userEmail == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      print('[Menu Debug] Clearing invalid notifications...');
      for (final doc in snapshot.docs) {
        final data = doc.data();
        // Check if notification is invalid (missing required fields)
        if (data['title'] == null ||
            data['body'] == null ||
            data['title'].toString().isEmpty ||
            data['body'].toString().isEmpty ||
            data['token'] == null ||
            data['token'].toString().isEmpty) {
          // Mark invalid notifications as read to prevent red dot
          await doc.reference.update({'read': true});
          print('[Menu Debug] Marked invalid notification as read: ${doc.id}');
        }

        // Also check if notification type is not invitation or comment
        final type = data['data']?['type'] ?? '';
        if (type != 'invitation' && type != 'comment') {
          await doc.reference.update({'read': true});
          print(
            '[Menu Debug] Marked non-invitation/comment notification as read: ${doc.id} (type: $type)',
          );
        }
      }
    } catch (e) {
      print('[Menu Debug] Error clearing invalid notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveSubscription = SubscriptionManager().hasActiveSubscription;

    // Set status bar for drawer - Huawei compatible
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return StreamBuilder<bool>(
      stream: _hasNewCollabNotificationStream,
      initialData: false,
      builder: (context, snapshot) {
        print('StreamBuilder notification snapshot.data: \'${snapshot.data}\'');
        final hasNewCollabNotification = snapshot.data ?? false;
        print('[Menu Debug] Red dot should show: $hasNewCollabNotification');

        // Additional debug info
        if (hasNewCollabNotification) {
          print(
            '[Menu Debug] ⚠️ RED DOT IS SHOWING - This means there are matching notifications',
          );
        } else {
          print(
            '[Menu Debug] ✅ Red dot is NOT showing - No matching notifications',
          );
        }

        return SafeArea(
          child: Drawer(
            width: 225,
            backgroundColor: Colors.white70,
            child: ListView(
              children: [
                SizedBox(
                  height: 180,
                  child: DrawerHeader(
                    padding: const EdgeInsets.all(16.0),
                    margin: const EdgeInsets.all(0.0),
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 107, 69, 106),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : CircleAvatar(
                                radius: 55,
                                backgroundColor: Colors.white,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        spreadRadius: 1,
                                        blurRadius: 3,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child:
                                        (_profilePictureUrl != null &&
                                            _profilePictureUrl!.isNotEmpty
                                        ? Image.network(
                                            _profilePictureUrl!,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  color: const Color.fromARGB(
                                                    255,
                                                    107,
                                                    69,
                                                    106,
                                                  ),
                                                  value:
                                                      loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    width: 100,
                                                    height: 100,
                                                    child: Image.asset(
                                                      'assets/images/logo/secrets-logo.jpg',
                                                      width: 100,
                                                      height: 100,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  );
                                                },
                                          )
                                        : Image.asset(
                                            'assets/images/logo/secrets-logo.jpg',
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          )),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            _isLoading ? '' : (_userName ?? ''),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Dynamic menu items from listDrawerModel
                ...listDrawerModel.map((e) {
                  bool isSelected = _pressedStates[e.name]!;
                  return Card(
                    margin: const EdgeInsets.only(
                      left: 8,
                      right: 8,
                      top: 5,
                      bottom: 0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 0,
                          ),
                          tileColor: isSelected
                              ? Colors.purple[50]
                              : Colors.white,
                          leading: e.customIconPath != null
                              ? Image.asset(
                                  e.customIconPath!,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.contain,
                                )
                              : Icon(e.icon),
                          title: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                child: CustomTextWidget(
                                  text: e.name,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),

                              // Show "Gratis" ONLY when:
                              // 1) User does NOT have active subscription
                              // 2) Feature is NOT premium
                              // 3) Feature is NOT in hideGratisLabel (e.g. Home)
                              if (!hasActiveSubscription &&
                                  !premiumFeatures.contains(e.name) &&
                                  !hideGratisLabel.contains(e.name)) ...[
                                const SizedBox(width: 6),
                                Text(
                                  'Gratis',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.normal,
                                    decorationThickness: 2,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          onTap: () {
                            _handleNavigation(e.name);
                          },
                        ),
                        // Show red dot for 'Hochzeitskit' and 'Mitgestalter' based on todoUnreadStatus
                        if (e.name == 'Hochzeitskit' ||
                            e.name == 'Mitgestalter')
                          StreamBuilder<bool>(
                            stream: _todoUnreadStatusStream,
                            initialData: false,
                            builder: (context, snapshot) {
                              final hasUnreadTodos = snapshot.data ?? false;
                              if (hasUnreadTodos) {
                                print(
                                  '[Menu Debug] Red dot showing for ${e.name} - todoUnreadStatus: true',
                                );
                                return Positioned(
                                  right: 16,
                                  top: 12,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                );
                              } else {
                                print(
                                  '[Menu Debug] No red dot for ${e.name} - todoUnreadStatus: false',
                                );
                                return SizedBox.shrink();
                              }
                            },
                          ),
                      ],
                    ),
                  );
                }),

                // Profil bearbeiten
                Card(
                  margin: const EdgeInsets.only(
                    left: 8,
                    right: 8,
                    top: 5,
                    bottom: 0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
                    tileColor: _pressedStates['Profil bearbeiten']!
                        ? Colors.purple[50]
                        : Colors.white,
                    leading: const Icon(Icons.person),
                    title: CustomTextWidget(
                      text: 'Profil bearbeiten',
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    onTap: () {
                      _select('Profil bearbeiten');
                      _navigateToEditProfile();
                    },
                  ),
                ),

                const Divider(
                  color: Colors.grey,
                  thickness: 0.5,
                  indent: 8,
                  endIndent: 8,
                ),

                // Log Out
                Card(
                  margin: const EdgeInsets.only(
                    left: 8,
                    right: 8,
                    top: 5,
                    bottom: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
                    tileColor: _pressedStates['Logout']!
                        ? Colors.purple[50]
                        : Colors.white,
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: CustomTextWidget(
                      text: 'Logout',
                      fontSize: 16,
                      color: Colors.red,
                    ),
                    onTap: () {
                      _handleLogout(context);
                    },
                  ),
                ),

                // // // Log Out
                // Card(
                //   margin: const EdgeInsets.only(
                //     left: 8,
                //     right: 8,
                //     top: 5,
                //     bottom: 8,
                //   ),
                //   shape: RoundedRectangleBorder(
                //     borderRadius: BorderRadius.circular(8),
                //   ),
                //   child: ListTile(
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //     contentPadding: const EdgeInsets.symmetric(
                //       horizontal: 10,
                //       vertical: 0,
                //     ),

                //     leading: const Icon(Icons.send, color: Colors.red),
                //     title: CustomTextWidget(
                //       text: 'send test email',
                //       fontSize: 16,
                //       color: Colors.red,
                //     ),
                //     onTap: () {
                //       final EmailService service = EmailService();
                //       service.sendEmail(
                //         email: "mughalfahad544@gmail.com",
                //         subject: "Helo this is test email",
                //         message: "How are you",
                //       );
                //     },
                //   ),
                // ),
                const SpacerWidget(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
