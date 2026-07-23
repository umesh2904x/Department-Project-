import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_constants.dart';
import '../../models/time_slot_model.dart';
import '../../models/timetable_entry_model.dart';
import '../../services/timetable_service.dart';

class RoomAvailabilityScreen extends StatefulWidget {
  const RoomAvailabilityScreen({super.key});

  @override
  State<RoomAvailabilityScreen> createState() => _RoomAvailabilityScreenState();
}

class _RoomAvailabilityScreenState extends State<RoomAvailabilityScreen> {
  String _selectedDay = 'Monday';
  String _roomTypeFilter = 'all'; // 'all', 'classroom', 'lab'
  List<TimetableEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final allEntries = await TimetableService.getAllEntries();
    setState(() {
      _entries = allEntries.where((e) => e.day.toLowerCase() == _selectedDay.toLowerCase()).toList();
      _isLoading = false;
    });
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
                  'You do not have permission to access the Room Availability screen.',
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

    // Filter rooms list
    final filteredRooms = AppConstants.allRooms.where((room) {
      final isLab = AppConstants.labs.contains(room);
      if (_roomTypeFilter == 'classroom' && isLab) return false;
      if (_roomTypeFilter == 'lab' && !isLab) return false;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Room Availability Grid', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Day & Type Filter Panel
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.deepPurple.shade50,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Day Selector Dropdown
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
                          const SizedBox(width: 12),
                          // Type Filter Selector
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _roomTypeFilter,
                              decoration: InputDecoration(
                                labelText: 'Room Type',
                                labelStyle: GoogleFonts.poppins(color: Colors.deepPurple.shade900),
                                fillColor: Colors.white,
                                filled: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('All Rooms')),
                                DropdownMenuItem(value: 'classroom', child: Text('Classrooms')),
                                DropdownMenuItem(value: 'lab', child: Text('Laboratories')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _roomTypeFilter = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Legend panel
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem('Available', Colors.green),
                          const SizedBox(width: 16),
                          _buildLegendItem('Occupied', Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),

                // Rooms List with horizontal Slots preview
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredRooms.length,
                    itemBuilder: (context, index) {
                      final roomNumber = filteredRooms[index];
                      final isLab = AppConstants.labs.contains(roomNumber);

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isLab ? Icons.science : Icons.room_preferences,
                                    color: Colors.deepPurple.shade800,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Room $roomNumber ${isLab ? "(Lab)" : "(Classroom)"}',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Grid or horizontal slots
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: AppTimeSlots.teachingSlots.map((slot) {
                                  // Check if room is occupied during this slot
                                  final occupiedEntry = _entries.firstWhere(
                                    (e) {
                                      if (e.roomNumber != roomNumber) return false;
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

                                  final isOccupied = occupiedEntry.id.isNotEmpty;

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isOccupied ? Colors.red.shade100 : Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isOccupied ? Colors.red.shade300 : Colors.green.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          slot.label,
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isOccupied ? Colors.red.shade900 : Colors.green.shade900,
                                          ),
                                        ),
                                        Text(
                                          isOccupied ? occupiedEntry.division : 'Free',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isOccupied ? Colors.red.shade800 : Colors.green.shade800,
                                          ),
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
        Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
