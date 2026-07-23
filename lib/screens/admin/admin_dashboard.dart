import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../services/faculty_service.dart';
import '../../services/timetable_service.dart';
import '../../services/notification_service_local.dart';
import '../../models/timetable_entry_model.dart';
import '../../models/faculty_model.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _activeRoomsCount = 0;
  int _totalLecturesToday = 0;
  int _facultyOnLeaveCount = 0;
  int _notificationsCount = 0;
  bool _isLoading = true;
  List<TimetableEntry> _todayLectures = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final today = _getCurrentDayName();
      final entries = await TimetableService.getAllEntries();
      final facultyList = await FacultyService.getAllFaculty();
      final notifications = await NotificationServiceLocal.getAllNotifications();

      // Today's lectures
      final todayEntries = entries.where((e) => e.day.toLowerCase() == today.toLowerCase()).toList();

      // Active rooms today
      final roomsUsed = todayEntries.map((e) => e.roomNumber).toSet();

      setState(() {
        _totalLecturesToday = todayEntries.length;
        _activeRoomsCount = roomsUsed.length;
        _facultyOnLeaveCount = facultyList.where((f) => f.isOnLeave).length;
        _notificationsCount = notifications.length;
        _todayLectures = todayEntries;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _getCurrentDayName() {
    final weekday = DateTime.now().weekday;
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      default: return 'Monday'; // Default to Monday if Sunday
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
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isLoggedIn || auth.user?.role != 'admin') {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gpp_bad, size: 80, color: Colors.redAccent),
                const SizedBox(height: 20),
                Text(
                  'Access Denied',
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'You do not have permission to access the Admin Panel.',
                  style: GoogleFonts.poppins(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  child: const Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Colors.deepPurple.shade300;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome message
                  Text(
                    'Welcome, Administrator',
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'CSE (Data Science) • Timetable & Academic Management',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // Metrics grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildMetricCard('Today\'s Lectures', '$_totalLecturesToday', Icons.book, Colors.blue),
                      _buildMetricCard('Rooms in Use', '$_activeRoomsCount', Icons.room, Colors.green),
                      _buildMetricCard('Faculty on Leave', '$_facultyOnLeaveCount', Icons.no_accounts, Colors.red),
                      _buildMetricCard('Notifications', '$_notificationsCount', Icons.notifications_active, Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick actions header
                  Text(
                    'Management Actions',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Action Buttons List
                  _buildActionRow([
                    _buildActionButton(context, 'Timetable Builder', Icons.calendar_month, '/admin/timetable_builder'),
                    _buildActionButton(context, 'Room Availability', Icons.grid_view, '/admin/room_availability'),
                  ]),
                  const SizedBox(height: 12),
                  _buildActionRow([
                    _buildActionButton(context, 'Faculty Availability', Icons.event_available, '/admin/faculty_availability'),
                    _buildActionButton(context, 'Faculty Records', Icons.people, '/admin/faculty_management'),
                  ]),
                  const SizedBox(height: 12),
                  _buildActionRow([
                    _buildActionButton(context, 'Send Notification', Icons.send, '/send_notification'),
                    _buildActionButton(context, 'View Notifications', Icons.notifications, '/notifications'),
                  ]),
                  const SizedBox(height: 24),

                  // Today's summary list
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Today\'s Schedule Summary (${_getCurrentDayName()})',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_todayLectures.length} total',
                        style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _todayLectures.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              'No lectures scheduled for today.',
                              style: GoogleFonts.poppins(color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _todayLectures.length,
                          itemBuilder: (context, index) {
                            final entry = _todayLectures[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: entry.isPractical ? Colors.orange.shade100 : Colors.deepPurple.shade100,
                                  child: Icon(
                                    entry.isPractical ? Icons.science : Icons.menu_book,
                                    color: entry.isPractical ? Colors.orange.shade800 : Colors.deepPurple.shade800,
                                  ),
                                ),
                                title: Text(
                                  '${entry.division} - ${entry.subjectName}',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Slot: ${entry.slotId} • Room: ${entry.roomNumber}\nFaculty: ${entry.facultyName} ${entry.batch.isNotEmpty ? "(${entry.batch})" : ""}',
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                                trailing: entry.isLocked
                                    ? const Icon(Icons.lock, color: Colors.amber, size: 20)
                                    : null,
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard(String title, String val, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  val,
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(List<Widget> children) {
    return Row(
      children: children.map((w) => Expanded(child: w)).toList(),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, String route) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(route).then((_) => _loadDashboardData()),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.deepPurple.shade200, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.deepPurple.shade800, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.deepPurple.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
