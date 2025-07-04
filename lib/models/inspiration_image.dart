import 'package:cloud_firestore/cloud_firestore.dart';

class InspirationImageModel {
   String? id;
  final String title;
  final String imageUrl;
   String? previousImageUrl;
  final DateTime createdAt;
  final String userId;

  InspirationImageModel({
     this.id,
    required this.title,
     this.previousImageUrl,
    required this.imageUrl,
    required this.createdAt,
    required this.userId,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      if(id != null)
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'createdAt':  Timestamp.fromDate(createdAt),
      'userId': userId,
    };
    
  }

  // Create from Firestore document
  factory InspirationImageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InspirationImageModel(
      id: doc.id,
      title: data['title'] ?? '',
      previousImageUrl: data['previousImageUrl'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
    );
  }

  // Create a copy with some fields changed
  InspirationImageModel copyWith({
    String? id,
    String? title,
    String? imageUrl,
    DateTime? createdAt,
    String? userId,
  }) {
    return InspirationImageModel(
      id: id ?? this.id,
      title: title ??  this.title,
      previousImageUrl: previousImageUrl ?? this.previousImageUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() {
    return 'InspirationImage Model(id: $id, title: $title, createdAt: $createdAt, userId: $userId)';
  }
}