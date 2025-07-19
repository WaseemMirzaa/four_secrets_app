import 'package:cloud_firestore/cloud_firestore.dart';

class WeddingDayScheduleModel1 {
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

  // New fields
  final String dienstleistername;
  final String kontaktperson;
  final String telefonnummer;
  final String email;
  final String homepage;
  final String instagram;
  final String addressDetails;
  final String angebotText;
  final String angebotFileUrl;
  final String angebotFileName;
  final String zahlungsstatus;
  final DateTime? probetermin;

  WeddingDayScheduleModel1(
      {this.id,
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
      required this.long,
      // New fields
      this.dienstleistername = '',
      this.kontaktperson = '',
      this.telefonnummer = '',
      this.email = '',
      this.homepage = '',
      this.instagram = '',
      this.addressDetails = '',
      this.angebotText = '',
      this.angebotFileUrl = '',
      this.angebotFileName = '',
      this.zahlungsstatus = 'Unbezahlt',
      this.probetermin});

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      // 'description': description,
      'time': Timestamp.fromDate(time),
      'reminderEnabled': reminderEnabled,
      if (reminderTime != null) // Only add reminderTime if it's not null
        'reminderTime': Timestamp.fromDate(reminderTime!),
      'userId': userId,
      'responsiblePerson': responsiblePerson,
      'notes': notes,
      'order': order,
      'address': address,
      'lat': lat,
      'long': long,
      // New fields
      'dienstleistername': dienstleistername,
      'kontaktperson': kontaktperson,
      'telefonnummer': telefonnummer,
      'email': email,
      'homepage': homepage,
      'instagram': instagram,
      'addressDetails': addressDetails,
      'angebotText': angebotText,
      'angebotFileUrl': angebotFileUrl,
      'angebotFileName': angebotFileName,
      'zahlungsstatus': zahlungsstatus,
      if (probetermin != null) 'probetermin': Timestamp.fromDate(probetermin!),
    };
  }

  factory WeddingDayScheduleModel1.fromMap(Map<String, dynamic> map) {
    return WeddingDayScheduleModel1(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        // description: map['description'] ?? '',
        time: (map['time'] as Timestamp).toDate(),
        reminderEnabled: map['reminderEnabled'] ?? false,
        reminderTime: map['reminderTime'] != null
            ? (map['reminderTime'] as Timestamp).toDate()
            : null, // Handle null case
        userId: map['userId'] ?? '',
        responsiblePerson: map['responsiblePerson'] ?? '',
        notes: map['notes'] ?? '',
        order: map['order'] ?? 0,
        address: map['address'] ?? "No Address",
        lat: map['lat'] ?? 0.00,
        long: map['long'] ?? 0.00,
        // New fields
        dienstleistername: map['dienstleistername'] ?? '',
        kontaktperson: map['kontaktperson'] ?? '',
        telefonnummer: map['telefonnummer'] ?? '',
        email: map['email'] ?? '',
        homepage: map['homepage'] ?? '',
        instagram: map['instagram'] ?? '',
        addressDetails: map['addressDetails'] ?? '',
        angebotText: map['angebotText'] ?? '',
        angebotFileUrl: map['angebotFileUrl'] ?? '',
        angebotFileName: map['angebotFileName'] ?? '',
        zahlungsstatus: map['zahlungsstatus'] ?? 'Unbezahlt',
        probetermin: map['probetermin'] != null
            ? (map['probetermin'] as Timestamp).toDate()
            : null);
  }

  WeddingDayScheduleModel1 copyWith(
      {String? id,
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
      double? long,
      // New fields
      String? dienstleistername,
      String? kontaktperson,
      String? telefonnummer,
      String? email,
      String? homepage,
      String? instagram,
      String? addressDetails,
      String? angebotText,
      String? angebotFileUrl,
      String? angebotFileName,
      String? zahlungsstatus,
      DateTime? probetermin}) {
    return WeddingDayScheduleModel1(
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
        long: long ?? this.long,
        // New fields
        dienstleistername: dienstleistername ?? this.dienstleistername,
        kontaktperson: kontaktperson ?? this.kontaktperson,
        telefonnummer: telefonnummer ?? this.telefonnummer,
        email: email ?? this.email,
        homepage: homepage ?? this.homepage,
        instagram: instagram ?? this.instagram,
        addressDetails: addressDetails ?? this.addressDetails,
        angebotText: angebotText ?? this.angebotText,
        angebotFileUrl: angebotFileUrl ?? this.angebotFileUrl,
        angebotFileName: angebotFileName ?? this.angebotFileName,
        zahlungsstatus: zahlungsstatus ?? this.zahlungsstatus,
        probetermin: probetermin ?? this.probetermin);
  }

  @override
  String toString() {
    return 'WeddingDayScheduleModel1(id: $id, title: $title, time: $time, reminderEnabled: $reminderEnabled, responsiblePerson: $responsiblePerson, notes: $notes, reminderTime: $reminderTime, order: $order, userId: $userId)';
  }
}
