import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_input_field.dart';
import '../models/app_notification_model.dart';
import '../services/notification_service_local.dart';
import '../utils/app_constants.dart';
import '../models/faculty_model.dart';
import '../services/faculty_service.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({Key? key}) : super(key: key);

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedTargetRole = 'student'; // 'all', 'teacher', 'student'
  String _selectedDivision = 'SE-A';
  String _selectedTeacherId = 'all';
  List<FacultyMember> _facultyList = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadFaculty();
  }

  void _loadFaculty() async {
    final list = await FacultyService.getAllFaculty();
    setState(() {
      _facultyList = list;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendNotification() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isSending = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    if (user != null) {
      // Create new local notification
      final String targetDivision;
      if (_selectedTargetRole == 'student') {
        targetDivision = _selectedDivision;
      } else if (_selectedTargetRole == 'teacher') {
        targetDivision = _selectedTeacherId;
      } else {
        targetDivision = 'all';
      }

      final notification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        targetRole: _selectedTargetRole,
        targetDivision: targetDivision,
        senderId: user.id,
        senderName: user.name,
        createdAt: DateTime.now().toString(),
      );

      await NotificationServiceLocal.createNotification(notification);

      setState(() => _isSending = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification sent successfully!'), backgroundColor: Colors.green),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context);
      });
    } else {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isLoggedIn || (auth.user?.role != 'admin' && auth.user?.role != 'teacher')) {
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
                  'You do not have permission to send notifications.',
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

    final user = auth.user;
    final isAdmin = user?.role == 'admin';
    final primaryColor = Colors.deepPurple.shade300;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          'Send Notification',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Broadcast Details',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Title input
              CustomInputField(
                label: 'Notification Title',
                hint: 'e.g., Exam Schedule Published, Holiday Announcement',
                controller: _titleController,
                prefixIcon: Icons.title,
              ),
              const SizedBox(height: 16),

              // Message input
              Text(
                'Message',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter notification message here',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.message),
                ),
              ),
              const SizedBox(height: 20),

              // Target audience selection
              if (isAdmin) ...[
                Text(
                  'Target Audience',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedTargetRole,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Users')),
                    DropdownMenuItem(value: 'teacher', child: Text('All Teachers')),
                    DropdownMenuItem(value: 'student', child: Text('Student Division')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedTargetRole = val);
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Teacher selector (shown if admin selects teacher target audience)
              if (isAdmin && _selectedTargetRole == 'teacher') ...[
                Text(
                  'Select Target Teacher',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedTeacherId,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All Teachers')),
                    ..._facultyList.map((f) {
                      return DropdownMenuItem(value: f.id, child: Text(f.name));
                    }),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedTeacherId = val);
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Division selector (shown for teachers, or if admin selects students)
              if (!isAdmin || _selectedTargetRole == 'student') ...[
                Text(
                  'Select Student Division',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedDivision,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: AppConstants.divisions.map((d) {
                    return DropdownMenuItem(value: d, child: Text(d));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedDivision = val);
                  },
                ),
                const SizedBox(height: 20),
              ],

              const SizedBox(height: 20),
              // Send Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendNotification,
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: _isSending
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          'Send Notification',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
