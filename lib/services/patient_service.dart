import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient_model.dart';
import 'database_service.dart';

class PatientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _dbService = DatabaseService();

  // Collection reference
  CollectionReference get _patientsCollection => _firestore.collection('patients');

  // Add new patient
  Future<String> addPatient(PatientModel patient) async {
    try {
      DocumentReference docRef = await _patientsCollection.add(patient.toMap());
      
      // Log activity
      await _dbService.logActivity(
        userId: patient.createdBy,
        action: 'patient_created',
        resourceType: 'patient',
        resourceId: docRef.id,
        details: {
          'patientName': patient.name,
          'patientAge': patient.age,
        },
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add patient: ${e.toString()}');
    }
  }

  // Update patient
  Future<void> updatePatient(String id, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _patientsCollection.doc(id).update(data);

      // Log activity
      if (data.containsKey('createdBy')) {
        await _dbService.logActivity(
          userId: data['createdBy'],
          action: 'patient_updated',
          resourceType: 'patient',
          resourceId: id,
          details: {'updatedFields': data.keys.toList()},
        );
      }
    } catch (e) {
      throw Exception('Failed to update patient: ${e.toString()}');
    }
  }

  // Update medical information only (for doctors)
  Future<void> updateMedicalInfo(
    String id,
    String userId, {
    String? medicalHistory,
    String? allergies,
    String? chronicDiseases,
  }) async {
    try {
      Map<String, dynamic> data = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (medicalHistory != null) data['medicalHistory'] = medicalHistory;
      if (allergies != null) data['allergies'] = allergies;
      if (chronicDiseases != null) data['chronicDiseases'] = chronicDiseases;

      await _patientsCollection.doc(id).update(data);

      // Log activity
      await _dbService.logActivity(
        userId: userId,
        action: 'patient_medical_updated',
        resourceType: 'patient',
        resourceId: id,
        details: {'updatedFields': data.keys.toList()},
      );
    } catch (e) {
      throw Exception('Failed to update medical info: ${e.toString()}');
    }
  }

  // Delete patient
  Future<void> deletePatient(String id, String userId) async {
    try {
      await _patientsCollection.doc(id).delete();

      // Log activity
      await _dbService.logActivity(
        userId: userId,
        action: 'patient_deleted',
        resourceType: 'patient',
        resourceId: id,
        details: {},
      );
    } catch (e) {
      throw Exception('Failed to delete patient: ${e.toString()}');
    }
  }

  // Get all patients (stream for real-time updates)
  Stream<List<PatientModel>> getPatients() {
    return _patientsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      try {
        List<PatientModel> patients = [];
        for (var doc in snapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            final patient = PatientModel.fromMap(data, doc.id);
            patients.add(patient);
          } catch (e) {
            print('PatientService: Error processing patient document ${doc.id}: $e');
            // Continue processing other documents instead of failing completely
          }
        }
        
        if (patients.isEmpty && snapshot.docs.isNotEmpty) {
          print('PatientService: Warning - No patients could be processed from ${snapshot.docs.length} documents');
        }
        
        return patients;
      } catch (e) {
        print('PatientService: Error in getPatients stream: $e');
        rethrow;
      }
    });
  }

  // Get patients created by specific user (for doctors to see their patients)
  Stream<List<PatientModel>> getPatientsByCreator(String creatorId) {
    return _patientsCollection
        .where('createdBy', isEqualTo: creatorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PatientModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    });
  }

  // Get single patient by ID
  Future<PatientModel?> getPatientById(String id) async {
    try {
      DocumentSnapshot doc = await _patientsCollection.doc(id).get();
      if (doc.exists) {
        return PatientModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get patient: ${e.toString()}');
    }
  }

  // Get patient by email
  Future<PatientModel?> getPatientByEmail(String email) async {
    try {
      QuerySnapshot snapshot = await _patientsCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return PatientModel.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>,
          snapshot.docs.first.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get patient by email: ${e.toString()}');
    }
  }

  // Search patients by name
  Stream<List<PatientModel>> searchPatients(String query) {
    return _patientsCollection
        .orderBy('name')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PatientModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    });
  }

  // Get patient count (for dashboard stats)
  Future<int> getPatientCount() async {
    try {
      QuerySnapshot snapshot = await _patientsCollection.get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Get patients by blood group (useful for emergency situations)
  Stream<List<PatientModel>> getPatientsByBloodGroup(String bloodGroup) {
    return _patientsCollection
        .where('bloodGroup', isEqualTo: bloodGroup)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PatientModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    });
  }
}

