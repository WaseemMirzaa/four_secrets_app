import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String categoryName;
  final List<String> todos;
  final DateTime createdAt;
  final String userId;

  CategoryModel({
    required this.id,
    required this.categoryName,
    required this.todos,
    required this.createdAt,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'categoryName': categoryName,
      'todos': todos,
      'createdAt': createdAt,
      'userId': userId,
    };
  }

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      categoryName: data['categoryName'] ?? '',
      todos: List<String>.from(data['todos'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
    );
  }
}
