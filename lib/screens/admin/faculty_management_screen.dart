import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../models/faculty_model.dart';
import '../../services/faculty_service.dart';

class FacultyManagementScreen extends StatefulWidget {
  const FacultyManagementScreen({super.key});

  @override
  State<FacultyManagementScreen> createState() => _FacultyManagementScreenState();
}

class _FacultyManagementScreenState extends State<FacultyManagementScreen> {
  List<FacultyMember> _facultyList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFaculty();
  }

  Future<void> _loadFaculty() async {
    setState(() => _isLoading = true);
    final list = await FacultyService.getAllFaculty();
    setState(() {
      _facultyList = list;
      _isLoading = false;
    });
  }

  void _showEditFacultySheet(FacultyMember faculty) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditFacultySheet(
        faculty: faculty,
        onSaved: () {
          Navigator.pop(context);
          _loadFaculty();
        },
      ),
    );
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
                  'You do not have permission to access the Faculty Management screen.',
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

    final primaryColor = Colors.deepPurple.shade300;

    return Scaffold(
      appBar: AppBar(
        title: Text('Faculty Management', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _facultyList.length,
              itemBuilder: (context, index) {
                final f = _facultyList[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: f.isOnLeave ? Colors.grey.shade200 : Colors.deepPurple.shade50,
                      child: Icon(
                        f.name.contains('HOD') ? Icons.stars : Icons.person,
                        color: f.isOnLeave ? Colors.grey.shade600 : Colors.deepPurple.shade700,
                      ),
                    ),
                    title: Text(
                      f.name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: f.isOnLeave ? Colors.grey.shade600 : Colors.black87),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${f.designation} • ID: ${f.employeeId}', style: GoogleFonts.poppins(fontSize: 12)),
                        Text('Email: ${f.email}', style: GoogleFonts.poppins(fontSize: 12)),
                        if (f.isOnLeave)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '⛔ On Leave: ${f.leaveReason}',
                              style: GoogleFonts.poppins(color: Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.edit, color: Colors.deepPurple),
                    onTap: () => _showEditFacultySheet(f),
                  ),
                );
              },
            ),
    );
  }
}

class _EditFacultySheet extends StatefulWidget {
  final FacultyMember faculty;
  final VoidCallback onSaved;

  const _EditFacultySheet({required this.faculty, required this.onSaved});

  @override
  State<_EditFacultySheet> createState() => _EditFacultySheetState();
}

class _EditFacultySheetState extends State<_EditFacultySheet> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _designationController;
  late TextEditingController _subjectsController;
  late TextEditingController _maxLecturesDayController;
  late TextEditingController _maxLecturesWeekController;
  late TextEditingController _leaveReasonController;
  late bool _isOnLeave;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.faculty.name);
    _emailController = TextEditingController(text: widget.faculty.email);
    _phoneController = TextEditingController(text: widget.faculty.phone);
    _designationController = TextEditingController(text: widget.faculty.designation);
    _subjectsController = TextEditingController(text: widget.faculty.subjects.join(', '));
    _maxLecturesDayController = TextEditingController(text: widget.faculty.maxLecturesPerDay.toString());
    _maxLecturesWeekController = TextEditingController(text: widget.faculty.maxLecturesPerWeek.toString());
    _leaveReasonController = TextEditingController(text: widget.faculty.leaveReason);
    _isOnLeave = widget.faculty.isOnLeave;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    _subjectsController.dispose();
    _maxLecturesDayController.dispose();
    _maxLecturesWeekController.dispose();
    _leaveReasonController.dispose();
    super.dispose();
  }

  void _save() async {
    final updated = widget.faculty.copyWith(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      designation: _designationController.text.trim(),
      subjects: _subjectsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      maxLecturesPerDay: int.tryParse(_maxLecturesDayController.text) ?? widget.faculty.maxLecturesPerDay,
      maxLecturesPerWeek: int.tryParse(_maxLecturesWeekController.text) ?? widget.faculty.maxLecturesPerWeek,
      isOnLeave: _isOnLeave,
      leaveReason: _isOnLeave ? _leaveReasonController.text.trim() : '',
    );

    await FacultyService.updateFaculty(updated);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 16),
            Text(
              'Edit Faculty Member',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _designationController,
              decoration: const InputDecoration(labelText: 'Designation'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectsController,
              decoration: const InputDecoration(labelText: 'Subjects (comma separated)', hintText: 'e.g. Maths, Science'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _maxLecturesDayController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max Lectures/Day'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxLecturesWeekController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max Lectures/Week'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Leave management
            SwitchListTile(
              title: Text('On Leave status', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              subtitle: Text(_isOnLeave ? 'Marked as on leave' : 'Active and working'),
              value: _isOnLeave,
              onChanged: (val) {
                setState(() => _isOnLeave = val);
              },
              activeThumbColor: Colors.deepPurple,
            ),
            if (_isOnLeave) ...[
              TextField(
                controller: _leaveReasonController,
                decoration: const InputDecoration(labelText: 'Leave Reason / Details'),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Save Changes', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
