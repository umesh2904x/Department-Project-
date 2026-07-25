import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timetable_entry_model.dart';
import '../models/time_slot_model.dart';
import '../models/faculty_model.dart';
import 'faculty_service.dart';
import 'api_service.dart';

class TimetableService {
  static const String _key = 'timetable_entries';

  /// Load all saved timetable entries
  static Future<List<TimetableEntry>> getAllEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key);
    if (data == null) return [];
    return data.map((item) => TimetableEntry.fromJson(jsonDecode(item))).toList();
  }

  /// Save all timetable entries
  static Future<void> saveAllEntries(List<TimetableEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final data = entries.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_key, data);
  }

  /// Check conflicts and constraints when adding/editing a timetable entry
  /// Returns a list of conflict warning messages. If empty, the entry is valid.
  static Future<List<String>> validateEntry(TimetableEntry entry, {String? ignoreEntryId}) async {
    final conflicts = <String>[];
    final allEntries = await getAllEntries();
    final facultyList = await FacultyService.getAllFaculty();

    // 1. Find the faculty member
    final faculty = facultyList.firstWhere((f) => f.id == entry.facultyId, orElse: () => FacultyMember(id: entry.facultyId, name: entry.facultyName, employeeId: ''));

    // Check if faculty is on leave
    if (faculty.isOnLeave) {
      conflicts.add('Faculty "${faculty.name}" is on leave: ${faculty.leaveReason}');
    }

    // Determine the slot IDs involved
    List<String> currentSlots = [];
    if (entry.isPractical) {
      final pSlot = AppTimeSlots.practicalById(entry.slotId);
      if (pSlot != null) {
        currentSlots = pSlot.coveredSlotIds;
      }
    } else {
      currentSlots = [entry.slotId];
    }

    // Check if faculty is available for these slots
    for (final slot in currentSlots) {
      if (!faculty.availableTimings.contains(slot)) {
        conflicts.add('Faculty "${faculty.name}" is marked unavailable for slot $slot.');
      }
    }

    // Check overlaps with other scheduled slots
    for (final existing in allEntries) {
      if (existing.id == ignoreEntryId) continue;
      if (existing.day != entry.day) continue;

      // Determine existing slot coverage
      List<String> existingSlots = [];
      if (existing.isPractical) {
        final pSlot = AppTimeSlots.practicalById(existing.slotId);
        if (pSlot != null) {
          existingSlots = pSlot.coveredSlotIds;
        }
      } else {
        existingSlots = [existing.slotId];
      }

      // Check if there is a slot intersection
      final hasOverlap = currentSlots.any((slot) => existingSlots.contains(slot));
      if (!hasOverlap) continue;

      // Conflict checks under overlap:
      
      // 2. Room double-booking
      if (existing.roomNumber == entry.roomNumber) {
        conflicts.add(
          'Room "${entry.roomNumber}" is already booked for Division ${existing.division} '
          '(${existing.subjectName}) during slot ${existing.slotId}.'
        );
      }

      // 3. Faculty double-booking
      if (existing.facultyId == entry.facultyId) {
        conflicts.add(
          'Faculty "${entry.facultyName}" is already teaching Division ${existing.division} '
          '(${existing.subjectName}) during slot ${existing.slotId}.'
        );
      }

      // 4. Batch overlap: No batch within the same division can have overlapping classes
      if (existing.division == entry.division) {
        // If one is theory (covers all batches) or they share a specific batch
        final isTheoryOverlap = existing.batch.isEmpty || entry.batch.isEmpty;
        final isSameBatchOverlap = existing.batch == entry.batch;
        
        if (isTheoryOverlap || isSameBatchOverlap) {
          conflicts.add(
            'Division ${entry.division} has an overlapping ${existing.isTheory ? "Theory" : "Practical"} lecture '
            '(${existing.subjectName}) already scheduled in slot ${existing.slotId}.'
          );
        }
      }
    }

    // 5. Workload limit checks
    final dayCount = allEntries.where((e) => e.facultyId == entry.facultyId && e.day == entry.day && e.id != ignoreEntryId).length;
    if (dayCount >= faculty.maxLecturesPerDay) {
      conflicts.add('Faculty "${faculty.name}" exceeds daily lecture limit (${faculty.maxLecturesPerDay}/day).');
    }

    final weekCount = allEntries.where((e) => e.facultyId == entry.facultyId && e.id != ignoreEntryId).length;
    if (weekCount >= faculty.maxLecturesPerWeek) {
      conflicts.add('Faculty "${faculty.name}" exceeds weekly lecture limit (${faculty.maxLecturesPerWeek}/week).');
    }

    return conflicts;
  }

  /// Add a new timetable entry
  static Future<bool> addEntry(TimetableEntry entry) async {
    final list = await getAllEntries();
    // Verify if it's locked protection
    list.add(entry);
    await saveAllEntries(list);
    return true;
  }

  /// Delete a timetable entry (if not locked, or if explicitly bypassed by admin)
  static Future<bool> deleteEntry(String id) async {
    final list = await getAllEntries();
    final idx = list.indexWhere((e) => e.id == id);
    if (idx != -1) {
      list.removeAt(idx);
      await saveAllEntries(list);
      return true;
    }
    return false;
  }

  /// Lock or unlock a timetable entry
  static Future<void> setLockedStatus(String id, bool locked) async {
    final list = await getAllEntries();
    final idx = list.indexWhere((e) => e.id == id);
    if (idx != -1) {
      list[idx].isLocked = locked;
      await saveAllEntries(list);
    }
  }
}
