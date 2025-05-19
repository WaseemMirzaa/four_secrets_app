import 'package:cloud_firestore/cloud_firestore.dart';

class ChecklistItemModel {
  final String id;
  final String taskName;
   bool isCompleted;
  final DateTime createdAt;
  final String userId;

  ChecklistItemModel({
    required this.id,
    required this.taskName,
    required this.isCompleted,
    required this.createdAt,
    required this.userId,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'taskName': taskName,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
    };
  }

  // Create from Firestore document
  factory ChecklistItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChecklistItemModel(
      id: doc.id,
      taskName: data['taskName'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
    );
  }

  // Create a copy with some fields changed
  ChecklistItemModel copyWith({
    String? id,
    String? taskName,
    bool? isCompleted,
    DateTime? createdAt,
    String? userId,
  }) {
    return ChecklistItemModel(
      id: id ?? this.id,
      taskName: taskName ?? this.taskName,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() {
    return 'ChecklistItemModel(id: $id, taskName: $taskName, isCompleted: $isCompleted, createdAt: $createdAt, userId: $userId)';
  }
}