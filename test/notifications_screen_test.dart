import 'package:flutter_test/flutter_test.dart';
import 'package:educational_timetable_app/models/app_notification_model.dart';
import 'package:educational_timetable_app/screens/notifications_screen.dart';

void main() {
  group('notification UI helpers', () {
    test('admins and teachers can delete notifications', () {
      expect(canDeleteNotification('admin'), isTrue);
      expect(canDeleteNotification('teacher'), isTrue);
      expect(canDeleteNotification('student'), isFalse);
      expect(canDeleteNotification(null), isFalse);
    });

    test('unread notification count is calculated correctly', () {
      final notifications = [
        AppNotification(
          id: '1',
          title: 'First',
          message: 'first message',
          targetRole: 'all',
          senderId: 's1',
          senderName: 'Admin',
          createdAt: '2026-07-23',
          isRead: false,
        ),
        AppNotification(
          id: '2',
          title: 'Second',
          message: 'second message',
          targetRole: 'all',
          senderId: 's1',
          senderName: 'Admin',
          createdAt: '2026-07-23',
          isRead: true,
        ),
        AppNotification(
          id: '3',
          title: 'Third',
          message: 'third message',
          targetRole: 'all',
          senderId: 's1',
          senderName: 'Admin',
          createdAt: '2026-07-23',
          isRead: false,
        ),
      ];

      expect(countUnreadNotifications(notifications), 2);
    });
  });
}
