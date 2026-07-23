/// All static application constants: divisions, batches, time slots, rooms, credentials.
class AppConstants {
  // ── Divisions & Batches ───────────────────────────────────────────────────
  static const List<String> divisions = [
    'SE-A', 'SE-B', 'TE-A', 'TE-B', 'BE-A', 'BE-B',
  ];

  static const List<String> batches = ['Batch 1', 'Batch 2', 'Batch 3'];

  static const List<String> days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
  ];

  // ── Rooms ─────────────────────────────────────────────────────────────────
  static const List<String> classrooms = [
    '201', '202', '203', '204', '205', '206', '207', '208', '209', '210',
    '211', '212', '213', '214', '215', '216', '221', '504',
  ];

  static const List<String> labs = [
    '208A', '208B', '217', '218', '219', '220', '222',
  ];

  static List<String> get allRooms => [...classrooms, ...labs];

  // ── Hardcoded Credentials ─────────────────────────────────────────────────
  // Map<username, {password, role, name, id/division}>
  static const Map<String, Map<String, String>> credentials = {
    // Admins
    'admin1': {
      'password': '[removed]',
      'role': 'admin',
      'name': 'Admin 1',
      'id': 'admin1',
    },
    'admin2': {
      'password': '[removed]',
      'role': 'admin',
      'name': 'Admin 2',
      'id': 'admin2',
    },

    // Teachers — use server-managed credentials
    'avani':     {'password': '[removed]', 'role': 'teacher', 'name': 'Prof. Avani',        'id': 'FAC001'},
    'hardiki':   {'password': '[removed]', 'role': 'teacher', 'name': 'Prof. Hardiki',      'id': 'FAC002'},
    'harsha':    {'password': '[removed]', 'role': 'teacher', 'name': 'Prof. Harsha',       'id': 'FAC003'},
    'deepali':   {'password': '[removed]', 'role': 'teacher', 'name': 'Prof. Deepali',      'id': 'FAC004'},
    'poonam':    {'password': '[removed]', 'role': 'teacher', 'name': 'Prof. Poonam',       'id': 'FAC005'},
    'veena_t':   {'password': '[removed]', 'role': 'teacher', 'name': 'Prof. Veena T.',     'id': 'FAC006'},
    'veena_g':   {'password': '[removed]', 'role': 'teacher', 'name': 'Prof. Veena G.',     'id': 'FAC007'},
    'rajashri':  {'password': '[removed]', 'role': 'teacher', 'name': 'Prof. Rajashri',     'id': 'FAC008'},
    'richa':     {'password': '[removed]', 'role': 'teacher', 'name': 'Prof. Richa',        'id': 'FAC009'},
    'shubhangi': {'password': '[removed]', 'role': 'teacher', 'name': 'Prof. Shubhangi',    'id': 'FAC010'},
    'kiran':     {'password': '[removed]', 'role': 'teacher', 'name': 'Prof. Kiran',        'id': 'FAC011'},
    'sarala':    {'password': '[removed]', 'role': 'teacher', 'name': 'Prof. Sarala',       'id': 'FAC012'},
    'avinash':   {'password': '[removed]', 'role': 'teacher', 'name': 'Prof. Avinash',      'id': 'FAC013'},
    'swati':     {'password': '[removed]', 'role': 'teacher', 'name': 'Prof. Swati',        'id': 'FAC014'},
    'aswini':    {'password': '[removed]', 'role': 'teacher', 'name': 'Prof. Aswini',       'id': 'FAC015'},
    'ujwala':    {'password': '[removed]', 'role': 'teacher', 'name': 'Prof. Ujwala',       'id': 'FAC016'},
    'pravin':    {'password': '[removed]', 'role': 'teacher', 'name': 'Dr. Pravin (HOD)',   'id': 'FAC017'},
    'priyanka':  {'password': '[removed]', 'role': 'teacher', 'name': 'Prof. Priyanka',     'id': 'FAC018'},

    // Students — one account per class/division
    'se_a': {'password': '[removed]', 'role': 'student', 'name': 'SE-A', 'division': 'SE-A'},
    'se_b': {'password': '[removed]', 'role': 'student', 'name': 'SE-B', 'division': 'SE-B'},
    'te_a': {'password': '[removed]', 'role': 'student', 'name': 'TE-A', 'division': 'TE-A'},
    'te_b': {'password': '[removed]', 'role': 'student', 'name': 'TE-B', 'division': 'TE-B'},
    'be_a': {'password': '[removed]', 'role': 'student', 'name': 'BE-A', 'division': 'BE-A'},
    'be_b': {'password': '[removed]', 'role': 'student', 'name': 'BE-B', 'division': 'BE-B'},
  };

  // ── Faculty IDs to names convenience map ─────────────────────────────────
  static Map<String, String> get facultyIdToName {
    final map = <String, String>{};
    for (final entry in credentials.entries) {
      if (entry.value['role'] == 'teacher') {
        map[entry.value['id']!] = entry.value['name']!;
      }
    }
    return map;
  }
}
