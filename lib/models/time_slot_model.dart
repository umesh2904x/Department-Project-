/// Time slot definitions for the department timetable.
class TimeSlot {
  final String id;
  final String label;
  final String startTime;
  final String endTime;
  final bool isBreak;

  const TimeSlot({
    required this.id,
    required this.label,
    required this.startTime,
    required this.endTime,
    this.isBreak = false,
  });

  @override
  String toString() => '$label ($startTime–$endTime)';
}

/// A two-hour block that combines two consecutive regular slots for practicals.
class PracticalSlot {
  final String id;
  final String label;
  final String startSlotId;
  final String endSlotId;
  final String startTime;
  final String endTime;

  const PracticalSlot({
    required this.id,
    required this.label,
    required this.startSlotId,
    required this.endSlotId,
    required this.startTime,
    required this.endTime,
  });

  /// Returns the IDs of both single slots covered by this practical.
  List<String> get coveredSlotIds => [startSlotId, endSlotId];

  @override
  String toString() => '$label ($startTime–$endTime)';
}

/// Central registry of all time slots used in the timetable.
class AppTimeSlots {
  // ── Single (1-hour theory) slots ──────────────────────────────────────────
  static const List<TimeSlot> slots = [
    TimeSlot(id: 'S1', label: 'Slot 1',     startTime: '8:10',  endTime: '9:05'),
    TimeSlot(id: 'S2', label: 'Slot 2',     startTime: '9:05',  endTime: '10:00'),
    TimeSlot(id: 'RECESS', label: 'Recess', startTime: '10:00', endTime: '10:20', isBreak: true),
    TimeSlot(id: 'S3', label: 'Slot 3',     startTime: '10:20', endTime: '11:15'),
    TimeSlot(id: 'S4', label: 'Slot 4',     startTime: '11:15', endTime: '12:10'),
    TimeSlot(id: 'LUNCH', label: 'Lunch Break', startTime: '12:10', endTime: '12:50', isBreak: true),
    TimeSlot(id: 'S5', label: 'Slot 5',     startTime: '12:50', endTime: '1:45'),
    TimeSlot(id: 'S6', label: 'Slot 6',     startTime: '1:45',  endTime: '2:40'),
    TimeSlot(id: 'S7', label: 'Slot 7',     startTime: '2:40',  endTime: '3:35'),
    TimeSlot(id: 'S8', label: 'Slot 8',     startTime: '3:35',  endTime: '4:30'),
    TimeSlot(id: 'S9', label: 'Slot 9',     startTime: '4:30',  endTime: '5:00'),
  ];

  /// Only the teaching (non-break) slots.
  static List<TimeSlot> get teachingSlots =>
      slots.where((s) => !s.isBreak).toList();

  static TimeSlot? slotById(String id) {
    try {
      return slots.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Two-hour practical slots ───────────────────────────────────────────────
  // A practical must never cross Recess or Lunch Break.
  static const List<PracticalSlot> practicalSlots = [
    PracticalSlot(id: 'P1', label: '8:10–10:00',  startSlotId: 'S1', endSlotId: 'S2', startTime: '8:10',  endTime: '10:00'),
    PracticalSlot(id: 'P2', label: '10:20–12:10', startSlotId: 'S3', endSlotId: 'S4', startTime: '10:20', endTime: '12:10'),
    PracticalSlot(id: 'P3', label: '12:50–2:40',  startSlotId: 'S5', endSlotId: 'S6', startTime: '12:50', endTime: '2:40'),
    PracticalSlot(id: 'P4', label: '1:45–3:35',   startSlotId: 'S6', endSlotId: 'S7', startTime: '1:45',  endTime: '3:35'),
    PracticalSlot(id: 'P5', label: '2:40–4:30',   startSlotId: 'S7', endSlotId: 'S8', startTime: '2:40',  endTime: '4:30'),
  ];

  static PracticalSlot? practicalById(String id) {
    try {
      return practicalSlots.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
