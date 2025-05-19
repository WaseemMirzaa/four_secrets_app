import 'package:cloud_firestore/cloud_firestore.dart';

class Guest {
  final String id;
  final String name;
  String? contactNumber;
  final String guestType;
  String? profilePicture;
  final DateTime createdAt;
  DateTime? updatedAt;

  Guest({
    required this.id,
    required this.name,
    this.contactNumber,
    required this.guestType,
    this.profilePicture,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contactNumber': contactNumber,
      'guestType': guestType,
      'profilePicture': profilePicture,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Guest.fromMap(Map<String, dynamic> map) {
    return Guest(
      id: map['id'],
      name: map['name'],
      contactNumber: map['contactNumber'],
      guestType: map['guestType'],
      profilePicture: map['profilePicture'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}