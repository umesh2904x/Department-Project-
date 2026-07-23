import 'dart:convert';

enum RoomType { classroom, lab }

enum RoomStatus { available, occupied, reserved, maintenance }

class Room {
  final String number;
  final RoomType type;
  final int capacity;
  bool isReserved;
  bool isMaintenance;
  String notes;

  Room({
    required this.number,
    required this.type,
    this.capacity = 60,
    this.isReserved = false,
    this.isMaintenance = false,
    this.notes = '',
  });

  bool get isLab => type == RoomType.lab;
  bool get isClassroom => type == RoomType.classroom;

  Map<String, dynamic> toJson() => {
        'number': number,
        'type': type.name,
        'capacity': capacity,
        'isReserved': isReserved,
        'isMaintenance': isMaintenance,
        'notes': notes,
      };

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        number: json['number'] ?? '',
        type: json['type'] == 'lab' ? RoomType.lab : RoomType.classroom,
        capacity: json['capacity'] ?? 60,
        isReserved: json['isReserved'] ?? false,
        isMaintenance: json['isMaintenance'] ?? false,
        notes: json['notes'] ?? '',
      );

  static Room fromJsonString(String s) => Room.fromJson(jsonDecode(s));
  String toJsonString() => jsonEncode(toJson());
}
