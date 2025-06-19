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

  void _select(String name) {
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
  bool isPressedBtn10 = false; // Impressum
  bool isPressedBtn11 = false; // inspiration
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
                              color: Colors.black.withValues(alpha: 0.2),
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

          ...listDrawerModel.map((e) {
            bool isSelected = _pressedStates[e.name]!;

            return Card(
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
                tileColor: isSelected ? Colors.purple[50] : Colors.white,
                leading: Icon(e.icon),
                title: CustomTextWidget(
                  text: e.name,
                  fontSize: 16,
                  color: Colors.black,
                ),
                onTap: () {
                  _select(e.name);

                  if (e.name == "Home") {
                    Timer(
                      const Duration(milliseconds: 100),
                      () {
                        Navigator.of(context).pushNamed(RouteManager.homePage);
                      },
                    );
                  } else if (e.name == "Inspirationen") {
                    Timer(
                      const Duration(milliseconds: 100),
                      () {
                        Navigator.of(context)
                            .pushNamed(RouteManager.inspirationsPage);
                      },
                    );
                  } else if (e.name == "Checkliste") {
                    Timer(
                      const Duration(milliseconds: 100),
                      () {
                        Navigator.of(context)
                            .pushNamed(RouteManager.checklistPage);
                      },
                    );
                  } else if (e.name == "Budget") {
                    Timer(
                      const Duration(milliseconds: 100),
                      () {
                        Navigator.of(context)
                            .pushNamed(RouteManager.budgetPage);
                      },
                    );
                  } else if (e.name == "Gästeliste") {
                    Timer(
                      const Duration(milliseconds: 100),
                      () {
                        Navigator.of(context)
                            .pushNamed(RouteManager.gaestelistPage);
                      },
                    );
                  } else if (e.name == "Tischverwaltung") {
                    Timer(
                      const Duration(milliseconds: 100),
                      () {
                        Navigator.of(context)
                            .pushNamed(RouteManager.tablesManagementPage);
                      },
                    );
                  } else if (e.name == "Showroom") {
                    Timer(
                      const Duration(milliseconds: 100),
                      () {
                        Navigator.of(context)
                            .pushNamed(RouteManager.showroomEventPage);
                      },
                    );
                  } else if (e.name == "Über mich") {
                    Timer(
                      const Duration(milliseconds: 100),
                      () {
                        Navigator.of(context)
                            .pushNamed(RouteManager.aboutMePage);
                      },
                    );
                  } else if (e.name == "Kontakt") {
                    Timer(
                      const Duration(milliseconds: 100),
                      () {
                        Navigator.of(context).pushNamed(RouteManager.kontakt);
                      },
                    );
                  } else if (e.name == "Zusammenarbeit") {
                    Timer(
                      const Duration(milliseconds: 100),
                      () {
                        Navigator.of(context)
                            .pushNamed(RouteManager.collaborationPage);
                      },
                    );
                  } else if (e.name == "Impressum") {
                    Timer(
                      const Duration(milliseconds: 100),
                      () {
                        Navigator.of(context).pushNamed(RouteManager.impressum);
                      },
                    );
                  } else if (e.name == "Hochzeitskit") {
                    Timer(
                      const Duration(milliseconds: 100),
                      () {
                        Navigator.of(context).pushNamed(RouteManager.toDoPage);
                      },
                    );
                  } else if (e.name == "Inspirationsordner") {
                    Timer(
                      const Duration(milliseconds: 100),
                      () {
                        Navigator.of(context)
                            .pushNamed(RouteManager.inspirationFolderPage);
                      },
                    );
                  } else if (e.name == "Tagesablauf") {
                    Timer(
                      const Duration(milliseconds: 100),
                      () {
                        Navigator.of(context)
                            .pushNamed(RouteManager.weddingSchedulePage);
                      },
                    );
                  }
                },
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
              tileColor:
                  _pressedStates['Logout']! ? Colors.purple[50] : Colors.white,
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

                Timer(
                  const Duration(milliseconds: 100),
                  () => _handleLogout(context),
                );
              },
            ),
          ),
          const SpacerWidget(height: 10),
        ],
      ),
    );
  }
}
