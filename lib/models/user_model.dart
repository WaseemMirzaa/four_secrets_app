class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? profilePictureUrl;
  final bool emailVerified;
  final bool isSubscribed;
  final bool todoUnreadStatus;
  // final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.profilePictureUrl,
    this.emailVerified = false,
    this.isSubscribed = true, // Set to true for testing
    this.todoUnreadStatus = false, // Default to false (no unread todos)
    // this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profilePictureUrl: map['profilePictureUrl'],
      emailVerified: map['emailVerified'] ?? false,
      isSubscribed: map['isSubscribed'] ?? true, // Default to true for testing
      todoUnreadStatus: map['todoUnreadStatus'] ?? false, // Default to false
      // createdAt: map['createdAt'] != null
      //     ? (map['createdAt'] as Timestamp).toDate()
      //     : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'profilePictureUrl': profilePictureUrl,
      'emailVerified': emailVerified,
      'isSubscribed': isSubscribed,
      'todoUnreadStatus': todoUnreadStatus,
      // 'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, profilePictureUrl: $profilePictureUrl, emailVerified: $emailVerified, isSubscribed: $isSubscribed, todoUnreadStatus: $todoUnreadStatus)';
  }
}
