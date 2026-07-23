import 'dart:convert';

enum EntryType { theory, practical }

/// A single scheduled entry in the department timetable.
class TimetableEntry {
  final String id;
  final String division;   // e.g. 'SE-A'
  final String batch;      // '' for theory, 'Batch 1' / 'Batch 2' / 'Batch 3' for practicals
  final String day;        // 'Monday' … 'Saturday'
  final String slotId;     // For theory: single slot 'S1'…'S8'. For practical: practical slot 'P1'…'P5'
  final String subjectName;
  final String facultyId;  // 'FAC001' … 'FAC017'
  final String facultyName;
  final String roomNumber;
  final EntryType entryType;
  bool isLocked;
  final String createdAt;
  final String createdBy; // username of admin who created

  TimetableEntry({
    required this.id,
    required this.division,
    this.batch = '',
    required this.day,
    required this.slotId,
    required this.subjectName,
    required this.facultyId,
    required this.facultyName,
    required this.roomNumber,
    required this.entryType,
    this.isLocked = false,
    required this.createdAt,
    required this.createdBy,
  });

  bool get isTheory => entryType == EntryType.theory;
  bool get isPractical => entryType == EntryType.practical;

  Map<String, dynamic> toJson() => {
        'id': id,
        'division': division,
        'batch': batch,
        'day': day,
        'slotId': slotId,
        'subjectName': subjectName,
        'facultyId': facultyId,
        'facultyName': facultyName,
        'roomNumber': roomNumber,
        'entryType': entryType.name,
        'isLocked': isLocked,
        'createdAt': createdAt,
        'createdBy': createdBy,
      };

  factory TimetableEntry.fromJson(Map<String, dynamic> json) => TimetableEntry(
        id: json['id'] ?? '',
        division: json['division'] ?? '',
        batch: json['batch'] ?? '',
        day: json['day'] ?? '',
        slotId: json['slotId'] ?? '',
        subjectName: json['subjectName'] ?? '',
        facultyId: json['facultyId'] ?? '',
        facultyName: json['facultyName'] ?? '',
        roomNumber: json['roomNumber'] ?? '',
        entryType: json['entryType'] == 'practical'
            ? EntryType.practical
            : EntryType.theory,
        isLocked: json['isLocked'] ?? false,
        createdAt: json['createdAt'] ?? '',
        createdBy: json['createdBy'] ?? '',
      );

  static TimetableEntry fromJsonString(String s) =>
      TimetableEntry.fromJson(jsonDecode(s));

  String toJsonString() => jsonEncode(toJson());

  TimetableEntry copyWith({
    String? subjectName,
    String? facultyId,
    String? facultyName,
    String? roomNumber,
    bool? isLocked,
  }) =>
      TimetableEntry(
        id: id,
        division: division,
        batch: batch,
        day: day,
        slotId: slotId,
        subjectName: subjectName ?? this.subjectName,
        facultyId: facultyId ?? this.facultyId,
        facultyName: facultyName ?? this.facultyName,
        roomNumber: roomNumber ?? this.roomNumber,
        entryType: entryType,
        isLocked: isLocked ?? this.isLocked,
        createdAt: createdAt,
        createdBy: createdBy,
      );
}
