class ImageUploadResponse {
  final String message;
  final String? previousImageUrl;
  final ImageData image;

  ImageUploadResponse({
    required this.message,
    this.previousImageUrl,
    required this.image,
  });

  factory ImageUploadResponse.fromJson(Map<String, dynamic> json) {
    return ImageUploadResponse(
      previousImageUrl: json['previous_image_url'] ?? '',
      message: json['message'] ?? '',
      image: ImageData.fromJson(json['image'] ?? {}),
    );
  }
}

class ImageDeleteResponse {
  final String message;

  ImageDeleteResponse({
    required this.message,
  });

  factory ImageDeleteResponse.fromJson(Map<String, dynamic> json) {
    return ImageDeleteResponse(
      message: json['message'] as String,
    );
  }
}

class ImageData {
  final String filename;
  final String originalname;
  final String mimetype;
  final int size;
  final String path;
  final String url;

  ImageData({
    required this.filename,
    required this.originalname,
    required this.mimetype,
    required this.size,
    required this.path,
    required this.url,
  });

  factory ImageData.fromJson(Map<String, dynamic> json) {
    return ImageData(
      filename: json['filename'] ?? '',
      originalname: json['originalname'] ?? '',
      mimetype: json['mimetype'] ?? '',
      size: json['size'] ?? 0,
      path: json['path'] ?? '',
      url: json['url'] ?? '',
    );
  }

  String getFullImageUrl() {
    return 'http://164.92.175.72:3001${url}';
  }
}
