import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/snackbar_helper.dart';
import 'services/menu_service.dart';

export 'menue.dart' show MenueState;

class Menue extends StatefulWidget {
  const Menue({Key? key}) : super(key: key);

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

  @override
  void initState() {
    super.initState();

    // Check if data is already loaded in the service
    final menuService = MenuService();
    if (menuService.isDataLoaded) {
      _userName = menuService.userName;
      _profilePictureUrl = menuService.profilePictureUrl;
      _isLoading = false;
    } else {
      _loadUserData();
    }
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

  bool isPressedBtn0 = false; // Home
  bool isPressedBtn1 = false; // Profil bearbeiten
  bool isPressedBtn2 = false; // Inspirationen
  bool isPressedBtn3 = false; // Budget
  bool isPressedBtn4 = false; // Checkliste
  bool isPressedBtn5 = false; // Gästeliste
  bool isPressedBtn6 = false; // Tischverwaltung
  bool isPressedBtn7 = false; // Showroom
  bool isPressedBtn8 = false; // About me
  bool isPressedBtn9 = false; // Kontakt
  bool isPressedBtn10 = false; // KI-Assistent (Chatbot)
  bool isPressedBtn11 = false; // Impressum
  bool isPressedBtn12 = false; // Logout

  void buttonIsPressed(int buttonNumber) {
    setState(() {
      isPressedBtn0 = buttonNumber == 0;
      isPressedBtn1 = buttonNumber == 1;
      isPressedBtn2 = buttonNumber == 2;
      isPressedBtn3 = buttonNumber == 3;
      isPressedBtn4 = buttonNumber == 4;
      isPressedBtn5 = buttonNumber == 5;
      isPressedBtn6 = buttonNumber == 6;
      isPressedBtn7 = buttonNumber == 7;
      isPressedBtn8 = buttonNumber == 8;
      isPressedBtn9 = buttonNumber == 9;
      isPressedBtn10 = buttonNumber == 10;
      isPressedBtn11 = buttonNumber == 11;
      isPressedBtn12 = buttonNumber == 12;
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await _authService.signOut();
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

  @override
  Widget build(BuildContext context) {
    // Set status bar color to black
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
    ));

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
                  if (!_isLoading)
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
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
                                  // loadingBuilder:
                                  //     (context, child, loadingProgress) {
                                  //   if (loadingProgress == null) {
                                  //     return child;
                                  //   }
                                  //   return Center(
                                  //     child: CircularProgressIndicator(
                                  //       color: const Color.fromARGB(
                                  //           255, 107, 69, 106),
                                  //       value: loadingProgress
                                  //                   .expectedTotalBytes !=
                                  //               null
                                  //           ? loadingProgress
                                  //                   .cumulativeBytesLoaded /
                                  //               loadingProgress
                                  //                   .expectedTotalBytes!
                                  //           : null,
                                  //     ),
                                  //   );
                                  // },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 100,
                                      height: 100,
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
          // 1. Home
          Card(
            margin: const EdgeInsets.only(left: 8, right: 8, top: 5, bottom: 0),
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
              tileColor: isPressedBtn0 ? Colors.purple[50] : Colors.white,
              leading: const Icon(Icons.home),
              title: const Text(
                'Home',
                style: TextStyle(fontSize: 18),
              ),
              onTap: () {
                buttonIsPressed(0);
                Timer(
                  const Duration(milliseconds: 100),
                  () {
                    Navigator.of(context).pushNamed(RouteManager.homePage);
                  },
                );
              },
            ),
          ),
          // 2. Muenchner Geheimtipp
          Card(
            margin: const EdgeInsets.only(left: 8, right: 8, top: 5, bottom: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
              tileColor: isPressedBtn2 ? Colors.purple[50] : Colors.white,
              leading: const Icon(Icons.auto_stories),
              title: const Text(
                'Münchner Geheimtipp',
                style: TextStyle(fontSize: 18),
              ),
              onTap: () {
                buttonIsPressed(2);
                Timer(
                  const Duration(milliseconds: 100),
                  () {
                    Navigator.of(context)
                        .pushNamed(RouteManager.muenchnerGeheimtippPage);
                  },
                );
              },
            ),
          ),
          // 3. Checkliste
          Card(
            margin: const EdgeInsets.only(left: 8, right: 8, top: 5, bottom: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
              tileColor: isPressedBtn4 ? Colors.purple[50] : Colors.white,
              leading: const Icon(Icons.checklist),
              title: const Text(
                'Checkliste',
                style: TextStyle(fontSize: 18),
              ),
              onTap: () {
                buttonIsPressed(4);
                Timer(
                  const Duration(milliseconds: 100),
                  () {
                    Navigator.of(context).pushNamed(RouteManager.checklistPage);
                  },
                );
              },
            ),
          ),
          // 4. Budget
          Card(
            margin: const EdgeInsets.only(left: 8, right: 8, top: 5, bottom: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
              tileColor: isPressedBtn3 ? Colors.purple[50] : Colors.white,
              leading: const Icon(Icons.euro_rounded),
              title: const Text(
                'Budget',
                style: TextStyle(fontSize: 18),
              ),
              onTap: () {
                buttonIsPressed(3);
                Timer(
                  const Duration(milliseconds: 100),
                  () {
                    Navigator.of(context).pushNamed(RouteManager.budgetPage);
                  },
                );
              },
            ),
          ),
          // 5. Gästeliste
          Card(
            margin: const EdgeInsets.only(left: 8, right: 8, top: 5, bottom: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
              tileColor: isPressedBtn5 ? Colors.purple[50] : Colors.white,
              leading: const Icon(Icons.group),
              title: const Text(
                'Gästeliste',
                style: TextStyle(fontSize: 18),
              ),
              onTap: () {
                buttonIsPressed(5);
                Timer(
                  const Duration(milliseconds: 100),
                  () {
                    Navigator.of(context)
                        .pushNamed(RouteManager.gaestelistPage);
                  },
                );
              },
            ),
          ),
          // 6. Tischverwaltung
          Card(
            margin: const EdgeInsets.only(left: 8, right: 8, top: 5, bottom: 0),
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
              tileColor: isPressedBtn6 ? Colors.purple[50] : Colors.white,
              leading: const Icon(Icons.table_bar),
              title: const Text('Tischverwaltung'),
              onTap: () {
                buttonIsPressed(6);
                Timer(
                  const Duration(milliseconds: 100),
                  () {
                    Navigator.of(context)
                        .pushNamed(RouteManager.tablesManagementPage);
                  },
                );
              },
            ),
          ),
          // 7. Showroom
          Card(
            margin: const EdgeInsets.only(left: 8, right: 8, top: 5, bottom: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
              tileColor: isPressedBtn7 ? Colors.purple[50] : Colors.white,
              leading: const Icon(Icons.celebration),
              title: const Text(
                'Showroom-Event',
                style: TextStyle(fontSize: 18),
              ),
              onTap: () {
                buttonIsPressed(7);
                Timer(
                  const Duration(milliseconds: 100),
                  () {
                    Navigator.of(context)
                        .pushNamed(RouteManager.showroomEventPage);
                  },
                );
              },
            ),
          ),
          // 8. About me
          Card(
            margin: const EdgeInsets.only(left: 8, right: 8, top: 5, bottom: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
              tileColor: isPressedBtn8 ? Colors.purple[50] : Colors.white,
              leading: const Icon(
                Icons.account_box_sharp,
              ),
              title: const Text(
                'About me',
                style: TextStyle(fontSize: 18),
              ),
              onTap: () {
                buttonIsPressed(8);
                Timer(
                  const Duration(milliseconds: 100),
                  () {
                    Navigator.of(context).pushNamed(RouteManager.aboutMePage);
                  },
                );
              },
            ),
          ),
          // 9. Kontakt
          Card(
            margin: const EdgeInsets.only(left: 8, right: 8, top: 5, bottom: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
              tileColor: isPressedBtn9 ? Colors.purple[50] : Colors.white,
              leading: Icon(FontAwesomeIcons.mapLocationDot),
              title: const Text(
                'Kontakt',
                style: TextStyle(fontSize: 18),
              ),
              onTap: () {
                buttonIsPressed(9);
                Timer(
                  const Duration(milliseconds: 100),
                  () {
                    Navigator.of(context).pushNamed(RouteManager.kontakt);
                  },
                );
              },
            ),
          ),
          // 9. KI-Assistent (Chatbot)
          Card(
            margin: const EdgeInsets.only(left: 8, right: 8, top: 5, bottom: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
              tileColor: isPressedBtn10 ? Colors.purple[50] : Colors.white,
              leading: Icon(FontAwesomeIcons.mapLocationDot),
              title: const Text(
                'KI-Assistent',
                style: TextStyle(fontSize: 18),
              ),
              onTap: () {
                buttonIsPressed(9);
                Timer(
                  const Duration(milliseconds: 100),
                  () {
                    Navigator.of(context).pushNamed(RouteManager.chatbotPage);
                  },
                );
              },
            ),
          ),
          // 10. Impressum und Datenschutz
          Card(
            margin: const EdgeInsets.only(left: 8, right: 8, top: 5, bottom: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
              tileColor: isPressedBtn10 ? Colors.purple[50] : Colors.white,
              leading: Icon(
                FontAwesomeIcons.circleInfo,
              ),
              title: const Text(
                'Impressum und Datenschutz',
                style: TextStyle(fontSize: 18),
              ),
              onTap: () {
                buttonIsPressed(10);
                Timer(
                  const Duration(milliseconds: 100),
                  () {
                    Navigator.of(context).pushNamed(RouteManager.impressum);
                  },
                );
              },
            ),
          ),
          // 11. Profil bearbeiten
          Card(
            margin: const EdgeInsets.only(left: 8, right: 8, top: 5, bottom: 0),
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
              tileColor: isPressedBtn1 ? Colors.purple[50] : Colors.white,
              leading: const Icon(
                Icons.person,
              ),
              title: const Text(
                'Profil bearbeiten',
                style: TextStyle(fontSize: 18),
              ),
              onTap: () {
                buttonIsPressed(1);
                Timer(
                  const Duration(milliseconds: 100),
                  () => _navigateToEditProfile(),
                );
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
            margin: const EdgeInsets.only(left: 8, right: 8, top: 5, bottom: 8),
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
              tileColor: isPressedBtn12 ? Colors.purple[50] : Colors.white,
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                ),
              ),
              onTap: () {
                buttonIsPressed(11);
                Timer(
                  const Duration(milliseconds: 100),
                  () => _handleLogout(context),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
