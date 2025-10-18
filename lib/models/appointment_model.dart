import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus {
  pending,
  confirmed,
  completed,
  cancelled,
  rejected,
}

class AppointmentModel {
  final String id;
  final String doctorId;
  final String patientId;
  final String doctorName;
  final String patientName;
  final Timestamp startTime; // UTC timestamp for appointment start
  final Timestamp endTime; // UTC timestamp for appointment end
  final AppointmentStatus status;
  final String? reason;
  final String? notes;
  final String createdBy; // UID of requester (patient)
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final String? meetingLink; // For telemedicine
  final String meetingType; // "physical" or "video"
  final String? cancelledBy; // UID who cancelled
  final String? cancellationReason;

  AppointmentModel({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.doctorName,
    required this.patientName,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.reason,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.meetingLink,
    this.meetingType = 'physical',
    this.cancelledBy,
    this.cancellationReason,
  });

  // Helper: Get duration in minutes
  int get durationMinutes {
    return endTime.toDate().difference(startTime.toDate()).inMinutes;
  }

  // Helper: Check if appointment is in the past
  bool get isPast {
    return endTime.toDate().isBefore(DateTime.now());
  }

  // Helper: Check if appointment is upcoming
  bool get isUpcoming {
    return startTime.toDate().isAfter(DateTime.now()) && 
           status != AppointmentStatus.cancelled &&
           status != AppointmentStatus.rejected;
  }

  // Helper: Get formatted time slot string (for backward compatibility)
  String get timeSlot {
    final start = startTime.toDate();
    final end = endTime.toDate();
    final startStr = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endStr = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorId': doctorId,
      'patientId': patientId,
      'doctorName': doctorName,
      'patientName': patientName,
      'startTime': startTime,
      'endTime': endTime,
      'status': status.name,
      'reason': reason ?? '',
      'notes': notes ?? '',
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
      'meetingLink': meetingLink ?? '',
      'meetingType': meetingType,
      'cancelledBy': cancelledBy ?? '',
      'cancellationReason': cancellationReason ?? '',
    };
  }

  // Create from Map
  factory AppointmentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AppointmentModel(
      id: documentId,
      doctorId: map['doctorId'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      patientName: map['patientName'] ?? '',
      startTime: map['startTime'] ?? Timestamp.now(),
      endTime: map['endTime'] ?? Timestamp.now(),
      status: _statusFromString(map['status'] ?? 'pending'),
      reason: map['reason'],
      notes: map['notes'],
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'],
      meetingLink: map['meetingLink'],
      meetingType: map['meetingType'] ?? 'physical',
      cancelledBy: map['cancelledBy'],
      cancellationReason: map['cancellationReason'],
    );
  }

  static AppointmentStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'rejected':
        return AppointmentStatus.rejected;
      default:
        return AppointmentStatus.pending;
    }
  }

  // Copy with
  AppointmentModel copyWith({
    String? id,
    String? doctorId,
    String? patientId,
    String? doctorName,
    String? patientName,
    Timestamp? startTime,
    Timestamp? endTime,
    AppointmentStatus? status,
    String? reason,
    String? notes,
    String? createdBy,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? meetingLink,
    String? meetingType,
    String? cancelledBy,
    String? cancellationReason,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      doctorName: doctorName ?? this.doctorName,
      patientName: patientName ?? this.patientName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      meetingLink: meetingLink ?? this.meetingLink,
      meetingType: meetingType ?? this.meetingType,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  // Helper: Check if this appointment overlaps with another time range
  bool overlapsWith(DateTime otherStart, DateTime otherEnd) {
    final thisStart = startTime.toDate();
    final thisEnd = endTime.toDate();
    return thisStart.isBefore(otherEnd) && thisEnd.isAfter(otherStart);
  }

  // Helper: Create appointment from date and time strings
  static Timestamp parseDateTime(DateTime date, String time) {
    // time format: "09:00" or "09:00 AM"
    final timeParts = time.replaceAll(RegExp(r'[AP]M'), '').trim().split(':');
    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    if (time.toUpperCase().contains('PM') && hour != 12) {
      hour += 12;
    } else if (time.toUpperCase().contains('AM') && hour == 12) {
      hour = 0;
    }
    
    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
    
    return Timestamp.fromDate(dateTime.toUtc());
  }
}

