import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart';
import '../models/image_upload_response.dart';

class ImageUploadService {
  static const String baseUrl = 'http://164.92.175.72:3001';
  static const String deleteEndpoint = '/api/images/delete';
  static const String uploadEndpoint = '/api/images/upload';

  Future<ImageUploadResponse> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse('$baseUrl$uploadEndpoint');

      // Create multipart request
      final request = http.MultipartRequest('POST', uri);

      // Add the image file to the request
      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();

      final multipartFile = http.MultipartFile(
        'image', // parameter name for the image
        fileStream,
        fileLength,
        filename: basename(imageFile.path),
      );

      request.files.add(multipartFile);

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Accept both 200 and 201 status codes as success
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        return ImageUploadResponse.fromJson(jsonResponse);
      } else {
        throw Exception(
            'Failed to upload image: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload a file (PDF, documents, etc.) with file prefix instead of image prefix
  Future<ImageUploadResponse> uploadFile(File file) async {
    try {
      final uri = Uri.parse('$baseUrl$uploadEndpoint');

      // Create multipart request
      final request = http.MultipartRequest('POST', uri);

      // Add a parameter to indicate this is a file upload (not image)
      request.fields['file_type'] = 'file';

      // Add the file to the request
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();

      final multipartFile = http.MultipartFile(
        'image', // Keep same parameter name for compatibility
        fileStream,
        fileLength,
        filename: basename(file.path),
      );

      request.files.add(multipartFile);

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Accept both 200 and 201 status codes as success
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        return ImageUploadResponse.fromJson(jsonResponse);
      } else {
        throw Exception(
            'Failed to upload file: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error uploading file: $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Upload and optionally replace an existing image on the server
  Future<ImageUploadResponse> uploadImageAndUpdateImage(
    File imageFile, {
    String? previousImageUrl, // ← NOW OPTIONAL
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$uploadEndpoint');
      final request = http.MultipartRequest('POST', uri);

      if (previousImageUrl != null && previousImageUrl.isNotEmpty) {
        request.fields['previous_image_url'] = previousImageUrl;
      }

      final stream = http.ByteStream(imageFile.openRead());
      final length = await imageFile.length();
      request.files.add(http.MultipartFile(
        'image',
        stream,
        length,
        filename: basename(imageFile.path),
      ));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ImageUploadResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception(
            'Upload & update failed: ${response.statusCode} – ${response.body}');
      }
    } catch (e) {
      print('Error in uploadImageAndUpdateImage: $e');
      rethrow;
    }
  }

  /// Delete an image from the server
  Future<ImageDeleteResponse> deleteImage(String imageUrl) async {
    try {
      final uri = Uri.parse('$baseUrl$deleteEndpoint');
      final resp = await http.delete(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'image_url': imageUrl}),
      );

      print(resp.body);

      if (resp.statusCode == 200) {
        print("deleted");
        return ImageDeleteResponse.fromJson(json.decode(resp.body));
      } else {
        throw Exception('Delete failed: ${resp.statusCode} – ${resp.body}');
      }
    } catch (e) {
      print('Error deleting image: $e');
      rethrow;
    }
  }
}
