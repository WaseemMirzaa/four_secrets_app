import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:four_secrets_wedding_app/models/image_upload_response.dart';
import 'package:four_secrets_wedding_app/services/image_upload_service.dart';

class FileUploadService1 {
  static final ImageUploadService _imageUploadService = ImageUploadService();
  static final ImagePicker _imagePicker = ImagePicker();

  /// Pick and upload an image file (camera or gallery)
  static Future<FileUploadResult?> pickAndUploadImage({
    required ImageSource source,
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      final File file = File(pickedFile.path);
      final String fileName = pickedFile.name;

      // Upload using existing image upload service
      final ImageUploadResponse? response =
          await _imageUploadService.uploadImage(file);

      if (response != null && response.image.url.isNotEmpty) {
        return FileUploadResult(
          fileName: fileName,
          fileUrl: response.image.getFullImageUrl(),
          fileType: FileType.image,
          success: true,
        );
      } else {
        return FileUploadResult(
          fileName: fileName,
          fileUrl: '',
          fileType: FileType.image,
          success: false,
          error: response?.message ?? 'Upload failed',
        );
      }
    } catch (e) {
      return FileUploadResult(
        fileName: '',
        fileUrl: '',
        fileType: FileType.image,
        success: false,
        error: 'Error picking image: $e',
      );
    }
  }

  /// Pick and upload a file (images, PDFs, etc.)
  static Future<FileUploadResult?> pickAndUploadFile({
    List<String>? allowedExtensions,
  }) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final PlatformFile platformFile = result.files.first;
      final String fileName = platformFile.name;
      final String? filePath = platformFile.path;

      if (filePath == null) {
        return FileUploadResult(
          fileName: fileName,
          fileUrl: '',
          fileType: _getFileType(fileName),
          success: false,
          error: 'File path is null',
        );
      }

      final File file = File(filePath);

      // Use appropriate upload method based on file type
      final ImageUploadResponse response;
      if (isPdfFile(fileName)) {
        // Use file upload endpoint for PDFs
        response = await _imageUploadService.uploadFile(file);
      } else {
        // Use image upload endpoint for images and other files
        response = await _imageUploadService.uploadImage(file);
      }

      if (response.image.url.isNotEmpty) {
        return FileUploadResult(
          fileName: fileName,
          fileUrl: response.image.getFullImageUrl(),
          fileType: _getFileType(fileName),
          success: true,
        );
      } else {
        return FileUploadResult(
          fileName: fileName,
          fileUrl: '',
          fileType: _getFileType(fileName),
          success: false,
          error:
              response.message.isNotEmpty ? response.message : 'Upload failed',
        );
      }
    } catch (e) {
      return FileUploadResult(
        fileName: '',
        fileUrl: '',
        fileType: FileType.any,
        success: false,
        error: 'Error picking file: $e',
      );
    }
  }

  /// Pick and upload files specifically for wedding offers (images and PDFs)
  static Future<FileUploadResult?> pickAndUploadOfferFile() async {
    return await pickAndUploadFile(
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif'],
    );
  }

  /// Show file picker options (camera, gallery, files)
  static Future<FileUploadResult?> showFilePickerOptions({
    required Function(ImageSource) onImagePick,
    required Function() onFilePick,
  }) async {
    // This method can be used to show a bottom sheet with options
    // Implementation depends on UI requirements
    return null;
  }

  /// Get file type based on extension
  static FileType _getFileType(String fileName) {
    final String extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return FileType.image;
      case 'pdf':
        return FileType.custom;
      case 'doc':
      case 'docx':
      case 'txt':
        return FileType.custom;
      default:
        return FileType.any;
    }
  }

  /// Check if file is an image
  static bool isImageFile(String fileName) {
    final String extension = fileName.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  /// Check if file is a PDF
  static bool isPdfFile(String fileName) {
    final String extension = fileName.split('.').last.toLowerCase();
    return extension == 'pdf';
  }

  /// Get file icon based on type
  static String getFileIcon(String fileName) {
    if (isImageFile(fileName)) return '🖼️';
    if (isPdfFile(fileName)) return '📄';
    return '📎';
  }
}

/// Result class for file upload operations
class FileUploadResult {
  final String fileName;
  final String fileUrl;
  final FileType fileType;
  final bool success;
  final String? error;

  FileUploadResult({
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.success,
    this.error,
  });
}
