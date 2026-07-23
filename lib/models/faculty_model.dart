import 'dart:convert';

/// Represents one faculty member. Records are editable by Admin.
class FacultyMember {
  final String id;           // e.g. FAC001
  String name;
  String employeeId;
  String designation;        // e.g. "Professor", "HOD"
  List<String> subjects;
  int maxLecturesPerDay;
  int maxLecturesPerWeek;
  List<String> availableTimings; // slot IDs e.g. ['S1','S2','S3'...]
  List<String> preferredRooms;
  String email;
  String phone;
  bool isOnLeave;
  String leaveReason;

  FacultyMember({
    required this.id,
    required this.name,
    required this.employeeId,
    this.designation = 'Professor',
    List<String>? subjects,
    this.maxLecturesPerDay = 4,
    this.maxLecturesPerWeek = 20,
    List<String>? availableTimings,
    List<String>? preferredRooms,
    this.email = '',
    this.phone = '',
    this.isOnLeave = false,
    this.leaveReason = '',
  })  : subjects = subjects ?? [],
        availableTimings = availableTimings ?? ['S1','S2','S3','S4','S5','S6','S7','S8'],
        preferredRooms = preferredRooms ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'employeeId': employeeId,
        'designation': designation,
        'subjects': subjects,
        'maxLecturesPerDay': maxLecturesPerDay,
        'maxLecturesPerWeek': maxLecturesPerWeek,
        'availableTimings': availableTimings,
        'preferredRooms': preferredRooms,
        'email': email,
        'phone': phone,
        'isOnLeave': isOnLeave,
        'leaveReason': leaveReason,
      };

  factory FacultyMember.fromJson(Map<String, dynamic> json) => FacultyMember(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        employeeId: json['employeeId'] ?? '',
        designation: json['designation'] ?? 'Professor',
        subjects: List<String>.from(json['subjects'] ?? []),
        maxLecturesPerDay: json['maxLecturesPerDay'] ?? 4,
        maxLecturesPerWeek: json['maxLecturesPerWeek'] ?? 20,
        availableTimings: List<String>.from(
            json['availableTimings'] ?? ['S1','S2','S3','S4','S5','S6','S7','S8']),
        preferredRooms: List<String>.from(json['preferredRooms'] ?? []),
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        isOnLeave: json['isOnLeave'] ?? false,
        leaveReason: json['leaveReason'] ?? '',
      );

  static FacultyMember fromJsonString(String s) =>
      FacultyMember.fromJson(jsonDecode(s));

  String toJsonString() => jsonEncode(toJson());

  FacultyMember copyWith({
    String? name,
    String? employeeId,
    String? designation,
    List<String>? subjects,
    int? maxLecturesPerDay,
    int? maxLecturesPerWeek,
    List<String>? availableTimings,
    List<String>? preferredRooms,
    String? email,
    String? phone,
    bool? isOnLeave,
    String? leaveReason,
  }) => FacultyMember(
        id: id,
        name: name ?? this.name,
        employeeId: employeeId ?? this.employeeId,
        designation: designation ?? this.designation,
        subjects: subjects ?? this.subjects,
        maxLecturesPerDay: maxLecturesPerDay ?? this.maxLecturesPerDay,
        maxLecturesPerWeek: maxLecturesPerWeek ?? this.maxLecturesPerWeek,
        availableTimings: availableTimings ?? this.availableTimings,
        preferredRooms: preferredRooms ?? this.preferredRooms,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        isOnLeave: isOnLeave ?? this.isOnLeave,
        leaveReason: leaveReason ?? this.leaveReason,
      );
}
