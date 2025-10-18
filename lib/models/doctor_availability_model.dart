import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorAvailabilityException {
  final DateTime date;
  final bool isOff;
  final String? reason;

  DoctorAvailabilityException({
    required this.date,
    required this.isOff,
    this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'isOff': isOff,
      'reason': reason ?? '',
    };
  }

  factory DoctorAvailabilityException.fromMap(Map<String, dynamic> map) {
    return DoctorAvailabilityException(
      date: (map['date'] as Timestamp).toDate(),
      isOff: map['isOff'] ?? true,
      reason: map['reason'],
    );
  }
}

class DoctorAvailabilityModel {
  final String id;
  final String doctorId;
  final int dayOfWeek; // 1 = Monday, 7 = Sunday
  final String startTime; // e.g., "09:00" (24-hour format)
  final String endTime; // e.g., "17:00" (24-hour format)
  final int slotDurationMinutes; // e.g., 20, 30, 60
  final List<DoctorAvailabilityException> exceptions; // Days off or special hours
  final bool isActive; // Can be toggled on/off
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  DoctorAvailabilityModel({
    required this.id,
    required this.doctorId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.slotDurationMinutes,
    this.exceptions = const [],
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorId': doctorId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'slotDurationMinutes': slotDurationMinutes,
      'exceptions': exceptions.map((e) => e.toMap()).toList(),
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  // Create from Map
  factory DoctorAvailabilityModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    final exceptionsList = (map['exceptions'] as List?)
            ?.map((e) => DoctorAvailabilityException.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [];

    return DoctorAvailabilityModel(
      id: documentId,
      doctorId: map['doctorId'] ?? '',
      dayOfWeek: map['dayOfWeek'] ?? 1,
      startTime: map['startTime'] ?? '09:00',
      endTime: map['endTime'] ?? '17:00',
      slotDurationMinutes: map['slotDurationMinutes'] ?? 30,
      exceptions: exceptionsList,
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'],
    );
  }

  // Copy with
  DoctorAvailabilityModel copyWith({
    String? id,
    String? doctorId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    int? slotDurationMinutes,
    List<DoctorAvailabilityException>? exceptions,
    bool? isActive,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return DoctorAvailabilityModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      slotDurationMinutes: slotDurationMinutes ?? this.slotDurationMinutes,
      exceptions: exceptions ?? this.exceptions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get day name
  String get dayName {
    switch (dayOfWeek) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  // Get day abbreviation
  String get dayAbbr {
    switch (dayOfWeek) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '---';
    }
  }

  // Check if doctor is available on a specific date
  bool isAvailableOnDate(DateTime date) {
    if (!isActive) return false;

    // Check if date matches this day of week
    if (date.weekday != dayOfWeek) return false;

    // Check exceptions
    for (final exception in exceptions) {
      if (_isSameDate(exception.date, date)) {
        return !exception.isOff;
      }
    }

    return true;
  }

  // Generate time slots for a specific date
  List<DateTime> generateTimeSlots(DateTime date) {
    if (!isAvailableOnDate(date)) return [];

    final slots = <DateTime>[];
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');

    var current = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(startParts[0]),
      int.parse(startParts[1]),
    );

    final end = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );

    while (current.isBefore(end)) {
      slots.add(current);
      current = current.add(Duration(minutes: slotDurationMinutes));
    }

    return slots;
  }

  // Helper: Check if two dates are the same day
  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Parse time string to TimeOfDay equivalent
  static DateTime parseTime(DateTime date, String time) {
    final parts = time.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}

