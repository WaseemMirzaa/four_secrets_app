import 'dart:io';
import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/widgets/auth_background.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/image_upload_service.dart';
import '../widgets/auth_text_field.dart';
import '../utils/snackbar_helper.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  File? _profilePicture;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  final ImageUploadService _imageUploadService = ImageUploadService();

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profilePicture = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AuthBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo Section

                    // Welcome Text
                    const Text(
                      AppConstants.signUpTitle,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppConstants.signUpSubtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Profile Picture Selector
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    image: _profilePicture != null
                                        ? DecorationImage(
                                            image: FileImage(_profilePicture!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: _profilePicture == null
                                      ? Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.white.withOpacity(0.7),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Color.fromARGB(255, 107, 69, 106),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
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
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _profilePicture == null
                            ? AppConstants.addProfilePictureText
                            : AppConstants.changeProfilePictureText,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form Fields
                    AuthTextField(
                      label: AppConstants.nameLabel,
                      controller: _nameController,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return AppConstants.emptyNameError;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      label: AppConstants.emailLabel,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return AppConstants.emptyEmailError;
                        }
                        if (!value!.contains('@')) {
                          return AppConstants.invalidEmailError;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      label: AppConstants.passwordLabel,
                      controller: _passwordController,
                      obscureText: true,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return AppConstants.emptyPasswordError;
                        }
                        if (value!.length < 6) {
                          return AppConstants.passwordLengthError;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      label: AppConstants.confirmPasswordLabel,
                      controller: _confirmPasswordController,
                      obscureText: true,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return AppConstants.emptyConfirmPasswordError;
                        }
                        if (value != _passwordController.text) {
                          return AppConstants.passwordMismatchError;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color.fromARGB(255, 107, 69, 106),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor:
                              Colors.white.withOpacity(0.6),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color.fromARGB(255, 107, 69, 106),
                                  ),
                                ),
                              )
                            : Text(
                                AppConstants.registerButton,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 107, 69, 106),
                                ),
                              ),
                      ),
                    ),

                    // Sign In Link
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          AppConstants.haveAccountText,
                          style: TextStyle(color: Colors.white),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            AppConstants.signInLink,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _isUploadingImage = false;
    });

    try {
      String? profilePictureUrl;
      if (_profilePicture != null) {
        setState(() => _isUploadingImage = true);
        try {
          final uploadResponse =
              await _imageUploadService.uploadImage(_profilePicture!);
          profilePictureUrl = uploadResponse.image.getFullImageUrl();
        } catch (e) {
          setState(() => _isUploadingImage = false);
          SnackBarHelper.showErrorSnackBar(
              context, 'Bild-Upload fehlgeschlagen: \n${e.toString()}');
          setState(() => _isLoading = false);
          return;
        }
        setState(() => _isUploadingImage = false);
      }

      // Create the user with optional image URL
      // ignore: unused_local_variable
      final userCredential = await AuthService().signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        profilePicture: _profilePicture,
        profilePictureUrl: profilePictureUrl,
      );

      if (mounted) {
        await FirebaseAuth.instance.currentUser!.sendEmailVerification();
        Navigator.of(context).pushNamedAndRemoveUntil(
          RouteManager.emailVerificationPage,
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = AppConstants.emailAlreadyInUseError;
          break;
        case 'invalid-email':
          errorMessage = AppConstants.invalidEmailError;
          break;
        case 'operation-not-allowed':
          errorMessage = AppConstants.operationNotAllowedError;
          break;
        case 'weak-password':
          errorMessage = AppConstants.weakPasswordError;
          break;
        case 'network-request-failed':
          errorMessage = AppConstants.networkRequestFailedError;
          break;
        default:
          errorMessage =
              '${AppConstants.signUpFailedError}${e.message ?? 'Please try again'}';
      }
      SnackBarHelper.showErrorSnackBar(context, errorMessage);
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showErrorSnackBar(
          context, 'Ein Fehler ist aufgetreten: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingImage = false;
        });
      }
    }
  }
}
