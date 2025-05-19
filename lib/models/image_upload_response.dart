class ImageUploadResponse {
  final String message;
  final ImageData image;

  ImageUploadResponse({
    required this.message,
    required this.image,
  });

  factory ImageUploadResponse.fromJson(Map<String, dynamic> json) {
    return ImageUploadResponse(
      message: json['message'] ?? '',
      image: ImageData.fromJson(json['image'] ?? {}),
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
    return 'http://164.92.175.72${url}';
  }
}