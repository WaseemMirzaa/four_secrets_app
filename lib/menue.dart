import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/models/drawer_model.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';
import '../config/theme/app_theme.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/snackbar_helper.dart';
import 'services/menu_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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

  // Helper: get the notification stream for unread invitations or comments
  Stream<bool> get _hasNewCollabNotificationStream async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('[Menu Notification Debug] No user logged in.');
      yield false;
      return;
    }
    final fcmToken = await FirebaseMessaging.instance.getToken();
    final userEmail = user.email;
    print(
        '[Menu Notification Debug] Current FCM token: $fcmToken, email: $userEmail');
    if (fcmToken == null && userEmail == null) {
      print('[Menu Notification Debug] No FCM token or email.');
      yield false;
      return;
    }
    yield* FirebaseFirestore.instance
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      print(
          '[Menu Notification Debug] Checking ${snapshot.docs.length} notification docs...');
      final matches = snapshot.docs.where((doc) {
        final data = doc.data();
        print('[Menu Notification Debug] Notification doc: ' + data.toString());
        final type = data['data']?['type'] ?? '';
        final tokenMatch = fcmToken != null && data['token'] == fcmToken;
        final emailMatch = userEmail != null &&
            (data['toEmail'] == userEmail ||
                data['data']?['toEmail'] == userEmail);
        final result = (type == 'invitation' || type == 'comment') &&
            (tokenMatch || emailMatch);
        print(
            '[Menu Notification Debug] type: $type, tokenMatch: $tokenMatch, emailMatch: $emailMatch, result: $result, doc: ${doc.id}');
        return result;
      }).toList();
      print(
          '[Menu Notification Debug] Matched notifications count: \'${matches.length}\'');
      return matches.isNotEmpty;
    });
  }

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

  // // Mark all collaboration notifications as read (now: delete them)
  // Future<void> _markAllCollabNotificationsAsRead() async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user == null) return;
  //   final fcmToken = await FirebaseMessaging.instance.getToken();
  //   final userEmail = user.email;
  //   if (fcmToken == null && userEmail == null) return;
  //   final snapshot = await FirebaseFirestore.instance
  //       .collection('notifications')
  //       .where('read', isEqualTo: false)
  //       .get();
  //   for (final doc in snapshot.docs) {
  //     final data = doc.data();
  //     final type = data['data']?['type'] ?? '';
  //     final tokenMatch = fcmToken != null && data['token'] == fcmToken;
  //     final emailMatch = userEmail != null &&
  //         (data['toEmail'] == userEmail ||
  //             data['data']?['toEmail'] == userEmail);
  //     if ((type == 'invitation' || type == 'comment') &&
  //         (tokenMatch || emailMatch)) {
  //       await doc.reference.delete();
  //     }
  //   }
  // }

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
                              // _markAllCollabNotificationsAsRead();
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
                      if (e.name == 'Hochzeitskit' && hasNewCollabNotification)
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
                    ],
                  ),
                );
              }),

              const Divider(
                color: Colors.grey,
                thickness: 0.5,
                indent: 8,
                endIndent: 8,
              ),
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
