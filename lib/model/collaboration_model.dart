import 'package:cloud_firestore/cloud_firestore.dart';

class CollaborationModel {
  final String id;
  final String todoId;
  final String todoName;
  final String inviterId;
  final String inviterName;
  final String inviteeId;
  final String inviteeName;
  final String status;
  final DateTime createdAt;

  CollaborationModel({
    required this.id,
    required this.todoId,
    required this.todoName,
    required this.inviterId,
    required this.inviterName,
    required this.inviteeId,
    required this.inviteeName,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'todoId': todoId,
      'todoName': todoName,
      'inviterId': inviterId,
      'inviterName': inviterName,
      'inviteeId': inviteeId,
      'inviteeName': inviteeName,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static CollaborationModel fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CollaborationModel(
      id: doc.id,
      todoId: data['todoId'] ?? '',
      todoName: data['todoName'] ?? '',
      inviterId: data['inviterId'] ?? '',
      inviterName: data['inviterName'] ?? '',
      inviteeId: data['inviteeId'] ?? '',
      inviteeName: data['inviteeName'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  CollaborationModel copyWith({
    String? id,
    String? todoId,
    String? todoName,
    String? inviterId,
    String? inviterName,
    String? inviteeId,
    String? inviteeName,
    String? status,
    DateTime? createdAt,
  }) {
    return CollaborationModel(
      id: id ?? this.id,
      todoId: todoId ?? this.todoId,
      todoName: todoName ?? this.todoName,
      inviterId: inviterId ?? this.inviterId,
      inviterName: inviterName ?? this.inviterName,
      inviteeId: inviteeId ?? this.inviteeId,
      inviteeName: inviteeName ?? this.inviteeName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
