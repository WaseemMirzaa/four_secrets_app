class NonRegisteredUser {
  final String email;
  final String name;
  final DateTime invitedAt;

  NonRegisteredUser({
    required this.email,
    required this.name,
    required this.invitedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'invitedAt': invitedAt.toIso8601String(),
    };
  }

  factory NonRegisteredUser.fromMap(Map<String, dynamic> map) {
    return NonRegisteredUser(
      email: map['email'],
      name: map['name'],
      invitedAt: DateTime.parse(map['invitedAt']),
    );
  }
}
