import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:four_secrets_wedding_app/services/notification_alaram-service.dart';

class NativeDownloadService {
  /// Downloads a PDF file to the device's Downloads folder using native integration
  static Future<bool> downloadPdf({
    required BuildContext context,
    required Uint8List pdfBytes,
    required String filename,
    String? successMessage,
  }) async {
    try {
      print('🔵 ===== STARTING PDF DOWNLOAD =====');
      print('🔵 Filename: $filename');
      print('🔵 PDF bytes length: ${pdfBytes.length}');
      print('🔵 Platform: ${Platform.operatingSystem}');

      // Show immediate feedback to user
      if (context.mounted) {
        SnackBarHelper.showSuccessSnackBar(
          context,
          'Download wird gestartet...',
        );
      }

      // For Android 13+, we don't need storage permissions for app-specific directories
      // For older Android versions, request permission
      if (Platform.isAndroid) {
        print('🔵 Checking Android storage permission...');
        final androidInfo = await _getAndroidVersion();
        if (androidInfo < 33) {
          final hasPermission = await _requestStoragePermission();
          if (!hasPermission) {
            print('🔴 Storage permission denied');
            if (context.mounted) {
              SnackBarHelper.showErrorSnackBar(
                context,
                'Speicherberechtigung erforderlich zum Herunterladen',
              );
            }
            return false;
          }
          print('🟢 Storage permission granted');
        } else {
          print('🟢 Android 13+: No storage permission needed');
        }
      }

      // Use a much simpler approach - try multiple paths until one works
      Directory? downloadDir;
      List<String> attemptedPaths = [];

      try {
        if (Platform.isAndroid) {
          // Try multiple Android paths in order of preference
          List<Directory?> androidPaths = [
            // 1. Try external storage Downloads (most preferred)
            Directory('/storage/emulated/0/Download'),
            // 2. Try external app directory
            await getExternalStorageDirectory(),
            // 3. Fallback to app documents
            await getApplicationDocumentsDirectory(),
          ];

          for (var dir in androidPaths) {
            if (dir != null) {
              attemptedPaths.add(dir.path);
              if (await dir.exists() || dir.path.contains('Documents')) {
                downloadDir = dir;
                print('🟢 Using Android path: ${dir.path}');
                break;
              }
            }
          }
        } else if (Platform.isIOS) {
          // For iOS, use the app's documents directory
          downloadDir = await getApplicationDocumentsDirectory();
          print('🟢 Using iOS path: ${downloadDir.path}');
        }

        // Final fallback
        downloadDir ??= await getApplicationDocumentsDirectory();
        print('🔵 Final download directory: ${downloadDir.path}');
        print('🔵 Attempted paths: $attemptedPaths');
      } catch (e) {
        print('🔴 Error getting download directory: $e');
        downloadDir = await getApplicationDocumentsDirectory();
      }

      // downloadDir is guaranteed to be non-null due to fallback

      // Create the directory if it doesn't exist
      print('🔵 Download directory: ${downloadDir.path}');
      if (!await downloadDir.exists()) {
        print('🔵 Creating download directory...');
        await downloadDir.create(recursive: true);
        print('🟢 Download directory created');
      } else {
        print('🟢 Download directory already exists');
      }

      // Ensure filename has .pdf extension
      if (!filename.toLowerCase().endsWith('.pdf')) {
        filename = '$filename.pdf';
      }

      // Create the file path
      final filePath = '${downloadDir.path}/$filename';
      final file = File(filePath);
      print('🔵 Writing PDF to: $filePath');

      // Write the PDF bytes to the file with verification
      print('🔵 Attempting to write ${pdfBytes.length} bytes to: $filePath');

      try {
        await file.writeAsBytes(pdfBytes, flush: true);
        print('🔵 File write completed, verifying...');

        // Verify the file was actually written
        if (await file.exists()) {
          final writtenSize = await file.length();
          print(
              '🟢 File verified: exists=${await file.exists()}, size=$writtenSize bytes');

          if (writtenSize == pdfBytes.length) {
            print('🟢 PDF file written successfully and verified!');

            // Show download completion notification
            await _showDownloadNotification(filename, filePath);
          } else {
            throw Exception(
                'File size mismatch: expected ${pdfBytes.length}, got $writtenSize');
          }
        } else {
          throw Exception('File does not exist after writing');
        }
      } catch (writeError) {
        print('🔴 File write error: $writeError');
        throw Exception('Failed to write file: $writeError');
      }

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
      print('🔴 Error downloading PDF: $e');
      print('🔴 Stack trace: ${StackTrace.current}');

      // Try alternative download methods
      print('🔵 Attempting alternative download methods...');

      // Method 1: Try different directory
      try {
        final result = await _fallbackDownload(context, pdfBytes, filename);
        if (result) {
          print('🟢 Fallback download successful');
          return true;
        }
      } catch (fallbackError) {
        print('🔴 Fallback download failed: $fallbackError');
      }

      // Method 2: Try share-based approach as last resort
      try {
        final result = await _shareBasedDownload(context, pdfBytes, filename);
        if (result) {
          print('🟢 Share-based download successful');
          return true;
        }
      } catch (shareError) {
        print('🔴 Share-based download failed: $shareError');
      }

      if (context.mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          'Fehler beim Herunterladen: $e',
        );
      }
      return false;
    }
  }

  /// Fallback download method using app documents directory
  static Future<bool> _fallbackDownload(
    BuildContext context,
    Uint8List pdfBytes,
    String filename,
  ) async {
    try {
      print('🔵 Using fallback download method');

      // Get documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${documentsDir.path}/Downloads');

      // Create Downloads directory if it doesn't exist
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Ensure filename has .pdf extension
      if (!filename.toLowerCase().endsWith('.pdf')) {
        filename = '$filename.pdf';
      }

      final file = File('${downloadsDir.path}/$filename');
      print('🔵 Fallback writing to: ${file.path}');

      // Write PDF bytes to file
      await file.writeAsBytes(pdfBytes);
      print('🟢 Fallback file written successfully');

      // Show download completion notification
      await _showDownloadNotification(filename, file.path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF gespeichert: $filename'),
            backgroundColor: const Color.fromARGB(255, 107, 69, 106),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      return true;
    } catch (e) {
      print('🔴 Fallback download error: $e');
      return false;
    }
  }

  /// Share-based download method as last resort
  static Future<bool> _shareBasedDownload(
    BuildContext context,
    Uint8List pdfBytes,
    String filename,
  ) async {
    try {
      print('🔵 Using share-based download method');

      // Create temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$filename');

      // Write to temporary file
      await tempFile.writeAsBytes(pdfBytes);

      if (await tempFile.exists()) {
        print('🔵 Temporary file created, sharing...');

        // Share the file - user can save it from share dialog
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: 'PDF: $filename',
          subject: filename,
        );

        if (context.mounted) {
          SnackBarHelper.showSuccessSnackBar(
            context,
            'PDF über Teilen-Dialog verfügbar: $filename',
          );
        }

        return true;
      }

      return false;
    } catch (e) {
      print('🔴 Share-based download error: $e');
      return false;
    }
  }

  /// Requests storage permission for Android devices
  static Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      try {
        // For Android 13+ (API 33+), we don't need WRITE_EXTERNAL_STORAGE
        // For older versions, request the permission
        final androidInfo = await _getAndroidVersion();
        print('🔵 Android SDK version: $androidInfo');

        if (androidInfo >= 33) {
          print('🟢 Android 13+: No storage permission needed');
          return true; // No permission needed for Android 13+
        }

        print('🔵 Requesting storage permission for Android < 13');
        final status = await Permission.storage.request();
        print('🔵 Storage permission status: $status');

        if (status.isGranted) {
          print('🟢 Storage permission granted');
          return true;
        } else if (status.isPermanentlyDenied) {
          print('🔴 Storage permission permanently denied');
          return false;
        } else {
          print('🔴 Storage permission denied');
          return false;
        }
      } catch (e) {
        print('🔴 Error requesting storage permission: $e');
        return false;
      }
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

  /// Shows a download completion notification
  static Future<void> _showDownloadNotification(
      String filename, String filePath) async {
    try {
      print('🔵 Showing download notification for: $filename');

      await NotificationService.showAlarmNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
        title: 'PDF Download abgeschlossen',
        body: 'Datei gespeichert: $filename',
        payload: filePath,
      );

      print('🟢 Download notification shown successfully');
    } catch (e) {
      print('🔴 Error showing download notification: $e');
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
    return '${baseName}_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}.pdf';
  }
}
