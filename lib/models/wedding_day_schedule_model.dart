import 'package:cloud_firestore/cloud_firestore.dart';

class WeddingDayScheduleModel {
   String? id;
  final String title;
  // final String description;
  final String responsiblePerson;
  final String notes;
   DateTime time;
  final bool reminderEnabled;
  final DateTime? reminderTime; // Make this nullable
  final String userId;
  final int order;
  final String address;
  final double lat;
  final double long;

  WeddingDayScheduleModel({
     this.id,
    required this.title,
    // required this.description,
    required this.time,
    required this.reminderEnabled,
    this.reminderTime, // Make this optional (not required)
    required this.userId,
    required this.responsiblePerson,
    required this.notes,
    required this.order,
    required this.address,
    required this.lat,
    required this.long
  });

  Map<String, dynamic> toMap() {
    return {
      if(id != null)
      'id': id,
      'title': title,
      // 'description': description,
     'time': Timestamp.fromDate(time),
      'reminderEnabled': reminderEnabled,
      if(reminderTime != null) // Only add reminderTime if it's not null
      'reminderTime': Timestamp.fromDate(reminderTime!),
      'userId': userId,
      'responsiblePerson': responsiblePerson,
      'notes': notes,
      'order': order,
      'address' : address,  
      'lat' : lat, 
      'long' : long
      
    };
  }

  factory WeddingDayScheduleModel.fromMap(Map<String, dynamic> map) {
    return WeddingDayScheduleModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      // description: map['description'] ?? '',
     time: (map['time'] as Timestamp).toDate(),
      reminderEnabled: map['reminderEnabled'] ?? false,
     reminderTime: map['reminderTime'] != null ? (map['reminderTime'] as Timestamp).toDate() : null, // Handle null case
      userId: map['userId'] ?? '',
      responsiblePerson: map['responsiblePerson'] ?? '',
      notes: map['notes'] ?? '',
      order: map['order'] ?? 0,
     address: map['address'] ?? "No Address", 
     lat: map['lat'] ?? 0.00, 
     long: map['long'] ?? 0.00
    );
  }

WeddingDayScheduleModel copyWith({
  String? id,
  String? title,
  String? description,
  DateTime? time,
  bool? reminderEnabled,
  DateTime? reminderTime,
  String? userId,
  String? responsiblePerson,
  String? notes,
  int? order,
  String? address, 
  double? lat, 
  double? long
}) {
  return WeddingDayScheduleModel(
    id: id ?? this.id,
    title: title ?? this.title,
    // description: description ?? this.description,
    time: time ?? this.time,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderTime: reminderTime ?? this.reminderTime,
    userId: userId ?? this.userId,
    responsiblePerson: responsiblePerson ?? this.responsiblePerson,
    notes: notes ?? this.notes,
    order: order ?? this.order,
    address: address ?? this.address, 
    lat: lat ?? this.lat, 
    long: long ?? this.long
  );
}

  @override
  String toString() {
    return 'WeddingDayScheduleModel(id: $id, title: $title, time: $time, reminderEnabled: $reminderEnabled, responsiblePerson: $responsiblePerson, notes: $notes, reminderTime: $reminderTime, order: $order, userId: $userId)';
  }
}