import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../models/app_notification_model.dart';
import '../services/api_service.dart';
import '../services/notification_service_local.dart';

bool canDeleteNotification(String? userRole, AppNotification notif, {String userId = ''}) {
  if (userRole == 'admin') {
    return true; // Admin can delete anything
  }
  if (userRole == 'teacher') {
    // Teachers can only delete notifications they sent themselves
    return notif.senderRole == 'teacher' && notif.senderId == userId;
  }
  return false; // Students cannot delete any
}

int countUnreadNotifications(List<AppNotification> notifications) {
  return notifications.where((n) => !n.isRead).length;
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.user;

      if (user != null) {
        List<AppNotification> localList;
        try {
          localList = await NotificationServiceLocal.getNotificationsForUser(
            role: user.role,
            division: user.className ?? 'all',
            userId: user.id,
            department: user.college ?? 'all',
          );
        } catch (_) {
          localList = await NotificationServiceLocal.getAllNotifications();
        }

        setState(() {
          _notifications = localList;
        });

        // Fetch from server API in background (short timeout)
        try {
          List<AppNotification> apiNotifications = [];
          if (user.role == 'admin') {
            final data = await ApiService.getAllNotifications();
            apiNotifications = data.map((json) {
              final map = json as Map<String, dynamic>;
              return AppNotification(
                id: map['id'] ?? '',
                title: map['title'] ?? '',
                message: map['message'] ?? '',
                targetRole: map['notificationType'] ?? 'all',
                targetDivision: map['className'] ?? 'all',
                senderId: map['senderId'] ?? '',
                senderName: map['senderName'] ?? 'System',
                senderRole: map['senderRole'] ?? 'system',
                createdAt: map['createdAt'] ?? map['scheduledAt'] ?? '',
                isRead: map['isRead'] == 1 || map['isRead'] == true,
              );
            }).toList();
          } else if (user.role == 'student') {
            final data = await ApiService.getStudentNotifications();
            apiNotifications = data.map((json) {
              final map = json as Map<String, dynamic>;
              return AppNotification(
                id: map['id'] ?? '',
                title: map['title'] ?? '',
                message: map['message'] ?? '',
                targetRole: map['notificationType'] ?? 'student',
                targetDivision: map['className'] ?? 'all',
                senderId: map['senderId'] ?? '',
                senderName: map['senderName'] ?? 'System',
                senderRole: map['senderRole'] ?? 'system',
                createdAt: map['createdAt'] ?? map['scheduledAt'] ?? '',
                isRead: map['isRead'] == 1 || map['isRead'] == true,
              );
            }).toList();
          } else if (user.role == 'teacher') {
            final data = await ApiService.getTeacherNotifications();
            apiNotifications = data.map((json) {
              final map = json as Map<String, dynamic>;
              return AppNotification(
                id: map['id'] ?? '',
                title: map['title'] ?? '',
                message: map['message'] ?? '',
                targetRole: map['notificationType'] ?? 'teacher',
                targetDivision: map['className'] ?? 'all',
                senderId: map['senderId'] ?? '',
                senderName: map['senderName'] ?? 'System',
                senderRole: map['senderRole'] ?? 'system',
                createdAt: map['createdAt'] ?? map['scheduledAt'] ?? '',
                isRead: map['isRead'] == 1 || map['isRead'] == true,
              );
            }).toList();
          }

          if (apiNotifications.isNotEmpty) {
            final apiIds = apiNotifications.map((n) => n.id).toSet();
            setState(() {
              _notifications = [
                ...apiNotifications,
                ...localList.where((n) => !apiIds.contains(n.id)),
              ];
            });
          }
        } catch (_) {
          // API failed — local data already displayed
        }

        await NotificationServiceLocal.markAllAsRead(
          user.role,
          user.className ?? 'all',
          userId: user.id,
          department: user.college ?? 'all',
        );
      }
    } catch (_) {
      // ignore
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteNotification(String id) async {
    bool deletedOnServer = false;
    try {
      final res = await ApiService.deleteNotification(id);
      if (res['success'] == true) {
        deletedOnServer = true;
      } else {
        // If server says "not found", it's a local-only notification — still delete locally
        final msg = (res['message'] ?? '').toLowerCase();
        if (msg.contains('not found')) {
          deletedOnServer = true; // Nothing to delete on server
        }
      }
    } catch (_) {
      // Server unreachable — delete locally only
      deletedOnServer = true;
    }

    if (deletedOnServer) {
      await NotificationServiceLocal.deleteNotification(id);
      _loadNotifications();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete. Check connection.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.deepPurple.shade300;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentRole = auth.user?.role;
    final unreadCount = countUnreadNotifications(_notifications);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Row(
          children: [
            Text(
              'Notifications Inbox',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$unreadCount',
                  style: GoogleFonts.poppins(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 20),
                      Text(
                        'No notifications yet',
                        style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'You will see broadcast messages here.',
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];

                      return Card(
                        elevation: notif.isRead ? 0 : 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: notif.isRead ? Colors.grey.shade300 : Colors.deepPurple.shade300,
                            width: notif.isRead ? 0.5 : 2,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: notif.isRead ? Colors.grey.shade100 : Colors.deepPurple.shade50,
                            child: Icon(
                              Icons.notifications,
                              color: notif.isRead ? Colors.grey : Colors.deepPurple.shade700,
                            ),
                          ),
                          title: Text(
                            notif.title,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: notif.isRead ? Colors.grey.shade600 : Colors.black87,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text(
                                notif.message,
                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade800),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'From: ${notif.senderName}',
                                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    notif.createdAt.split(' ').first,
                                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: canDeleteNotification(currentRole, notif, userId: auth.user?.id ?? '')
                              ? IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () => _deleteNotification(notif.id),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
