import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medical_note_model.dart';
import 'database_service.dart';

class MedicalNoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _dbService = DatabaseService();

  // Collection reference
  CollectionReference get _notesCollection => _firestore.collection('medical_notes');

  // Create new medical note
  Future<String> createMedicalNote(MedicalNoteModel note) async {
    try {
      DocumentReference docRef = await _notesCollection.add(note.toMap());
      
      // Log activity
      await _dbService.logActivity(
        userId: note.doctorId,
        action: 'medical_note_created',
        resourceType: 'medical_note',
        resourceId: docRef.id,
        details: {
          'patientId': note.patientId,
          'diagnosis': note.diagnosis,
        },
      );

      // Create notification for patient
      await _dbService.createNotification(
        userId: note.patientId,
        title: 'New Medical Note',
        message: 'Dr. ${note.doctorName} has added a medical note',
        type: 'medical_note',
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create medical note: ${e.toString()}');
    }
  }

  // Update medical note
  Future<void> updateMedicalNote(String id, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _notesCollection.doc(id).update(data);

      // Log activity
      if (data.containsKey('doctorId')) {
        await _dbService.logActivity(
          userId: data['doctorId'],
          action: 'medical_note_updated',
          resourceType: 'medical_note',
          resourceId: id,
          details: {'updatedFields': data.keys.toList()},
        );
      }
    } catch (e) {
      throw Exception('Failed to update medical note: ${e.toString()}');
    }
  }

  // Delete medical note
  Future<void> deleteMedicalNote(String id, String userId) async {
    try {
      await _notesCollection.doc(id).delete();

      // Log activity
      await _dbService.logActivity(
        userId: userId,
        action: 'medical_note_deleted',
        resourceType: 'medical_note',
        resourceId: id,
        details: {},
      );
    } catch (e) {
      throw Exception('Failed to delete medical note: ${e.toString()}');
    }
  }

  // Get medical notes by patient ID (stream)
  Stream<List<MedicalNoteModel>> getMedicalNotesByPatient(String patientId) {
    return _notesCollection
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MedicalNoteModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    });
  }

  // Get medical notes by doctor ID (stream)
  Stream<List<MedicalNoteModel>> getMedicalNotesByDoctor(String doctorId) {
    return _notesCollection
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MedicalNoteModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    });
  }

  // Get medical notes by appointment ID
  Future<List<MedicalNoteModel>> getMedicalNotesByAppointment(String appointmentId) async {
    try {
      QuerySnapshot snapshot = await _notesCollection
          .where('appointmentId', isEqualTo: appointmentId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => MedicalNoteModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to get medical notes: ${e.toString()}');
    }
  }

  // Get single medical note by ID
  Future<MedicalNoteModel?> getMedicalNoteById(String id) async {
    try {
      DocumentSnapshot doc = await _notesCollection.doc(id).get();
      if (doc.exists) {
        return MedicalNoteModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get medical note: ${e.toString()}');
    }
  }

  // Get medical note count by doctor
  Future<int> getMedicalNoteCountByDoctor(String doctorId) async {
    try {
      QuerySnapshot snapshot = await _notesCollection
          .where('doctorId', isEqualTo: doctorId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Get medical note count by patient
  Future<int> getMedicalNoteCountByPatient(String patientId) async {
    try {
      QuerySnapshot snapshot = await _notesCollection
          .where('patientId', isEqualTo: patientId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Search medical notes by diagnosis
  Stream<List<MedicalNoteModel>> searchNotesByDiagnosis(String query) {
    return _notesCollection
        .orderBy('diagnosis')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MedicalNoteModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    });
  }
}

