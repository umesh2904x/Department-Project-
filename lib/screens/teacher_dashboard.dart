import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../models/timetable_entry_model.dart';
import '../models/time_slot_model.dart';
import '../services/api_service.dart';
import '../models/app_notification_model.dart';
import '../services/timetable_service.dart';
import '../services/notification_service_local.dart';
import '../utils/app_constants.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  String _selectedDay = 'Monday';
  List<TimetableEntry> _myEntries = [];
  bool _isLoading = true;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadTeacherSchedule();
  }

  Future<void> _loadTeacherSchedule() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null) {
      final allEntries = await TimetableService.getAllEntries();
      
      List<AppNotification> apiNotifs = [];
      try {
        final data = await ApiService.getTeacherNotifications();
        apiNotifs = data.map((json) {
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
      } catch (_) {}

      final localNotifications = await NotificationServiceLocal.getNotificationsForUser(
        role: user.role,
        division: user.className ?? 'all',
        userId: user.id,
        department: user.college ?? 'all',
      );

      final combinedNotifications = apiNotifs.isNotEmpty ? apiNotifs : localNotifications;

      // Filter for this teacher specifically
      setState(() {
        _myEntries = allEntries.where((e) {
          final matchesFaculty = e.facultyId.trim().toLowerCase() == user.id.trim().toLowerCase() ||
                                e.facultyName.trim().toLowerCase() == user.name.trim().toLowerCase();
          final matchesDay = e.day.toLowerCase() == _selectedDay.toLowerCase();
          return matchesFaculty && matchesDay;
        }).toList();
        _unreadNotifications = combinedNotifications.where((n) => !n.isRead).length;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.isLoggedIn || authProvider.user?.role != 'teacher') {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = authProvider.user;
    final primaryColor = Colors.deepPurple.shade300;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Teacher Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadTeacherSchedule,
          ),
          IconButton(
            icon: const Icon(Icons.people, color: Colors.white),
            tooltip: 'Faculty Availability',
            onPressed: () {
              Navigator.of(context).pushNamed('/admin/faculty_availability');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Welcome header card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${user?.name ?? "Teacher"}',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${user?.id ?? "N/A"} • ${user?.email ?? ""}',
                        style: GoogleFonts.poppins(color: Colors.deepPurple.shade100, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      // Action buttons
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed('/send_notification');
                                  },
                                  icon: const Icon(Icons.send, size: 18),
                                  label: const Text('Send Notification'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: primaryColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed('/notifications');
                                  },
                                  icon: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      const Icon(Icons.notifications_active, size: 18, color: Colors.white),
                                      if (_unreadNotifications > 0)
                                        Positioned(
                                          right: -6,
                                          top: -6,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                          ),
                                        ),
                                    ],
                                  ),
                                  label: Text(
                                    _unreadNotifications > 0
                                        ? 'View Inbox ($_unreadNotifications)'
                                        : 'View Inbox',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.white),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pushNamed('/admin/room_availability');
                              },
                              icon: const Icon(Icons.grid_view, size: 18),
                              label: const Text('Room Availability'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                // Day Selection Panel
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: AppConstants.days.map((day) {
                        final isSelected = _selectedDay == day;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(day),
                            labelStyle: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : primaryColor,
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedDay = day);
                                _loadTeacherSchedule();
                              }
                            },
                            selectedColor: primaryColor,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Lecture Slots List
                Expanded(
                  child: _myEntries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today, size: 60, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'No lectures scheduled for $_selectedDay.',
                                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _myEntries.length,
                          itemBuilder: (context, index) {
                            final entry = _myEntries[index];

                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.only(bottom: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: entry.isPractical ? Colors.orange.shade200 : Colors.deepPurple.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: entry.isPractical ? Colors.orange.shade100 : Colors.deepPurple.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            entry.isPractical ? 'Practical Lab' : 'Theory Lecture',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: entry.isPractical ? Colors.orange.shade800 : Colors.deepPurple.shade800,
                                            ),
                                          ),
                                        ),
                                        if (entry.isLocked)
                                          const Icon(Icons.lock, color: Colors.amber, size: 18),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      entry.subjectName,
                                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Division: ${entry.division} ${entry.batch.isNotEmpty ? "(${entry.batch})" : ""}',
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                                    ),
                                    const Divider(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                            const SizedBox(width: 6),
                                            Builder(
                                              builder: (context) {
                                                String timeText = '';
                                                if (entry.isPractical) {
                                                  final pSlot = AppTimeSlots.practicalById(entry.slotId);
                                                  if (pSlot != null) {
                                                    timeText = '${pSlot.startTime}–${pSlot.endTime}';
                                                  }
                                                } else {
                                                  final slot = AppTimeSlots.slotById(entry.slotId);
                                                  if (slot != null) {
                                                    timeText = '${slot.startTime}–${slot.endTime}';
                                                  }
                                                }
                                                return Text(
                                                  'Time: $timeText',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade700,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.room, size: 16, color: Colors.grey),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Room: ${entry.roomNumber}',
                                              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}