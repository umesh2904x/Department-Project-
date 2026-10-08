/// Static application constants for divisions, rooms, and faculty.
class AppConstants {
  // ── Divisions & Batches ───────────────────────────────────────────────────
  static const List<String> divisions = [
    'SE-A',
    'SE-B',
    'TE-A',
    'TE-B',
    'BE-A',
    'BE-B',
  ];

  static const List<String> batches = ['Batch 1', 'Batch 2', 'Batch 3'];

  static const List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  // ── Rooms ─────────────────────────────────────────────────────────────────
  static const List<String> classrooms = [
    '201',
    '202',
    '203',
    '204',
    '205',
    '206',
    '207',
    '208',
    '209',
    '210',
    '211',
    '212',
    '213',
    '214',
    '215',
    '216',
    '221',
    '504',
  ];

  static const List<String> labs = [
    '208A',
    '208B',
    '217',
    '218',
    '219',
    '220',
    '222',
  ];

  static List<String> get allRooms => [...classrooms, ...labs];

  // ── Faculty directory (public display data, not login credentials) ───────
  static const Map<String, String> facultyIdToName = {
    'FAC001': 'Prof. Avani',
    'FAC002': 'Prof. Hardiki',
    'FAC003': 'Prof. Harsha',
    'FAC004': 'Prof. Deepali',
    'FAC005': 'Prof. Poonam',
    'FAC006': 'Prof. Veena T.',
    'FAC007': 'Prof. Veena G.',
    'FAC008': 'Prof. Rajashri',
    'FAC009': 'Prof. Richa',
    'FAC010': 'Prof. Shubhangi',
    'FAC011': 'Prof. Kiran',
    'FAC012': 'Prof. Sarala',
    'FAC013': 'Prof. Avinash',
    'FAC014': 'Prof. Swati',
    'FAC015': 'Prof. Aswini',
    'FAC016': 'Prof. Ujwala',
    'FAC017': 'Dr. Pravin (HOD)',
    'FAC018': 'Prof. Priyanka',
  };
}
