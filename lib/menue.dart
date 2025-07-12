import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:four_secrets_wedding_app/models/drawer_model.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/services/auth_service.dart';
import 'package:four_secrets_wedding_app/services/push_notification_service.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';

import 'services/menu_service.dart';
import 'utils/snackbar_helper.dart';

export 'menue.dart' show MenueState;

class Menue extends StatefulWidget {
  Menue({Key? key}) : super(key: key);

  // Static method to get the singleton menu instance
  static Widget getInstance(Key keyWidget) {
    return MenuService().getMenu(keyWidget);
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

  // Use shared notification stream from PushNotificationService
  Stream<bool> get _hasNewCollabNotificationStream => PushNotificationService.hasNewCollabNotificationStream;

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

  // Optimized navigation method to eliminate Timer delays
  void _navigateTo(String routeName) {
    if (!mounted) return;
    Navigator.of(context).pushNamed(routeName);
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await _authService.signOut();
      MenuService().selectedItem = null;
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          RouteManager.signinPage,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
            context, 'Logout failed: ${e.toString()}');
      }
    }
  }

  Future<void> _navigateToEditProfile() async {
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

  // Helper method to capitalize the first letter of a string
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Mark all collaboration notifications as read
  // Use shared notification service method
  Future<void> _markAllCollabNotificationsAsRead() async {
    await PushNotificationService.markAllCollabNotificationsAsRead();
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
          print('[Menu Debug] Marked non-invitation/comment notification as read: ${doc.id} (type: $type)');
        }
      }
    } catch (e) {
      print('[Menu Debug] Error clearing invalid notifications: $e');
    }
  }

  // Test method to create a test notification (for debugging)
  Future<void> _createTestNotification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final fcmToken = await FirebaseMessaging.instance.getToken();
      final userEmail = user.email;
      if (fcmToken == null || userEmail == null) return;
      
      await FirebaseFirestore.instance.collection('notifications').add({
        'token': fcmToken,
        'toEmail': userEmail,
        'title': 'Test Einladung',
        'body': 'Dies ist eine Test-Einladung',
        'data': {'type': 'invitation', 'toEmail': userEmail},
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
      print('[Menu Debug] Created test notification');
    } catch (e) {
      print('[Menu Debug] Error creating test notification: $e');
    }
  }


 

 


  @override
  Widget build(BuildContext context) {
    // Set status bar color to black
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
    ));

    return StreamBuilder<bool>(
      stream: _hasNewCollabNotificationStream,
      initialData: false,
      builder: (context, snapshot) {
        print('StreamBuilder notification snapshot.data: \'${snapshot.data}\'');
        final hasNewCollabNotification = snapshot.data ?? false;
        print('[Menu Debug] Red dot should show: $hasNewCollabNotification');
        
        // Additional debug info
        if (hasNewCollabNotification) {
          print('[Menu Debug] ⚠️ RED DOT IS SHOWING - This means there are matching notifications');
          // Don't call _testStream() here as it might cause infinite loops
          // Instead, just log the issue
        } else {
          print('[Menu Debug] ✅ Red dot is NOT showing - No matching notifications');
        }
        return Drawer(
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
                            ))
                          : CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.white,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: (_profilePictureUrl != null &&
                                          _profilePictureUrl!.isNotEmpty
                                      ? Image.network(
                                          _profilePictureUrl!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Center(
                                              child: CircularProgressIndicator(
                                                color: const Color.fromARGB(
                                                    255, 107, 69, 106),
                                                value: loadingProgress
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

              ...listDrawerModel.map((e) {
                bool isSelected = _pressedStates[e.name]!;
                return Card(
                  margin: const EdgeInsets.only(
                      left: 8, right: 8, top: 5, bottom: 0),
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
                        tileColor:
                            isSelected ? Colors.purple[50] : Colors.white,
                        leading: Icon(e.icon),
                        title: CustomTextWidget(
                          text: e.name,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        onTap: () {
                          _select(e.name);

                          // Optimized navigation without Timer delays
                          switch (e.name) {
                            case "Home":
                              _navigateTo(RouteManager.homePage);
                              break;
                            case "Münchner Geheimtipp":
                              _navigateTo(RouteManager.inspirationsPage);
                              break;
                            case "Checkliste":
                              _navigateTo(RouteManager.checklistPage);
                              break;
                            case "Budget":
                              _navigateTo(RouteManager.budgetPage);
                              break;
                            case "Gästeliste":
                              _navigateTo(RouteManager.gaestelistPage);
                              break;
                            case "Tischverwaltung":
                              _navigateTo(RouteManager.tablesManagementPage);
                              break;
                            case "Showroom":
                              _navigateTo(RouteManager.showroomEventPage);
                              break;
                            case "Über mich":
                              _navigateTo(RouteManager.aboutMePage);
                              break;
                            case "Kontakt":
                              _navigateTo(RouteManager.kontakt);
                              break;
                            case "Mitgestalter":
                              _navigateTo(RouteManager.collaborationPage);
                              break;
                            case "Impressum":
                              _navigateTo(RouteManager.impressum);
                              break;
                            case "Hochzeitskit":
                              // Don't mark notifications as read automatically
                              // Only mark as read when user actually clicks the collaboration icon
                              _navigateTo(RouteManager.toDoPage);
                              break;
                            case "Inspirationen":
                              _navigateTo(RouteManager.inspirationFolderPage);
                              break;
                            case "Tagesablauf":
                              _navigateTo(RouteManager.weddingSchedulePage);
                              break;
                          }
                        },
                      ),
                      // Show the red dot only for 'Hochzeitskit'
                      if (e.name == 'Hochzeitskit' && hasNewCollabNotification) ...[
                        Positioned(
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
                        ),
                        // Debug print when red dot is shown
                        Builder(
                          builder: (context) {
                            print('[Menu Debug] Red dot is visible for Hochzeitskit');
                            return SizedBox.shrink();
                          },
                        ),
                      ],
                    ],
                  ),
                );
              }),

             
            
              // 12. Profil bearbeiten
              Card(
                margin:
                    const EdgeInsets.only(left: 8, right: 8, top: 5, bottom: 0),
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
                  leading: const Icon(
                    Icons.person,
                  ),
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
              // 12. Log Out
              Card(
                margin:
                    const EdgeInsets.only(left: 8, right: 8, top: 5, bottom: 8),
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
                  leading: const Icon(
                    Icons.logout,
                    color: Colors.red,
                  ),
                  title: CustomTextWidget(
                    text: 'Logout',
                    fontSize: 16,
                    color: Colors.red,
                  ),
                  onTap: () {
                    _select('Logout');
                    _handleLogout(context);
                  },
                ),
              ),
              const SpacerWidget(height: 10),
            ],
          ),
        );
      },
    );
  }
}
