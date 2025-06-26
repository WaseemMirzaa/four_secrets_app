import 'package:flutter/material.dart';

/// Helper class to show consistent SnackBars throughout the app
class SnackBarHelper {
  /// Shows an error SnackBar with longer duration and fade-out animation
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 8), // Longer duration for errors
        behavior: SnackBarBehavior.floating,
        animation: _createFadeAnimation(context),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  /// Shows an info SnackBar with standard duration and fade-out animation
  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5), // Standard duration
        behavior: SnackBarBehavior.floating,
        animation: _createFadeAnimation(context),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  /// Shows a success SnackBar with standard duration and fade-out animation
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5), // Standard duration
        behavior: SnackBarBehavior.floating,
        animation: _createFadeAnimation(context),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  /// Shows a persistent SnackBar with a close button (for reminders)
  static void showPersistentSnackBar(BuildContext context, String message,
      {Color? backgroundColor}) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Expanded(child: Text(message)),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            tooltip: 'Schließen',
          ),
        ],
      ),
      backgroundColor: backgroundColor ?? Colors.deepPurple,
      duration: const Duration(days: 1), // Effectively infinite
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.horizontal,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Creates a custom fade animation for SnackBars
  static Animation<double> _createFadeAnimation(BuildContext context) {
    final AnimationController controller = AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 500), // Fade-in duration
    );

    // Start the animation
    controller.forward();

    // Create a curved animation that fades in quickly and fades out slowly
    return CurvedAnimation(
      parent: controller,
      curve: Curves.easeIn,
      reverseCurve: Curves.easeOut,
    );
  }
}
