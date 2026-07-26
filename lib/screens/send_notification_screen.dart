import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_input_field.dart';
import '../models/app_notification_model.dart';
import '../services/notification_service_local.dart';
import '../services/api_service.dart';
import '../utils/app_constants.dart';
import '../models/faculty_model.dart';
import '../services/faculty_service.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedTargetRole = 'class'; // admin: 'all'|'all_students'|'teachers'|'teacher'|'class'|'teacher_and_class'  teacher: 'class'|'teacher'|'teacher_and_class'
  String _selectedDivision = 'SE-A';
  String _selectedTeacherId = '';
  List<FacultyMember> _facultyList = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadFaculty();
    // Pre-select defaults based on current user role (set after first frame)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.user;
      if (user != null && user.role == 'teacher') {
        setState(() {
          _selectedTargetRole = 'class';
        });
      }
    });
  }

  void _loadFaculty() async {
    final list = await FacultyService.getAllFaculty();
    setState(() {
      _facultyList = list;
      if (_selectedTeacherId.isEmpty && list.isNotEmpty) {
        _selectedTeacherId = list.first.id;
      }
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

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Confirm Send'),
          content: const Text('Send this notification to the selected recipients?'),
          actions: [
            TextButton(
              key: const Key('cancelSendDialogButton'),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const Key('confirmSendDialogButton'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isSending = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    if (user != null) {
      // Create new local notification
      final String targetDivision;
      final String targetRole;

      if (_selectedTargetRole == 'class') {
        targetRole = 'student';
        targetDivision = _selectedDivision;
      } else if (_selectedTargetRole == 'teacher') {
        targetRole = 'teacher';
        targetDivision = _selectedTeacherId;
      } else if (_selectedTargetRole == 'teacher_and_class') {
        targetRole = 'teacher_and_class';
        targetDivision = '$_selectedDivision||$_selectedTeacherId';
      } else if (_selectedTargetRole == 'all_students') {
        targetRole = 'all_students';
        targetDivision = user.college?.trim() ?? 'CSE (Data Science) Department';
      } else if (_selectedTargetRole == 'teachers') {
        targetRole = 'teacher';
        targetDivision = 'all';
      } else {
        targetRole = 'all';
        targetDivision = 'all';
      }

      final notification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        targetRole: targetRole,
        targetDivision: targetDivision,
        senderId: user.id,
        senderName: user.name,
        senderRole: user.role,
        createdAt: DateTime.now().toString(),
      );

      // Persist locally immediately
      await NotificationServiceLocal.createNotification(notification);
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved locally. Sending in background...'), backgroundColor: Colors.green),
      );

      unawaited(ApiService.scheduleNotification(
        lectureId: '',
        title: title,
        message: message,
        notificationType: targetRole,
        className: (_selectedTargetRole == 'class' || _selectedTargetRole == 'teacher_and_class') ? _selectedDivision : '',
        section: '',
        college: (_selectedTargetRole == 'all_students' || _selectedTargetRole == 'all') ? targetDivision : null,
        scheduledAt: DateTime.now().toIso8601String(),
        targetDivision: targetDivision,
      ).then((apiResp) {
        if (apiResp['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification sent successfully!'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved locally. Server error: ${apiResp['message'] ?? 'unknown'}'), backgroundColor: Colors.orange),
          );
        }
      }).catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved locally. Failed to reach server.'), backgroundColor: Colors.orange),
        );
      }));

      if (Navigator.of(context).canPop()) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context);
        });
      }
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
    final isTeacher = user?.role == 'teacher';
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
                inputKey: const Key('notificationTitleField'),
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
                key: const Key('notificationMessageField'),
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter notification message here',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.message),
                ),
              ),
              const SizedBox(height: 20),

              // Target audience selection for admin and teachers
              if (isAdmin || isTeacher) ...[
                Text(
                  'Target Audience',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedTargetRole,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: (isAdmin)
                      ? const [
                          DropdownMenuItem(value: 'all', child: Text('All Users')),
                          DropdownMenuItem(value: 'all_students', child: Text('All Students')),
                          DropdownMenuItem(value: 'teachers', child: Text('All Teachers')),
                          DropdownMenuItem(value: 'teacher', child: Text('Specific Teacher')),
                          DropdownMenuItem(value: 'class', child: Text('Specific Class')),
                          DropdownMenuItem(value: 'teacher_and_class', child: Text('Specific Class & Teacher')),
                        ]
                      : const [
                          DropdownMenuItem(value: 'class', child: Text('Specific Class')),
                          DropdownMenuItem(value: 'teacher', child: Text('Specific Teacher')),
                          DropdownMenuItem(value: 'teacher_and_class', child: Text('Specific Class & Teacher')),
                        ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedTargetRole = val);
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Teacher selector (shown if admin or teacher selects specific teacher)
              if ((isAdmin || isTeacher) && (_selectedTargetRole == 'teacher' || _selectedTargetRole == 'teacher_and_class')) ...[
                Text(
                  'Select Target Teacher',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  key: ValueKey('teacher_select_${_facultyList.length}_$_selectedTeacherId'),
                  initialValue: _facultyList.isNotEmpty ? _selectedTeacherId : null,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _facultyList.isNotEmpty
                      ? _facultyList.map((f) {
                          return DropdownMenuItem(value: f.id, child: Text(f.name));
                        }).toList()
                      : [
                          const DropdownMenuItem(value: '', child: Text('No teachers available')),
                        ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedTeacherId = val);
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Division selector (shown if admin or teacher selects specific class or combined target)
              if ((isAdmin || isTeacher) && (_selectedTargetRole == 'class' || _selectedTargetRole == 'teacher_and_class')) ...[
                Text(
                  'Select Target Class',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDivision,
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
                  key: const Key('sendNotificationSubmit'),
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
