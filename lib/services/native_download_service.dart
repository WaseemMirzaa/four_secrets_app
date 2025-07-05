import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';

class NativeDownloadService {
  /// Downloads a PDF file to the device's Downloads folder using native integration
  static Future<bool> downloadPdf({
    required BuildContext context,
    required Uint8List pdfBytes,
    required String filename,
    String? successMessage,
  }) async {
    try {
      // Request storage permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        if (context.mounted) {
          SnackBarHelper.showErrorSnackBar(
            context,
            'Speicherberechtigung erforderlich zum Herunterladen',
          );
        }
        return false;
      }

      // Get the appropriate download directory
      Directory? downloadDir;

      if (Platform.isAndroid) {
        // For Android, try to get the Downloads directory
        try {
          downloadDir = Directory('/storage/emulated/0/Download');
          if (!await downloadDir.exists()) {
            // Fallback to external storage directory
            downloadDir = await getExternalStorageDirectory();
            if (downloadDir != null) {
              downloadDir = Directory('${downloadDir.path}/Download');
            }
          }
        } catch (e) {
          // Fallback to app documents directory
          downloadDir = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        // For iOS, use the app's documents directory which is accessible via Files app
        downloadDir = await getApplicationDocumentsDirectory();
      } else {
        // For other platforms, use downloads directory
        downloadDir = await getDownloadsDirectory();
      }

      if (downloadDir == null) {
        if (context.mounted) {
          SnackBarHelper.showErrorSnackBar(
            context,
            'Download-Verzeichnis nicht verfügbar',
          );
        }
        return false;
      }

      // Create the directory if it doesn't exist
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // Ensure filename has .pdf extension
      if (!filename.toLowerCase().endsWith('.pdf')) {
        filename = '$filename.pdf';
      }

      // Create the file path
      final filePath = '${downloadDir.path}/$filename';
      final file = File(filePath);

      // Write the PDF bytes to the file
      await file.writeAsBytes(pdfBytes);

      // Show success message with platform-specific options
      if (context.mounted) {
        final message =
            successMessage ?? 'PDF erfolgreich heruntergeladen: $filename';

        if (Platform.isAndroid) {
          // Android: Show detailed info with open option
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  const SizedBox(height: 4),
                  Text(
                    'Gespeichert in: Downloads',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              backgroundColor: const Color.fromARGB(255, 107, 69, 106),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Öffnen',
                textColor: Colors.white,
                onPressed: () => _openFile(filePath),
              ),
            ),
          );
        } else if (Platform.isIOS) {
          // iOS: Show success with share option
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  const SizedBox(height: 4),
                  Text(
                    'Gespeichert in: Dateien App',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              backgroundColor: const Color.fromARGB(255, 107, 69, 106),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Teilen',
                textColor: Colors.white,
                onPressed: () => _shareFile(filePath, filename),
              ),
            ),
          );
        } else {
          // Other platforms: Simple success message
          SnackBarHelper.showSuccessSnackBar(context, message);
        }
      }

      return true;
    } catch (e) {
      print('Error downloading PDF: $e');
      if (context.mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          'Fehler beim Herunterladen: $e',
        );
      }
      return false;
    }
  }

  /// Requests storage permission for Android devices
  static Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), we don't need WRITE_EXTERNAL_STORAGE
      // For older versions, request the permission
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 33) {
        return true; // No permission needed for Android 13+
      }

      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true; // iOS doesn't need explicit storage permission for app documents
  }

  /// Gets Android SDK version
  static Future<int> _getAndroidVersion() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.version.sdkInt;
      }
    } catch (e) {
      print('Error getting Android version: $e');
    }
    return 0;
  }

  /// Opens a file using the system's default app (Android)
  static Future<void> _openFile(String filePath) async {
    try {
      if (Platform.isAndroid) {
        // Try to open with the default PDF viewer
        final result = await Process.run('am', [
          'start',
          '-a',
          'android.intent.action.VIEW',
          '-d',
          'file://$filePath',
          '-t',
          'application/pdf',
          '--grant-read-uri-permission'
        ]);

        if (result.exitCode != 0) {
          // Fallback: try to open with any app that can handle the file
          await Process.run('am', [
            'start',
            '-a',
            'android.intent.action.VIEW',
            '-d',
            'file://$filePath',
          ]);
        }
      }
    } catch (e) {
      print('Error opening file: $e');
      // Could also show a snackbar to user about the error
    }
  }

  /// Shares a file using the native share sheet (iOS)
  static Future<void> _shareFile(String filePath, String filename) async {
    try {
      if (Platform.isIOS) {
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'PDF: $filename',
          subject: filename,
        );
      }
    } catch (e) {
      print('Error sharing file: $e');
    }
  }

  /// Generates a timestamped filename
  static String generateTimestampedFilename(String baseName) {
    final now = DateTime.now();
    return '${baseName}_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
  }
}
