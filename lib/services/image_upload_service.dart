import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart';
import '../models/image_upload_response.dart';

class ImageUploadService {
  static const String baseUrl = 'http://164.92.175.72';
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
}
