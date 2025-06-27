import 'package:cloud_firestore/cloud_firestore.dart';

class NonRegisteredInviteModel {
  final String id;
  final String email;
  final String inviterEmail;
  final String? inviterId;
  final String? todoId;
  final String? todoName;
  final String status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  NonRegisteredInviteModel({
    required this.id,
    required this.email,
    required this.inviterEmail,
    this.inviterId,
    this.todoId,
    this.todoName,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory NonRegisteredInviteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NonRegisteredInviteModel(
      id: doc.id,
      email: data['email'] ?? '',
      inviterEmail: data['inviterEmail'] ?? '',
      inviterId: data['inviterId'],
      todoId: data['todoId'],
      todoName: data['todoName'],
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'inviterEmail': inviterEmail,
      'inviterId': inviterId,
      'todoId': todoId,
      'todoName': todoName,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt':
          respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }
}
