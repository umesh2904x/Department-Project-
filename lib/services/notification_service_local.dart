import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification_model.dart';

class NotificationServiceLocal {
  static const String _key = 'app_notifications';

  /// Fetch all notifications
  static Future<List<AppNotification>> getAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key);
    if (data == null) return [];
    return data
        .map((item) => AppNotification.fromJson(jsonDecode(item)))
        .toList();
  }

  /// Save notifications list
  static Future<void> saveAllNotifications(List<AppNotification> list) async {
    final prefs = await SharedPreferences.getInstance();
    final data = list.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_key, data);
  }

  /// Create a notification
  static Future<void> createNotification(AppNotification notif) async {
    final list = await getAllNotifications();
    list.insert(0, notif); // Insert at beginning (newest first)
    await saveAllNotifications(list);
  }

  /// Delete a notification
  static Future<void> deleteNotification(String id) async {
    final list = await getAllNotifications();
    list.removeWhere((item) => item.id == id);
    await saveAllNotifications(list);
  }

  /// Mark all as read for a given target role/division
  static Future<void> markAllAsRead(String role, String division, {String userId = '', String department = 'all'}) async {
    String normalize(String s) => s.replaceAll('-', '').replaceAll('_', '').replaceAll(' ', '').toLowerCase();

    final list = await getAllNotifications();
    for (final notif in list) {
      if (notif.targetRole == 'all' || notif.targetRole == role) {
        notif.isRead = true;
      } else if (notif.targetRole == 'all_students' && role == 'student') {
        notif.isRead = true;
      } else if (notif.targetRole == 'department') {
        final normTarget = normalize(notif.targetDivision);
        final normDepartment = normalize(department);
        if (normTarget == 'all' || normTarget == normDepartment) {
          notif.isRead = true;
        }
      } else if (notif.targetRole == 'teacher_and_class') {
        final parts = notif.targetDivision.split('||');
        if (parts.length == 2) {
          final targetClass = parts[0].toLowerCase();
          final targetTeacherId = parts[1].toLowerCase();
          if (role == 'student' && division.toLowerCase() == targetClass) {
            notif.isRead = true;
          } else if (role == 'teacher' && userId.toLowerCase() == targetTeacherId) {
            notif.isRead = true;
          }
        }
      }
    }
    await saveAllNotifications(list);
  }

  /// Filter notifications for a specific user role/division
  static Future<List<AppNotification>> getNotificationsForUser({
    required String role,
    String division = 'all',
    String userId = '',
    String department = 'all',
  }) async {
    final all = await getAllNotifications();
    if (role == 'admin') {
      return all; // Admins see everything
    }

    String normalize(String s) => s.replaceAll('-', '').replaceAll('_', '').replaceAll(' ', '').toLowerCase();
    final normDivision = normalize(division);

    return all.where((notif) {
      // Rule 1: targetRole is 'all' (admin broadcast to everyone)
      if (notif.targetRole == 'all') return true;

      // Rule 2: targetRole is 'all_students' (admin broadcast to all students)
      if (notif.targetRole == 'all_students' && role == 'student') return true;

      if (notif.targetRole == 'department') {
        final normTarget = normalize(notif.targetDivision);
        final normDepartment = normalize(department);
        return normTarget == 'all' || normTarget == normDepartment;
      }

      // Rule 3: matches exact role
      if (notif.targetRole == role) {
        // If it's a student, check division or exact student ID
        if (role == 'student') {
          final normTarget = normalize(notif.targetDivision);
          final normUserId = normalize(userId);
          return normTarget == 'all' || normTarget == normDivision || normTarget == normUserId;
        }
        // If it's a teacher, check specific teacher ID
        if (role == 'teacher') {
          final normTarget = notif.targetDivision.toLowerCase();
          return normTarget == 'all' || normTarget == userId.toLowerCase();
        }
        // Department notifications can still match all users, so allow by default for any other role logic
        return true;
      }

      // Rule 4: combined class + teacher notifications
      if (notif.targetRole == 'teacher_and_class') {
        final parts = notif.targetDivision.split('||');
        if (parts.length != 2) return false;
        final targetClass = normalize(parts[0]);
        final targetTeacherId = parts[1].toLowerCase();

        if (role == 'student') {
          return targetClass == normDivision;
        }
        if (role == 'teacher') {
          return targetTeacherId == userId.toLowerCase();
        }
      }

      return false;
    }).toList();
  }
}
