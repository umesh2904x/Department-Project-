import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../models/app_notification_model.dart';
import '../services/notification_service_local.dart';

bool canDeleteNotification(String? role) {
  return role == 'admin' || role == 'teacher';
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
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    if (user != null) {
      final list = await NotificationServiceLocal.getNotificationsForUser(
        role: user.role,
        division: user.className ?? 'all',
        userId: user.id,
        department: user.college ?? 'all',
      );
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
      // Mark all read for this user
      await NotificationServiceLocal.markAllAsRead(
        user.role,
        user.className ?? 'all',
        userId: user.id,
        department: user.college ?? 'all',
      );
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _deleteNotification(String id) async {
    await NotificationServiceLocal.deleteNotification(id);
    _loadNotifications();
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
                          trailing: canDeleteNotification(currentRole)
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
