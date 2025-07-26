class NonRegisteredUser {
  final String email;
  final String name;
  final DateTime invitedAt;
  final bool todoUnreadStatus;

  NonRegisteredUser({
    required this.email,
    required this.name,
    required this.invitedAt,
    this.todoUnreadStatus = true, // Default to true when invited
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'invitedAt': invitedAt.toIso8601String(),
      'todoUnreadStatus': todoUnreadStatus,
    };
  }

  factory NonRegisteredUser.fromMap(Map<String, dynamic> map) {
    return NonRegisteredUser(
      email: map['email'],
      name: map['name'],
      invitedAt: DateTime.parse(map['invitedAt']),
      todoUnreadStatus: map['todoUnreadStatus'] ?? true, // Default to true
    );
  }
}
