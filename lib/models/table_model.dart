class TableModel {
  final String id;
  final String nameOrNumber;
  final String tableType;
  final int maxGuests;
  final List<String> assignedGuestIds; // Store guest IDs assigned to this table

  TableModel({
    required this.id,
    required this.nameOrNumber,
    required this.tableType,
    required this.maxGuests,
    List<String>? assignedGuestIds,
  }) : assignedGuestIds = assignedGuestIds ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameOrNumber': nameOrNumber,
      'tableType': tableType,
      'maxGuests': maxGuests,
      'assignedGuestIds': assignedGuestIds,
    };
  }

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'],
      nameOrNumber: json['nameOrNumber'],
      tableType: json['tableType'],
      maxGuests: json['maxGuests'],
      assignedGuestIds: List<String>.from(json['assignedGuestIds'] ?? []),
    );
  }
}