import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:four_secrets_wedding_app/models/user_model.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/services/auth_service.dart';
import 'package:four_secrets_wedding_app/services/image_upload_service.dart';
import 'package:four_secrets_wedding_app/widgets/custom_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../utils/snackbar_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfilePage extends StatefulWidget {
  final String currentName;
  final String? currentProfilePicUrl;

  const EditProfilePage({
    super.key,
    required this.currentName,
    this.currentProfilePicUrl,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final key = GlobalKey<MenueState>();

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  File? _newProfilePicture;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  final ImageUploadService _imageUploadService = ImageUploadService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    // Force black status bar when page initializes
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _newProfilePicture = File(image.path);
      });
    }
  }

  // Show password change dialog
  Future<void> _showChangePasswordDialog() async {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;
    bool isChangingPassword = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              contentPadding: EdgeInsets.zero,
              content: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 320, // Adjusted height for password fields
                  color: Colors.grey.shade100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Title
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                        child: Text(
                          AppConstants.changePasswordTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 107, 69, 106),
                          ),
                        ),
                      ),

                      // Current password field
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: TextField(
                          controller: currentPasswordController,
                          obscureText: obscureCurrentPassword,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            hintText: AppConstants.currentPasswordLabel,
                            fillColor: Color.fromARGB(255, 255, 255, 255),
                            filled: true,
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureCurrentPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscureCurrentPassword =
                                      !obscureCurrentPassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ),

                      // New password field
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: TextField(
                          controller: newPasswordController,
                          obscureText: obscureNewPassword,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            hintText: AppConstants.newPasswordLabel,
                            fillColor: Color.fromARGB(255, 255, 255, 255),
                            filled: true,
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureNewPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscureNewPassword = !obscureNewPassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ),

                      // Confirm password field
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: TextField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirmPassword,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            hintText: AppConstants.confirmNewPasswordLabel,
                            fillColor: Color.fromARGB(255, 255, 255, 255),
                            filled: true,
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscureConfirmPassword =
                                      !obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ),

                      // Buttons row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Save button
                          isChangingPassword
                              ? Container(
                                  width: 100,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Color.fromARGB(255, 107, 69, 106),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    ),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: () async {
                                    // Validate inputs
                                    if (currentPasswordController
                                        .text.isEmpty) {
                                      SnackBarHelper.showErrorSnackBar(
                                          context,
                                          AppConstants
                                              .emptyCurrentPasswordError);
                                      return;
                                    }
//check list againt user id 1 images2 checklist 3 data waiting
                                    if (newPasswordController.text.length < 6) {
                                      SnackBarHelper.showErrorSnackBar(context,
                                          AppConstants.newPasswordLengthError);
                                      return;
                                    }

                                    if (newPasswordController.text !=
                                        confirmPasswordController.text) {
                                      SnackBarHelper.showErrorSnackBar(
                                          context,
                                          AppConstants
                                              .newPasswordMismatchError);
                                      return;
                                    }

                                    // Set loading state
                                    setState(() => isChangingPassword = true);

                                    try {
                                      final user =
                                          FirebaseAuth.instance.currentUser;
                                      if (user == null)
                                        throw Exception(
                                            'Kein Benutzer angemeldet');

                                      // Reauthenticate with current password
                                      AuthCredential credential =
                                          EmailAuthProvider.credential(
                                        email: user.email!,
                                        password:
                                            currentPasswordController.text,
                                      );

                                      await user.reauthenticateWithCredential(
                                          credential);

                                      // Update password
                                      await user.updatePassword(
                                          newPasswordController.text);

                                      // Check if "Remember Me" is enabled and update saved password
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      final rememberMe =
                                          prefs.getBool('remember_me') ?? false;

                                      if (rememberMe) {
                                        // Update the saved password
                                        await prefs.setString('saved_password',
                                            newPasswordController.text);
                                        print(
                                            'Updated saved password in SharedPreferences');
                                      }

                                      if (!mounted) return;
                                      Navigator.of(context).pop();

                                      SnackBarHelper.showSuccessSnackBar(
                                          context,
                                          AppConstants
                                              .passwordUpdateSuccessMessage);
                                    } catch (e) {
                                      if (!mounted) return;

                                      String errorMessage = AppConstants
                                          .passwordUpdateFailedError;

                                      if (e
                                          .toString()
                                          .contains('wrong-password')) {
                                        errorMessage = AppConstants
                                            .wrongCurrentPasswordError;
                                      } else if (e
                                          .toString()
                                          .contains('too-many-requests')) {
                                        errorMessage = AppConstants
                                            .tooManyPasswordRequestsError;
                                      }

                                      SnackBarHelper.showErrorSnackBar(
                                          context, errorMessage);

                                      // Reset loading state
                                      setState(
                                          () => isChangingPassword = false);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 107, 69, 106),
                                    foregroundColor: Colors.white,
                                    minimumSize: Size(100, 36),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Speichern'),
                                ),
                          const SizedBox(
                            width: 35,
                          ),
                          // Cancel button
                          ElevatedButton(
                            onPressed: isChangingPassword
                                ? null
                                : () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black87,
                              minimumSize: Size(100, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              disabledBackgroundColor:
                                  Colors.grey[300]!.withOpacity(0.6),
                            ),
                            child: const Text(AppConstants.cancelButton),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Modify the existing _updateProfile method to handle profile updates
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _isUploadingImage = false;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kein Benutzer angemeldet');

      // Update profile picture if selected
      String? newProfilePicUrl;
      if (_newProfilePicture != null) {
        setState(() => _isUploadingImage = true);
        try {
          final uploadResponse =
              await _imageUploadService.uploadImage(_newProfilePicture!);
          newProfilePicUrl = uploadResponse.image.getFullImageUrl();
        } catch (e) {
          setState(() => _isUploadingImage = false);
          SnackBarHelper.showErrorSnackBar(
              context, 'Bild-Upload fehlgeschlagen: \n${e.toString()}');
          setState(() => _isLoading = false);
          return;
        }
        setState(() => _isUploadingImage = false);
      }

      // Update user data in Firestore
      final updates = {
        'name': _nameController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newProfilePicUrl != null) {
        updates['profilePictureUrl'] = newProfilePicUrl;
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updates);

      // Get updated user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        userData['uid'] = user.uid;

        // Create updated UserModel
        final updatedUser = UserModel.fromMap(userData);

        // Update SharedPreferences
        await AuthService().saveUserToPrefs(updatedUser);
      }

      await Menue.refreshUserData();

      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(
            context, AppConstants.profileUpdateSuccessMessage);
        Navigator.pop(context, true); // Return true to indicate update success
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
            context, '${AppConstants.profileUpdateFailedError}${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CustomDialog(
          title: AppConstants.deleteAccountTitle,
          message: AppConstants.deleteAccountConfirmation,
          confirmText: AppConstants.deleteButton,
          cancelText: 'Stornieren',
          onConfirm: () {
            Navigator.of(context).pop();
            _deleteAccount();
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);

    try {
      await AuthService().deleteAccount();

      if (mounted) {
        // Navigate to login screen and remove all previous routes
        Navigator.of(context).pushNamedAndRemoveUntil(
          RouteManager.signinPage,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
            context, '${AppConstants.accountDeleteFailedError}${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Force black status bar on every build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
      ));
    });

    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight / 3;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: Menue.getInstance(key),
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.black,
          statusBarIconBrightness: Brightness.light,
        ),
        foregroundColor: Colors.white,
        title: const Text(AppConstants.editProfileTitle),
        backgroundColor: const Color.fromARGB(255, 107, 69, 106),
      ),
      body: Column(
        children: [
          // Top colored section with profile image (now slightly smaller to account for app bar)
          Container(
            height: headerHeight - AppBar().preferredSize.height,
            width: double.infinity,
            color: const Color.fromARGB(255, 107, 69, 106),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profile image with edit icon
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60, // Increased from 50
                          backgroundColor: Colors.white,
                          backgroundImage: _newProfilePicture != null
                              ? FileImage(_newProfilePicture!)
                              : (widget.currentProfilePicUrl != null
                                  ? NetworkImage(widget.currentProfilePicUrl!)
                                  : null) as ImageProvider?,
                          child: (_newProfilePicture == null &&
                                  widget.currentProfilePicUrl == null)
                              ? const Icon(Icons.person,
                                  size: 60, // Increased from 50
                                  color: Color.fromARGB(255, 107, 69, 106))
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color.fromARGB(255, 107, 69, 106),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Color.fromARGB(255, 107, 69, 106),
                            size: 20, // Slightly increased from 18
                          ),
                        ),
                      ),
                      if (_isUploadingImage)
                        const Positioned.fill(
                          child: Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color.fromARGB(255, 107, 69, 106)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8), // Reduced from 16

                // User name in white
                Text(
                  widget.currentName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Bottom section with form fields and buttons
          Expanded(
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.editProfileTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 107, 69, 106),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Name field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Bitte geben Sie Ihren Namen ein';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Change Password Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.lock_outline),
                          label: Text(
                            AppConstants.changePasswordButton,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed:
                              _isLoading ? null : _showChangePasswordDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor:
                                const Color.fromARGB(255, 107, 69, 106),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            disabledBackgroundColor:
                                Colors.grey[200]!.withOpacity(0.6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Save profile button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 107, 69, 106),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            disabledBackgroundColor:
                                const Color.fromARGB(255, 107, 69, 106)
                                    .withOpacity(0.6),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  AppConstants.saveChangesButton,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Delete account button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed:
                              _isLoading ? null : _showDeleteConfirmationDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Konto löschen',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
