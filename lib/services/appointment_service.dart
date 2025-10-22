import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';
import 'database_service.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _dbService = DatabaseService();

  // Collection reference
  CollectionReference get _appointmentsCollection => _firestore.collection('appointments');

  // Check for appointment conflicts
  Future<bool> hasConflict({
    required String doctorId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeAppointmentId,
  }) async {
    try {
      final query = await _appointmentsCollection
          .where('doctorId', isEqualTo: doctorId)
          .where('startTime', isLessThan: Timestamp.fromDate(endTime))
          .get();

      for (final doc in query.docs) {
        if (excludeAppointmentId != null && doc.id == excludeAppointmentId) {
          continue; // Skip when rescheduling same appointment
        }

        final appointment = AppointmentModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );

        // Only check non-cancelled/rejected appointments
        if (appointment.status != AppointmentStatus.cancelled &&
            appointment.status != AppointmentStatus.rejected) {
          if (appointment.overlapsWith(startTime, endTime)) {
            return true; // Conflict found
          }
        }
      }

      return false; // No conflicts
    } catch (e) {
      throw Exception('Failed to check conflicts: ${e.toString()}');
    }
  }

  // Create new appointment with conflict checking
  Future<String> createAppointment(AppointmentModel appointment) async {
    try {
      // Validate appointment data
      if (appointment.doctorId.isEmpty) {
        throw Exception('Doctor ID is required');
      }
      if (appointment.patientId.isEmpty) {
        throw Exception('Patient ID is required');
      }
      if (appointment.doctorName.isEmpty) {
        throw Exception('Doctor name is required');
      }
      if (appointment.patientName.isEmpty) {
        throw Exception('Patient name is required');
      }
      if (appointment.reason == null || appointment.reason!.isEmpty) {
        throw Exception('Reason for visit is required');
      }

      // Check for conflicts
      final hasTimeConflict = await hasConflict(
        doctorId: appointment.doctorId,
        startTime: appointment.startTime.toDate(),
        endTime: appointment.endTime.toDate(),
      );

      if (hasTimeConflict) {
        throw Exception(
          'This time slot is no longer available. Please choose another time.',
        );
      }

      // Use transaction for atomic operation
      return await _firestore.runTransaction<String>((transaction) async {
        // Double-check for conflicts within transaction
        final recentCheck = await hasConflict(
          doctorId: appointment.doctorId,
          startTime: appointment.startTime.toDate(),
          endTime: appointment.endTime.toDate(),
        );

        if (recentCheck) {
          throw Exception('Time slot was just booked. Please choose another.');
        }

        // Create appointment
        final docRef = _appointmentsCollection.doc();
        final appointmentData = appointment.toMap();
        appointmentData['id'] = docRef.id; // Ensure ID is set
        
        transaction.set(docRef, appointmentData);

        // Schedule notifications and logging after transaction
        Future.microtask(() async {
          try {
            // Log activity
            await _dbService.logActivity(
              userId: appointment.createdBy,
              action: 'appointment_created',
              resourceType: 'appointment',
              resourceId: docRef.id,
              details: {
                'doctorId': appointment.doctorId,
                'startTime': appointment.startTime.toDate().toString(),
              },
            );

            // Create notification for doctor
            await _dbService.createNotification(
              userId: appointment.doctorId,
              title: 'New Appointment Request',
              message: 'You have a new appointment request from ${appointment.patientName}',
              type: 'appointment',
            );

            // Create notification for patient
            await _dbService.createNotification(
              userId: appointment.patientId,
              title: 'Appointment Created',
              message: 'Your appointment with Dr. ${appointment.doctorName} has been created',
              type: 'appointment',
            );
          } catch (notificationError) {
            // Log notification errors but don't fail the appointment creation
            print('Warning: Failed to send notifications: $notificationError');
          }
        });

        return docRef.id;
      });
    } catch (e) {
      // Log the error for debugging
      print('Appointment creation error: ${e.toString()}');
      throw Exception('Failed to create appointment: ${e.toString()}');
    }
  }

  // Cancel appointment
  Future<void> cancelAppointment({
    required String id,
    required String cancelledBy,
    String? cancellationReason,
  }) async {
    try {
      await _appointmentsCollection.doc(id).update({
        'status': AppointmentStatus.cancelled.name,
        'cancelledBy': cancelledBy,
        'cancellationReason': cancellationReason ?? 'No reason provided',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get appointment details for notifications
      final doc = await _appointmentsCollection.doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final patientId = data['patientId'];
        final doctorId = data['doctorId'];

        // Notify both parties
        await _dbService.createNotification(
          userId: cancelledBy == patientId ? doctorId : patientId,
          title: 'Appointment Cancelled',
          message: 'An appointment has been cancelled',
          type: 'appointment',
        );

        // Log activity
        await _dbService.logActivity(
          userId: cancelledBy,
          action: 'appointment_cancelled',
          resourceType: 'appointment',
          resourceId: id,
          details: {'reason': cancellationReason ?? 'No reason'},
        );
      }
    } catch (e) {
      throw Exception('Failed to cancel appointment: ${e.toString()}');
    }
  }

  // Reschedule appointment
  Future<void> rescheduleAppointment({
    required String id,
    required DateTime newStartTime,
    required DateTime newEndTime,
    required String userId,
  }) async {
    try {
      // Get current appointment
      final doc = await _appointmentsCollection.doc(id).get();
      if (!doc.exists) {
        throw Exception('Appointment not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      final appointment = AppointmentModel.fromMap(data, id);

      // Check for conflicts with new time (excluding this appointment)
      final hasTimeConflict = await hasConflict(
        doctorId: appointment.doctorId,
        startTime: newStartTime,
        endTime: newEndTime,
        excludeAppointmentId: id,
      );

      if (hasTimeConflict) {
        throw Exception('The new time slot is not available');
      }

      // Update appointment
      await _appointmentsCollection.doc(id).update({
        'startTime': Timestamp.fromDate(newStartTime),
        'endTime': Timestamp.fromDate(newEndTime),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify both parties
      await _dbService.createNotification(
        userId: appointment.patientId,
        title: 'Appointment Rescheduled',
        message: 'Your appointment has been rescheduled',
        type: 'appointment',
      );

      await _dbService.createNotification(
        userId: appointment.doctorId,
        title: 'Appointment Rescheduled',
        message: 'An appointment has been rescheduled',
        type: 'appointment',
      );

      // Log activity
      await _dbService.logActivity(
        userId: userId,
        action: 'appointment_rescheduled',
        resourceType: 'appointment',
        resourceId: id,
        details: {
          'oldStartTime': appointment.startTime.toDate().toString(),
          'newStartTime': newStartTime.toString(),
        },
      );
    } catch (e) {
      throw Exception('Failed to reschedule appointment: ${e.toString()}');
    }
  }

  // Update appointment
  Future<void> updateAppointment(String id, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _appointmentsCollection.doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update appointment: ${e.toString()}');
    }
  }

  // Update appointment status
  Future<void> updateAppointmentStatus(
    String id,
    AppointmentStatus status,
    String userId,
  ) async {
    try {
      await _appointmentsCollection.doc(id).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log activity
      await _dbService.logActivity(
        userId: userId,
        action: 'appointment_status_updated',
        resourceType: 'appointment',
        resourceId: id,
        details: {'newStatus': status.name},
      );

      // Get appointment to send notification
      DocumentSnapshot doc = await _appointmentsCollection.doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final patientId = data['patientId'];
        
        // Notify patient
        await _dbService.createNotification(
          userId: patientId,
          title: 'Appointment ${status.name}',
          message: 'Your appointment has been ${status.name}',
          type: 'appointment',
        );
      }
    } catch (e) {
      throw Exception('Failed to update status: ${e.toString()}');
    }
  }

  // Delete appointment
  Future<void> deleteAppointment(String id, String userId) async {
    try {
      await _appointmentsCollection.doc(id).delete();

      // Log activity
      await _dbService.logActivity(
        userId: userId,
        action: 'appointment_deleted',
        resourceType: 'appointment',
        resourceId: id,
        details: {},
      );
    } catch (e) {
      throw Exception('Failed to delete appointment: ${e.toString()}');
    }
  }

  // Get appointments by doctor ID (stream)
  Stream<List<AppointmentModel>> getAppointmentsByDoctor(String doctorId) {
    return _appointmentsCollection
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) {
      final appointments = snapshot.docs
          .map((doc) => AppointmentModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
      
      // Sort on client side by startTime to avoid needing Firestore index
      appointments.sort((a, b) => a.startTime.compareTo(b.startTime));
      return appointments;
    });
  }

  // Get appointments by patient ID (stream)
  Stream<List<AppointmentModel>> getAppointmentsByPatient(String patientId) {
    return _appointmentsCollection
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
      final appointments = snapshot.docs
          .map((doc) => AppointmentModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
      
      // Sort on client side by startTime to avoid needing Firestore index
      appointments.sort((a, b) => a.startTime.compareTo(b.startTime));
      return appointments;
    });
  }

  // Get today's appointments for a doctor
  Stream<List<AppointmentModel>> getTodayAppointmentsByDoctor(String doctorId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _appointmentsCollection
        .where('doctorId', isEqualTo: doctorId)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
      final appointments = snapshot.docs
          .map((doc) => AppointmentModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
      
      // Sort on client side by startTime
      appointments.sort((a, b) => a.startTime.compareTo(b.startTime));
      return appointments;
    });
  }

  // Get pending appointments for a doctor
  Stream<List<AppointmentModel>> getPendingAppointmentsByDoctor(String doctorId) {
    return _appointmentsCollection
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final appointments = snapshot.docs
          .map((doc) => AppointmentModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
      
      // Sort on client side by startTime
      appointments.sort((a, b) => a.startTime.compareTo(b.startTime));
      return appointments;
    });
  }

  // Get appointment by ID
  Future<AppointmentModel?> getAppointmentById(String id) async {
    try {
      DocumentSnapshot doc = await _appointmentsCollection.doc(id).get();
      if (doc.exists) {
        return AppointmentModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get appointment: ${e.toString()}');
    }
  }

  // Get appointment count for a doctor
  Future<int> getAppointmentCountByDoctor(String doctorId) async {
    try {
      QuerySnapshot snapshot = await _appointmentsCollection
          .where('doctorId', isEqualTo: doctorId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Get today's appointment count for a doctor
  Future<int> getTodayAppointmentCount(String doctorId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      QuerySnapshot snapshot = await _appointmentsCollection
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Get pending appointment count for a doctor
  Future<int> getPendingAppointmentCount(String doctorId) async {
    try {
      QuerySnapshot snapshot = await _appointmentsCollection
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}

