import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_availability_model.dart';
import '../models/appointment_model.dart';
import 'database_service.dart';

class DoctorAvailabilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _dbService = DatabaseService();

  // Collection reference
  CollectionReference get _availabilityCollection =>
      _firestore.collection('doctor_availability');

  // Create or update availability for a specific day
  Future<String> setAvailability(DoctorAvailabilityModel availability) async {
    try {
      // Check if availability for this day already exists
      final existing = await _availabilityCollection
          .where('doctorId', isEqualTo: availability.doctorId)
          .where('dayOfWeek', isEqualTo: availability.dayOfWeek)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        // Update existing
        final docId = existing.docs.first.id;
        await _availabilityCollection.doc(docId).update(availability.toMap());
        return docId;
      } else {
        // Create new
        final docRef = await _availabilityCollection.add(availability.toMap());
        
        // Log activity
        await _dbService.logActivity(
          userId: availability.doctorId,
          action: 'availability_set',
          resourceType: 'availability',
          resourceId: docRef.id,
          details: {
            'dayOfWeek': availability.dayOfWeek,
            'startTime': availability.startTime,
            'endTime': availability.endTime,
          },
        );

        return docRef.id;
      }
    } catch (e) {
      throw Exception('Failed to set availability: ${e.toString()}');
    }
  }

  // Get availability for a doctor
  Stream<List<DoctorAvailabilityModel>> getAvailabilityForDoctor(
    String doctorId,
  ) {
    return _availabilityCollection
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) {
      final availabilities = snapshot.docs
          .map((doc) => DoctorAvailabilityModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
      
      // Sort on client side to avoid needing Firestore index
      availabilities.sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
      return availabilities;
    });
  }

  // Get availability for a specific day
  Future<DoctorAvailabilityModel?> getAvailabilityForDay(
    String doctorId,
    int dayOfWeek,
  ) async {
    try {
      final snapshot = await _availabilityCollection
          .where('doctorId', isEqualTo: doctorId)
          .where('dayOfWeek', isEqualTo: dayOfWeek)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return DoctorAvailabilityModel.fromMap(
        snapshot.docs.first.data() as Map<String, dynamic>,
        snapshot.docs.first.id,
      );
    } catch (e) {
      throw Exception('Failed to get availability: ${e.toString()}');
    }
  }

  // Delete availability
  Future<void> deleteAvailability(String id, String doctorId) async {
    try {
      await _availabilityCollection.doc(id).delete();

      // Log activity
      await _dbService.logActivity(
        userId: doctorId,
        action: 'availability_deleted',
        resourceType: 'availability',
        resourceId: id,
        details: {},
      );
    } catch (e) {
      throw Exception('Failed to delete availability: ${e.toString()}');
    }
  }

  // Add exception (day off or special hours)
  Future<void> addException(
    String availabilityId,
    String doctorId,
    DoctorAvailabilityException exception,
  ) async {
    try {
      final doc = await _availabilityCollection.doc(availabilityId).get();
      if (!doc.exists) {
        throw Exception('Availability not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      final availability =
          DoctorAvailabilityModel.fromMap(data, availabilityId);

      final updatedExceptions = List<DoctorAvailabilityException>.from(
        availability.exceptions,
      )..add(exception);

      await _availabilityCollection.doc(availabilityId).update({
        'exceptions': updatedExceptions.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log activity
      await _dbService.logActivity(
        userId: doctorId,
        action: 'availability_exception_added',
        resourceType: 'availability',
        resourceId: availabilityId,
        details: {
          'date': exception.date.toString(),
          'isOff': exception.isOff,
        },
      );
    } catch (e) {
      throw Exception('Failed to add exception: ${e.toString()}');
    }
  }

  // Remove exception
  Future<void> removeException(
    String availabilityId,
    String doctorId,
    DateTime exceptionDate,
  ) async {
    try {
      final doc = await _availabilityCollection.doc(availabilityId).get();
      if (!doc.exists) {
        throw Exception('Availability not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      final availability =
          DoctorAvailabilityModel.fromMap(data, availabilityId);

      final updatedExceptions = availability.exceptions.where((e) {
        return !_isSameDate(e.date, exceptionDate);
      }).toList();

      await _availabilityCollection.doc(availabilityId).update({
        'exceptions': updatedExceptions.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove exception: ${e.toString()}');
    }
  }

  // Generate available time slots for a date range
  Future<Map<DateTime, List<DateTime>>> generateAvailableSlots({
    required String doctorId,
    required DateTime startDate,
    required DateTime endDate,
    required List<AppointmentModel> existingAppointments,
  }) async {
    final Map<DateTime, List<DateTime>> availableSlots = {};

    try {
      // Get doctor's availability rules
      final availabilitySnapshot = await _availabilityCollection
          .where('doctorId', isEqualTo: doctorId)
          .get();

      if (availabilitySnapshot.docs.isEmpty) {
        return availableSlots; // No availability set
      }

      // Filter for active availability on client side to avoid needing index
      final availabilityRules = availabilitySnapshot.docs
          .map((doc) => DoctorAvailabilityModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .where((rule) => rule.isActive) // Filter on client side
          .toList();
      
      if (availabilityRules.isEmpty) {
        return availableSlots; // No active availability
      }

      // Iterate through each date in range
      DateTime currentDate = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      final endDateOnly = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
      );

      while (currentDate.isBefore(endDateOnly) ||
          currentDate.isAtSameMomentAs(endDateOnly)) {
        // Find availability rule for this day of week
        final rule = availabilityRules.firstWhere(
          (r) => r.dayOfWeek == currentDate.weekday,
          orElse: () => availabilityRules.first, // Fallback
        );

        if (rule.isAvailableOnDate(currentDate)) {
          // Generate time slots for this date
          final slots = rule.generateTimeSlots(currentDate);

          // Filter out slots that overlap with existing appointments
          final availableForDate = slots.where((slot) {
            final slotEnd = slot.add(Duration(
              minutes: rule.slotDurationMinutes,
            ));

            // Check if this slot conflicts with any appointment
            final hasConflict = existingAppointments.any((appointment) {
              return appointment.overlapsWith(slot, slotEnd);
            });

            // Also check if slot is in the past
            final isPast = slot.isBefore(DateTime.now());

            return !hasConflict && !isPast;
          }).toList();

          if (availableForDate.isNotEmpty) {
            availableSlots[currentDate] = availableForDate;
          }
        }

        currentDate = currentDate.add(const Duration(days: 1));
      }

      return availableSlots;
    } catch (e) {
      throw Exception('Failed to generate available slots: ${e.toString()}');
    }
  }

  // Quick check: Is doctor available at a specific time?
  Future<bool> isDoctorAvailableAt({
    required String doctorId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      // Check availability rules
      final availability = await getAvailabilityForDay(
        doctorId,
        startTime.weekday,
      );

      if (availability == null || !availability.isActive) {
        return false;
      }

      // Check if time falls within availability hours
      if (!availability.isAvailableOnDate(startTime)) {
        return false;
      }

      // Check availability time range
      final availStart = DoctorAvailabilityModel.parseTime(
        startTime,
        availability.startTime,
      );
      final availEnd = DoctorAvailabilityModel.parseTime(
        startTime,
        availability.endTime,
      );

      if (startTime.isBefore(availStart) || endTime.isAfter(availEnd)) {
        return false;
      }

      // Check for appointment conflicts
      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('startTime',
              isLessThan: Timestamp.fromDate(endTime))
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startTime.subtract(const Duration(hours: 1))))
          .get();

      final appointments = appointmentsSnapshot.docs
          .map((doc) => AppointmentModel.fromMap(
                doc.data(),
                doc.id,
              ))
          .toList();

      // Check for overlaps
      for (final appointment in appointments) {
        if (appointment.status != AppointmentStatus.cancelled &&
            appointment.status != AppointmentStatus.rejected) {
          if (appointment.overlapsWith(startTime, endTime)) {
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      throw Exception('Failed to check availability: ${e.toString()}');
    }
  }

  // Helper: Check if two dates are the same day
  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Toggle availability active status
  Future<void> toggleAvailability(
    String availabilityId,
    String doctorId,
    bool isActive,
  ) async {
    try {
      await _availabilityCollection.doc(availabilityId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log activity
      await _dbService.logActivity(
        userId: doctorId,
        action: 'availability_toggled',
        resourceType: 'availability',
        resourceId: availabilityId,
        details: {'isActive': isActive},
      );
    } catch (e) {
      throw Exception('Failed to toggle availability: ${e.toString()}');
    }
  }
}

