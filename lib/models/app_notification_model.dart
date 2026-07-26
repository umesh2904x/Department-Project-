import 'dart:convert';

/// Represents a notification inside the app sent by Admin or Teacher.
class AppNotification {
  final String id;
  final String title;
  final String message;
  final String targetRole; // 'all' | 'student' | 'teacher' | 'department'
  final String targetDivision; // e.g. 'SE-A', department name, or 'all'
  final String senderId;
  final String senderName;
  final String senderRole; // 'admin' | 'teacher' | 'system'
  final String createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.targetRole,
    this.targetDivision = 'all',
    required this.senderId,
    required this.senderName,
    this.senderRole = 'system',
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': message, // Oops, keep this standard or mapping correctly
        'titleField': title, // Let's keep it direct
        'message': message,
        'targetRole': targetRole,
        'targetDivision': targetDivision,
        'senderId': senderId,
        'senderName': senderName,
        'senderRole': senderRole,
        'createdAt': createdAt,
        'isRead': isRead,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] ?? '',
        title: json['titleField'] ?? json['title'] ?? '',
        message: json['message'] ?? '',
        targetRole: json['targetRole'] ?? 'all',
        targetDivision: json['targetDivision'] ?? 'all',
        senderId: json['senderId'] ?? '',
        senderName: json['senderName'] ?? '',
        senderRole: json['senderRole'] ?? 'system',
        createdAt: json['createdAt'] ?? '',
        isRead: json['isRead'] ?? false,
      );

  static AppNotification fromJsonString(String s) =>
      AppNotification.fromJson(jsonDecode(s));

  String toJsonString() => jsonEncode(toJson());
}
