import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/lecture_provider.dart';
import '../models/timetable_entry_model.dart';
import '../models/time_slot_model.dart';
import '../services/timetable_service.dart';
import '../services/notification_service_local.dart';
import '../utils/app_constants.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  String _selectedDay = 'Monday';
  List<TimetableEntry> _classEntries = [];
  bool _isLoading = true;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadStudentSchedule();
  }

  Future<void> _loadStudentSchedule() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null) {
      // Fetch from server API
      final lectureProvider = Provider.of<LectureProvider>(context, listen: false);
      try {
        await lectureProvider.getTimetable(user.className ?? '');
      } catch (_) {}

      // Convert API timetable entries to display format
      final apiEntries = lectureProvider.timetableEntries;
      final displayEntries = apiEntries.map((t) => TimetableEntry(
        id: t.id,
        division: t.section.isNotEmpty ? '${t.className}-${t.section}' : t.className,
        day: t.day,
        slotId: '',
        subjectName: t.subjectName,
        facultyId: '',
        facultyName: t.teacherName,
        roomNumber: t.roomNumber,
        entryType: EntryType.theory,
        createdAt: t.createdAt,
        createdBy: 'server',
      )).toList();

      // Also get local entries for fallback
      final localEntries = await TimetableService.getAllEntries();

      final notifications = await NotificationServiceLocal.getNotificationsForUser(
        role: user.role,
        division: user.className ?? 'all',
        userId: user.id,
        department: user.college ?? 'all',
      );

      String normalize(String s) => s.replaceAll('-', '').replaceAll('_', '').replaceAll(' ', '').toLowerCase();
      final normClass = normalize(user.className ?? '');
      setState(() {
        _classEntries = [...displayEntries, ...localEntries].where((e) {
          final matchesClass = normalize(e.division) == normClass;
          final matchesDay = e.day.toLowerCase() == _selectedDay.toLowerCase();
          return matchesClass && matchesDay;
        }).toList();
        _unreadNotifications = notifications.where((n) => !n.isRead).length;
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
    if (!authProvider.isLoggedIn || authProvider.user?.role != 'student') {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = authProvider.user;
    final primaryColor = Colors.deepPurple.shade300;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Student Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadStudentSchedule,
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
                // Student info header card
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
                        'Class Account: ${user?.name ?? "Student"}',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Department: CSE (Data Science) • Division: ${user?.className ?? ""}',
                        style: GoogleFonts.poppins(color: Colors.deepPurple.shade100, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      // View Notifications
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/notifications');
                          },
                          icon: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.notifications, size: 20),
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
                                ? 'View Class Notifications & Reminders ($_unreadNotifications)'
                                : 'View Class Notifications & Reminders',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Day Selection Chips
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
                                _loadStudentSchedule();
                              }
                            },
                            selectedColor: primaryColor,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Timetable list
                Expanded(
                  child: _classEntries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today, size: 60, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'No lectures scheduled for $_selectedDay.',
                                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 15),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _classEntries.length,
                          itemBuilder: (context, index) {
                            final entry = _classEntries[index];

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
                                            entry.isPractical
                                                ? 'Practical (${entry.batch})'
                                                : 'Theory Lecture',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: entry.isPractical ? Colors.orange.shade800 : Colors.deepPurple.shade800,
                                            ),
                                          ),
                                        ),
                                        if (entry.isLocked)
                                          const Icon(Icons.lock, color: Colors.amber, size: 16),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      entry.subjectName,
                                      style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Faculty: ${entry.facultyName}',
                                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
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
