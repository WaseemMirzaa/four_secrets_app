import 'package:cloud_firestore/cloud_firestore.dart';

class WeddingCategoryModel1 {
  final String id;
  final String categoryName;
  final List<String> items;
  final DateTime createdAt;
  final String userId;

  WeddingCategoryModel1({
    required this.id,
    required this.categoryName,
    required this.items,
    required this.createdAt,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'categoryName': categoryName,
      'items': items,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
    };
  }

  static WeddingCategoryModel1 fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WeddingCategoryModel1(
      id: doc.id,
      categoryName: data['categoryName'] ?? '',
      items: List<String>.from(data['items'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: data['userId'] ?? '',
    );
  }

  WeddingCategoryModel1 copyWith({
    String? id,
    String? categoryName,
    List<String>? items,
    DateTime? createdAt,
    String? userId,
  }) {
    return WeddingCategoryModel1(
      id: id ?? this.id,
      categoryName: categoryName ?? this.categoryName,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }
}
