import 'package:cloud_firestore/cloud_firestore.dart';

class WeddingDayScheduleModel {
   String? id;
  final String title;
  final String description;
  final String responsiblePerson;
  final String notes;
  final DateTime time;
  final bool reminderEnabled;
  final DateTime reminderTime;
  final String userId;
  final int order;

  WeddingDayScheduleModel({
     this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.reminderEnabled,
    required this.reminderTime,
    required this.userId,
    required this.responsiblePerson,
    required this.notes,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      if(id != null)
      'id': id,
      'title': title,
      'description': description,
     'time': Timestamp.fromDate(time),
      'reminderEnabled': reminderEnabled,
      'reminderTime': Timestamp.fromDate(reminderTime),
      'userId': userId,
      'responsiblePerson': responsiblePerson,
      'notes': notes,
      'order': order,
    };
  }

  factory WeddingDayScheduleModel.fromMap(Map<String, dynamic> map) {
    return WeddingDayScheduleModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
     time: (map['time'] as Timestamp).toDate(),
      reminderEnabled: map['reminderEnabled'] ?? false,
     reminderTime: (map['reminderTime'] as Timestamp).toDate(),
      userId: map['userId'] ?? '',

      responsiblePerson: map['responsiblePerson'] ?? '',
      notes: map['notes'] ?? '',
      order: map['order'] ?? 0,
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
}) {
  return WeddingDayScheduleModel(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    time: time ?? this.time,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderTime: reminderTime ?? this.reminderTime,
    userId: userId ?? this.userId,
    responsiblePerson: responsiblePerson ?? this.responsiblePerson,
    notes: notes ?? this.notes,
    order: order ?? this.order,
  );
}


  @override
  String toString() {
    return 'WeddingDayScheduleModel(id: $id, title: $title, description: $description, time: $time, reminderEnabled: $reminderEnabled, responsiblePerson: $responsiblePerson, notes: $notes, reminderTime: $reminderTime, order: $order, userId: $userId)';
  }


}