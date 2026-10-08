import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/faculty_model.dart';
import '../utils/app_constants.dart';

class FacultyService {
  static const String _key = 'faculty_members';

  /// Fetch all faculty members. Pre-seed on first run.
  static Future<List<FacultyMember>> getAllFaculty() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key);

    if (data == null) {
      // Pre-seed
      final seeded = _preSeedFaculty();
      await saveAllFaculty(seeded);
      return seeded;
    }

    final list =
        data.map((item) => FacultyMember.fromJson(jsonDecode(item))).toList();
    bool updated = false;

    if (!list.any((f) => f.name.contains('Priyanka') || f.id == 'FAC018')) {
      list.add(FacultyMember(
        id: 'FAC018',
        name: 'Prof. Priyanka',
        employeeId: 'EMP118',
        designation: 'Assistant Professor',
        subjects: ['Computer Networks', 'Data Science'],
        maxLecturesPerDay: 4,
        maxLecturesPerWeek: 16,
        availableTimings: [
          'S1',
          'S2',
          'S3',
          'S4',
          'S5',
          'S6',
          'S7',
          'S8',
          'S9'
        ],
        preferredRooms: ['203', '204'],
        email: 'priyanka@college.edu',
        phone: '9876543218',
      ));
      updated = true;
    }

    for (final f in list) {
      if (!f.availableTimings.contains('S9')) {
        f.availableTimings.add('S9');
        updated = true;
      }
    }

    if (updated) {
      await saveAllFaculty(list);
    }

    return list;
  }

  /// Save the entire list of faculty
  static Future<void> saveAllFaculty(List<FacultyMember> list) async {
    final prefs = await SharedPreferences.getInstance();
    final data = list.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_key, data);
  }

  /// Update single faculty member
  static Future<void> updateFaculty(FacultyMember member) async {
    final list = await getAllFaculty();
    final idx = list.indexWhere((f) => f.id == member.id);
    if (idx != -1) {
      list[idx] = member;
    } else {
      list.add(member);
    }
    await saveAllFaculty(list);
  }

  /// Find faculty by ID
  static Future<FacultyMember?> getFacultyById(String id) async {
    final list = await getAllFaculty();
    try {
      return list.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Generate the display directory without embedding login credentials.
  static List<FacultyMember> _preSeedFaculty() {
    final list = <FacultyMember>[];
    AppConstants.facultyIdToName.forEach((id, name) {
      final isHod = name.contains('(HOD)');

      list.add(FacultyMember(
        id: id,
        name: name,
        employeeId: 'EMP${100 + list.length}',
        designation: isHod ? 'HOD' : 'Assistant Professor',
        subjects:
            isHod ? ['Management', 'Research'] : ['Subject ${list.length + 1}'],
        maxLecturesPerDay: isHod ? 2 : 4,
        maxLecturesPerWeek: isHod ? 8 : 16,
        availableTimings: [
          'S1',
          'S2',
          'S3',
          'S4',
          'S5',
          'S6',
          'S7',
          'S8',
          'S9'
        ],
        preferredRooms: isHod ? ['504'] : ['201', '202'],
        email: '${id.toLowerCase()}@college.edu',
        phone: '98765432${list.length.toString().padLeft(2, '0')}',
      ));
    });
    return list;
  }
}
