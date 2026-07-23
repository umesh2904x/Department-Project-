import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../models/time_slot_model.dart';
import '../../models/timetable_entry_model.dart';
import '../../models/faculty_model.dart';
import '../../services/faculty_service.dart';
import '../../services/timetable_service.dart';

class FacultyAvailabilityScreen extends StatefulWidget {
  const FacultyAvailabilityScreen({super.key});

  @override
  State<FacultyAvailabilityScreen> createState() => _FacultyAvailabilityScreenState();
}

class _FacultyAvailabilityScreenState extends State<FacultyAvailabilityScreen> {
  String _selectedDay = 'Monday';
  List<TimetableEntry> _entries = [];
  List<FacultyMember> _facultyList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final allEntries = await TimetableService.getAllEntries();
    final faculty = await FacultyService.getAllFaculty();
    setState(() {
      _entries = allEntries.where((e) => e.day.toLowerCase() == _selectedDay.toLowerCase()).toList();
      _facultyList = faculty;
      _isLoading = false;
    });
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
                  'You do not have permission to access the Faculty Availability screen.',
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
        title: Text('Faculty Availability Grid', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter Panel
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.deepPurple.shade50,
                  child: Row(
                    children: [
                      // Day selector dropdown
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedDay,
                          decoration: InputDecoration(
                            labelText: 'Day',
                            labelStyle: GoogleFonts.poppins(color: Colors.deepPurple.shade900),
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: AppConstants.days.map((d) {
                            return DropdownMenuItem(value: d, child: Text(d, style: GoogleFonts.poppins()));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedDay = val);
                              _loadData();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Legend panel
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem('Available', Colors.green),
                          const SizedBox(height: 4),
                          _buildLegendItem('Teaching', Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),

                // Faculty list showing current availability per slot
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _facultyList.length,
                    itemBuilder: (context, index) {
                      final faculty = _facultyList[index];

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${faculty.name} (${faculty.designation})',
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  // 'On Leave' status removed from UI per request
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Slots Wrap grid
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: AppTimeSlots.teachingSlots.map((slot) {
                                  // Determine status: leave takes precedence, then active timetable entries
                                  bool isTeaching = false;
                                  String currentTeachingClass = '';

                                  if (!faculty.isOnLeave) {
                                    final match = _entries.firstWhere(
                                      (e) {
                                        if (e.facultyId != faculty.id) return false;
                                        if (e.isTheory) {
                                          return e.slotId == slot.id;
                                        } else {
                                          final pSlot = AppTimeSlots.practicalById(e.slotId);
                                          return pSlot != null && pSlot.coveredSlotIds.contains(slot.id);
                                        }
                                      },
                                      orElse: () => TimetableEntry(
                                        id: '', division: '', day: '', slotId: '', subjectName: '',
                                        facultyId: '', facultyName: '', roomNumber: '',
                                        entryType: EntryType.theory, createdAt: '', createdBy: '',
                                      ),
                                    );
                                    if (match.id.isNotEmpty) {
                                      isTeaching = true;
                                      currentTeachingClass = match.division;
                                    }
                                  }

                                  Color statusColorBg = Colors.green.shade100;
                                  Color statusColorBorder = Colors.green.shade300;
                                  Color statusColorText = Colors.green.shade900;
                                  String slotLabelSubtitle = 'Free';

                                  // Only show 'Teaching' status; treat other cases as available
                                  if (isTeaching) {
                                    statusColorBg = Colors.red.shade100;
                                    statusColorBorder = Colors.red.shade300;
                                    statusColorText = Colors.red.shade900;
                                    slotLabelSubtitle = currentTeachingClass;
                                  }

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColorBg,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: statusColorBorder),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          slot.label,
                                          style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: statusColorText),
                                        ),
                                        Text(
                                          slotLabelSubtitle,
                                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: statusColorText),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
// Small mapping trick to make it import AppConstants correctly
class AppConstants {
  static List<String> get days => [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
  ];
}
