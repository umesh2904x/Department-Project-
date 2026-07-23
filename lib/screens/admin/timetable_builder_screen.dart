import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_constants.dart';
import '../../models/time_slot_model.dart';
import '../../models/timetable_entry_model.dart';
import '../../models/faculty_model.dart';
import '../../services/faculty_service.dart';
import '../../services/timetable_service.dart';

class TimetableBuilderScreen extends StatefulWidget {
  const TimetableBuilderScreen({super.key});

  @override
  State<TimetableBuilderScreen> createState() => _TimetableBuilderScreenState();
}

class _TimetableBuilderScreenState extends State<TimetableBuilderScreen> {
  String _selectedDivision = 'SE-A';
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
      _entries = allEntries
          .where((e) =>
              e.division == _selectedDivision &&
              e.day.toLowerCase() == _selectedDay.toLowerCase())
          .toList();
      _facultyList = faculty;
      _isLoading = false;
    });
  }

  void _deleteEntry(String id) async {
    final success = await TimetableService.deleteEntry(id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry removed successfully'), backgroundColor: Colors.green),
      );
      _loadData();
    }
  }

  void _toggleLock(TimetableEntry entry) async {
    await TimetableService.setLockedStatus(entry.id, !entry.isLocked);
    _loadData();
  }

  void _showAddEntrySheet(String slotId, {bool isPractical = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEntrySheet(
        division: _selectedDivision,
        day: _selectedDay,
        preselectedSlotId: slotId,
        isPractical: isPractical,
        facultyList: _facultyList,
        onSaved: () {
          Navigator.pop(context);
          _loadData();
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
                  'You do not have permission to access the Timetable Builder.',
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
        title: Text('Timetable Builder', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filters Header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.deepPurple.shade50,
                  child: Row(
                    children: [
                      // Division Selector
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedDivision,
                          decoration: InputDecoration(
                            labelText: 'Division',
                            labelStyle: GoogleFonts.poppins(color: Colors.deepPurple.shade900),
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: AppConstants.divisions.map((d) {
                            return DropdownMenuItem(value: d, child: Text(d, style: GoogleFonts.poppins()));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedDivision = val);
                              _loadData();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Day Selector
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedDay,
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
                    ],
                  ),
                ),

                // Main Slots List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: AppTimeSlots.slots.length,
                    itemBuilder: (context, index) {
                      final slot = AppTimeSlots.slots[index];

                      if (slot.isBreak) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '☕ ${slot.label} (${slot.startTime}–${slot.endTime})',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        );
                      }

                      // Find entries in this slot
                      // For practical entries, they might map to a practical slot covering multiple regular slots.
                      final matchingEntries = _entries.where((e) {
                        if (e.isTheory) {
                          return e.slotId == slot.id;
                        } else {
                          final pSlot = AppTimeSlots.practicalById(e.slotId);
                          return pSlot != null && pSlot.coveredSlotIds.contains(slot.id);
                        }
                      }).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, top: 12, bottom: 4),
                            child: Text(
                              '${slot.label} (${slot.startTime}–${slot.endTime})',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple.shade800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          // Render existing entries first
                          if (matchingEntries.isNotEmpty)
                            ...matchingEntries.map((entry) {
                              return Card(
                                color: entry.isPractical ? Colors.orange.shade50 : Colors.deepPurple.shade50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: entry.isPractical ? Colors.orange.shade200 : Colors.deepPurple.shade200,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: Icon(
                                    entry.isPractical ? Icons.science : Icons.menu_book,
                                    color: entry.isPractical ? Colors.orange.shade800 : Colors.deepPurple.shade800,
                                    size: 28,
                                  ),
                                  title: Text(
                                    entry.subjectName,
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  subtitle: Text(
                                    'Room: ${entry.roomNumber} • ${entry.facultyName}\nType: ${entry.isPractical ? "Practical (${entry.batch})" : "Theory"}',
                                    style: GoogleFonts.poppins(fontSize: 12),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          entry.isLocked ? Icons.lock : Icons.lock_open,
                                          color: entry.isLocked ? Colors.amber.shade700 : Colors.grey,
                                        ),
                                        onPressed: () => _toggleLock(entry),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                                        onPressed: entry.isLocked
                                            ? null
                                            : () => _deleteEntry(entry.id),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),

                          // Show addition buttons if applicable
                          Builder(
                            builder: (context) {
                              final hasTheory = matchingEntries.any((e) => e.isTheory);
                              final scheduledBatches = matchingEntries.map((e) => e.batch).toList();
                              final hasAllBatches = scheduledBatches.contains('Batch 1') &&
                                                    scheduledBatches.contains('Batch 2') &&
                                                    scheduledBatches.contains('Batch 3');

                              if (matchingEntries.isEmpty) {
                                return Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _showAddEntrySheet(slot.id, isPractical: false),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Add Theory Lecture'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.deepPurple.shade700,
                                          side: BorderSide(color: Colors.deepPurple.shade200),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _showAddEntrySheet(slot.id, isPractical: true),
                                        icon: const Icon(Icons.science),
                                        label: const Text('Add Practical Lab'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.orange.shade800,
                                          side: BorderSide(color: Colors.orange.shade200),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              } else if (!hasTheory && !hasAllBatches) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showAddEntrySheet(slot.id, isPractical: true),
                                      icon: const Icon(Icons.science),
                                      label: const Text('Add Practical Lab (Next Batch)'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.orange.shade800,
                                        side: BorderSide(color: Colors.orange.shade200),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// Bottom sheet class to add a timetable entry
class _AddEntrySheet extends StatefulWidget {
  final String division;
  final String day;
  final String preselectedSlotId;
  final bool isPractical;
  final List<FacultyMember> facultyList;
  final VoidCallback onSaved;

  const _AddEntrySheet({
    required this.division,
    required this.day,
    required this.preselectedSlotId,
    required this.isPractical,
    required this.facultyList,
    required this.onSaved,
  });

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  final _subjectController = TextEditingController();
  String? _selectedFacultyId;
  String? _selectedRoom;
  String? _selectedSlotId; // Can be single S1..S8 or practical P1..P5
  String _selectedBatch = 'Batch 1';
  List<String> _availableBatches = ['Batch 1', 'Batch 2', 'Batch 3'];
  List<String> _validationErrors = [];
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    // Default slot assignment
    if (widget.isPractical) {
      // Find a practical slot that starts with or contains preselectedSlotId
      final match = AppTimeSlots.practicalSlots.firstWhere(
        (p) => p.startSlotId == widget.preselectedSlotId || p.endSlotId == widget.preselectedSlotId,
        orElse: () => AppTimeSlots.practicalSlots.first,
      );
      _selectedSlotId = match.id;
    } else {
      _selectedSlotId = widget.preselectedSlotId;
    }
    _loadAvailableBatches();
  }

  void _loadAvailableBatches() async {
    final all = await TimetableService.getAllEntries();
    final matches = all.where((e) {
      if (e.division != widget.division || e.day.toLowerCase() != widget.day.toLowerCase()) return false;
      
      final currentId = _selectedSlotId ?? widget.preselectedSlotId;
      List<String> currentSlots = [];
      if (widget.isPractical) {
        final pSlot = AppTimeSlots.practicalById(currentId);
        if (pSlot != null) {
          currentSlots = pSlot.coveredSlotIds;
        }
      } else {
        currentSlots = [currentId];
      }

      List<String> existingSlots = [];
      if (e.isPractical) {
        final pSlot = AppTimeSlots.practicalById(e.slotId);
        if (pSlot != null) {
          existingSlots = pSlot.coveredSlotIds;
        }
      } else {
        existingSlots = [e.slotId];
      }
      return currentSlots.any((s) => existingSlots.contains(s));
    }).toList();

    final takenBatches = matches.map((e) => e.batch).where((b) => b.isNotEmpty).toList();
    if (mounted) {
      setState(() {
        _availableBatches = ['Batch 1', 'Batch 2', 'Batch 3']
            .where((b) => !takenBatches.contains(b))
            .toList();
        if (_availableBatches.isNotEmpty && !_availableBatches.contains(_selectedBatch)) {
          _selectedBatch = _availableBatches.first;
        }
      });
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  void _validateAndSave() async {
    if (_subjectController.text.trim().isEmpty || _selectedFacultyId == null || _selectedRoom == null || _selectedSlotId == null) {
      setState(() {
        _validationErrors = ['Please fill all fields.'];
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _validationErrors = [];
    });

    final faculty = widget.facultyList.firstWhere((f) => f.id == _selectedFacultyId);

    final entry = TimetableEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      division: widget.division,
      batch: widget.isPractical ? _selectedBatch : '',
      day: widget.day,
      slotId: _selectedSlotId!,
      subjectName: _subjectController.text.trim(),
      facultyId: _selectedFacultyId!,
      facultyName: faculty.name,
      roomNumber: _selectedRoom!,
      entryType: widget.isPractical ? EntryType.practical : EntryType.theory,
      createdAt: DateTime.now().toString(),
      createdBy: 'admin',
    );

    // Call service validator
    final errors = await TimetableService.validateEntry(entry);

    if (errors.isNotEmpty) {
      setState(() {
        _validationErrors = errors;
        _isValidating = false;
      });
    } else {
      await TimetableService.addEntry(entry);
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = widget.isPractical ? Colors.orange.shade800 : Colors.deepPurple.shade300;

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
              'Add ${widget.isPractical ? "Practical Lab" : "Theory Lecture"}',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Subject name field
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: 'Subject / Course Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),

            // Faculty list Dropdown
            DropdownButtonFormField<String>(
              value: _selectedFacultyId,
              decoration: InputDecoration(
                labelText: 'Faculty Member',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: widget.facultyList.map((f) {
                return DropdownMenuItem(
                  value: f.id,
                  child: Text('${f.name} (${f.designation})', style: GoogleFonts.poppins(fontSize: 13)),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedFacultyId = val),
            ),
            const SizedBox(height: 12),

            // Room / Lab list Dropdown
            DropdownButtonFormField<String>(
              value: _selectedRoom,
              decoration: InputDecoration(
                labelText: widget.isPractical ? 'Laboratory' : 'Classroom',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: (widget.isPractical ? AppConstants.labs : AppConstants.classrooms).map((r) {
                return DropdownMenuItem(
                  value: r,
                  child: Text('Room $r', style: GoogleFonts.poppins()),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedRoom = val),
            ),
            const SizedBox(height: 12),

            // Practical batch selector
            if (widget.isPractical) ...[
              DropdownButtonFormField<String>(
                value: _availableBatches.contains(_selectedBatch)
                    ? _selectedBatch
                    : (_availableBatches.isNotEmpty ? _availableBatches.first : null),
                decoration: InputDecoration(
                  labelText: 'Practical Batch',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _availableBatches.map((b) {
                  return DropdownMenuItem(value: b, child: Text(b, style: GoogleFonts.poppins()));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBatch = val);
                },
              ),
              const SizedBox(height: 12),
              // Practical slot selector
              DropdownButtonFormField<String>(
                value: _selectedSlotId,
                decoration: InputDecoration(
                  labelText: 'Practical Continuous Slots',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: AppTimeSlots.practicalSlots.map((p) {
                  return DropdownMenuItem(
                    value: p.id,
                    child: Text('${p.label} (Slots: ${p.startSlotId}+${p.endSlotId})', style: GoogleFonts.poppins()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedSlotId = val);
                    _loadAvailableBatches();
                  }
                },
              ),
            ] else ...[
              // Theory slot selector
              DropdownButtonFormField<String>(
                value: _selectedSlotId,
                decoration: InputDecoration(
                  labelText: 'Time Slot',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: AppTimeSlots.teachingSlots.map((s) {
                  return DropdownMenuItem(
                    value: s.id,
                    child: Text('${s.label} (${s.startTime}–${s.endTime})', style: GoogleFonts.poppins()),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedSlotId = val),
              ),
            ],
            const SizedBox(height: 16),

            // Errors container
            if (_validationErrors.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Constraint Violations Found:',
                      style: GoogleFonts.poppins(color: Colors.red.shade800, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    ..._validationErrors.map((err) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $err', style: GoogleFonts.poppins(color: Colors.red.shade700, fontSize: 12)),
                        )),
                  ],
                ),
              ),

            // Save / Submit Button
            ElevatedButton(
              onPressed: _isValidating ? null : _validateAndSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isValidating
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Validate & Add Slot', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
