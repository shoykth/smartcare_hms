import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/doctor_model.dart';
import 'database_service.dart';

class DoctorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final DatabaseService _dbService = DatabaseService();

  // Collection reference
  CollectionReference get _doctorsCollection => _firestore.collection('doctors');

  // Add new doctor
  Future<String> addDoctor(DoctorModel doctor) async {
    try {
      DocumentReference docRef = await _doctorsCollection.add(doctor.toMap());
      
      // Log activity
      await _dbService.logActivity(
        userId: doctor.id,
        action: 'doctor_created',
        resourceType: 'doctor',
        resourceId: docRef.id,
        details: {
          'doctorName': doctor.name,
          'specialization': doctor.specialization,
        },
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add doctor: ${e.toString()}');
    }
  }

  // Update doctor
  Future<void> updateDoctor(String id, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _doctorsCollection.doc(id).update(data);

      // Log activity
      await _dbService.logActivity(
        userId: id,
        action: 'doctor_updated',
        resourceType: 'doctor',
        resourceId: id,
        details: {'updatedFields': data.keys.toList()},
      );
    } catch (e) {
      throw Exception('Failed to update doctor: ${e.toString()}');
    }
  }

  // Delete doctor
  Future<void> deleteDoctor(String id, String userId) async {
    try {
      await _doctorsCollection.doc(id).delete();

      // Log activity
      await _dbService.logActivity(
        userId: userId,
        action: 'doctor_deleted',
        resourceType: 'doctor',
        resourceId: id,
        details: {},
      );
    } catch (e) {
      throw Exception('Failed to delete doctor: ${e.toString()}');
    }
  }

  // Get all doctors (stream for real-time updates)
  Stream<List<DoctorModel>> getDoctors() {
    return _doctorsCollection
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DoctorModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    });
  }

  // Get doctors by specialization
  Stream<List<DoctorModel>> getDoctorsBySpecialization(String specialization) {
    return _doctorsCollection
        .where('specialization', isEqualTo: specialization)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DoctorModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    });
  }

  // Get doctors by department
  Stream<List<DoctorModel>> getDoctorsByDepartment(String department) {
    return _doctorsCollection
        .where('department', isEqualTo: department)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DoctorModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    });
  }

  // Get single doctor by ID
  Future<DoctorModel?> getDoctorById(String id) async {
    try {
      DocumentSnapshot doc = await _doctorsCollection.doc(id).get();
      if (doc.exists) {
        return DoctorModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get doctor: ${e.toString()}');
    }
  }

  // Get doctor by user ID (link between users and doctors collections)
  Future<DoctorModel?> getDoctorByUserId(String userId) async {
    try {
      QuerySnapshot snapshot = await _doctorsCollection
          .where('id', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return DoctorModel.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>,
          snapshot.docs.first.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get doctor by user ID: ${e.toString()}');
    }
  }

  // Search doctors by name
  Stream<List<DoctorModel>> searchDoctors(String query) {
    return _doctorsCollection
        .orderBy('name')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DoctorModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    });
  }

  // Get doctor count
  Future<int> getDoctorCount() async {
    try {
      QuerySnapshot snapshot = await _doctorsCollection.get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Upload profile image
  Future<String> uploadProfileImage(String doctorId, File imageFile) async {
    try {
      final ref = _storage.ref().child('doctors/$doctorId/profile.jpg');
      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();
      
      // Update doctor document with new image URL
      await updateDoctor(doctorId, {'profileImageUrl': url});
      
      return url;
    } catch (e) {
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  // Toggle availability status
  Future<void> toggleAvailability(String doctorId, bool isAvailable) async {
    try {
      await _doctorsCollection.doc(doctorId).update({
        'isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update availability: ${e.toString()}');
    }
  }

  // Get available doctors
  Stream<List<DoctorModel>> getAvailableDoctors() {
    return _doctorsCollection
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DoctorModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    });
  }
}

