import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility to sync existing users to their role-specific collections
/// Run this once to migrate existing data
class SyncUsersToCollections {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sync all doctor users to doctors collection
  Future<void> syncDoctorsToCollection() async {
    try {
      print('🔄 Starting doctor sync...');
      
      // Get all users with doctor role
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();

      print('📊 Found ${usersSnapshot.docs.length} doctor users');

      int synced = 0;
      int skipped = 0;
      int errors = 0;

      for (var userDoc in usersSnapshot.docs) {
        try {
          final userData = userDoc.data();
          final uid = userDoc.id;

          // Check if doctor record already exists
          final doctorDoc = await _firestore
              .collection('doctors')
              .doc(uid)
              .get();

          if (doctorDoc.exists) {
            print('⏭️  Doctor record already exists for ${userData['name']} ($uid)');
            skipped++;
            continue;
          }

          // Create doctor record
          final doctorData = {
            'id': uid,
            'name': userData['name'] ?? 'Unknown',
            'email': userData['email'] ?? '',
            'phone': userData['phone'] ?? '',
            'specialization': userData['specialization'] ?? '',
            'department': userData['departmentId'] ?? '',
            'qualification': '',
            'experience': userData['experience']?.toString() ?? '0 years',
            'rating': 0.0,
            'totalPatients': 0,
            'bio': '',
            'isAvailable': true,
            'profileImageUrl': userData['profileImage'] ?? '',
            'createdAt': userData['createdAt'] ?? FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          await _firestore
              .collection('doctors')
              .doc(uid)
              .set(doctorData);

          print('✅ Created doctor record for ${userData['name']} ($uid)');
          synced++;

        } catch (e) {
          print('❌ Error syncing doctor ${userDoc.id}: ${e.toString()}');
          errors++;
        }
      }

      print('\n📈 SYNC SUMMARY:');
      print('   ✅ Synced: $synced');
      print('   ⏭️  Skipped (already exist): $skipped');
      print('   ❌ Errors: $errors');
      print('   📊 Total: ${usersSnapshot.docs.length}');
      print('\n✨ Doctor sync complete!\n');

    } catch (e) {
      print('❌ Fatal error during doctor sync: ${e.toString()}');
      rethrow;
    }
  }

  /// Sync all patient users to patients collection
  Future<void> syncPatientsToCollection() async {
    try {
      print('🔄 Starting patient sync...');
      
      // Get all users with patient role
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'patient')
          .get();

      print('📊 Found ${usersSnapshot.docs.length} patient users');

      int synced = 0;
      int skipped = 0;
      int errors = 0;

      for (var userDoc in usersSnapshot.docs) {
        try {
          final userData = userDoc.data();
          final uid = userDoc.id;

          // Check if patient record already exists
          final patientDoc = await _firestore
              .collection('patients')
              .doc(uid)
              .get();

          if (patientDoc.exists) {
            print('⏭️  Patient record already exists for ${userData['name']} ($uid)');
            skipped++;
            continue;
          }

          // Create patient record
          final patientData = {
            'id': uid,
            'name': userData['name'] ?? 'Unknown',
            'email': userData['email'] ?? '',
            'phone': userData['phone'] ?? '',
            'dateOfBirth': userData['dateOfBirth'],
            'gender': userData['gender'] ?? '',
            'bloodGroup': userData['bloodGroup'] ?? '',
            'address': userData['address'] ?? '',
            'emergencyContact': '',
            'emergencyContactName': '',
            'allergies': [],
            'chronicConditions': [],
            'currentMedications': [],
            'profileImage': userData['profileImage'] ?? '',
            'insuranceProvider': '',
            'insuranceNumber': '',
            'createdAt': userData['createdAt'] ?? FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          await _firestore
              .collection('patients')
              .doc(uid)
              .set(patientData);

          print('✅ Created patient record for ${userData['name']} ($uid)');
          synced++;

        } catch (e) {
          print('❌ Error syncing patient ${userDoc.id}: ${e.toString()}');
          errors++;
        }
      }

      print('\n📈 SYNC SUMMARY:');
      print('   ✅ Synced: $synced');
      print('   ⏭️  Skipped (already exist): $skipped');
      print('   ❌ Errors: $errors');
      print('   📊 Total: ${usersSnapshot.docs.length}');
      print('\n✨ Patient sync complete!\n');

    } catch (e) {
      print('❌ Fatal error during patient sync: ${e.toString()}');
      rethrow;
    }
  }

  /// Sync all users to their respective collections
  Future<void> syncAllUsers() async {
    print('\n🚀 STARTING FULL USER SYNC\n');
    print('════════════════════════════════════════\n');
    
    await syncDoctorsToCollection();
    print('────────────────────────────────────────\n');
    await syncPatientsToCollection();
    
    print('════════════════════════════════════════');
    print('🎉 FULL SYNC COMPLETE!\n');
  }

  /// Sync a specific user by ID
  Future<void> syncUserById(String userId) async {
    try {
      print('🔄 Syncing user: $userId');

      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        print('❌ User not found: $userId');
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final role = userData['role'];

      if (role == 'doctor') {
        // Check if doctor record exists
        final doctorDoc = await _firestore
            .collection('doctors')
            .doc(userId)
            .get();

        if (doctorDoc.exists) {
          print('⏭️  Doctor record already exists');
          return;
        }

        // Create doctor record
        final doctorData = {
          'id': userId,
          'name': userData['name'] ?? 'Unknown',
          'email': userData['email'] ?? '',
          'phone': userData['phone'] ?? '',
          'specialization': userData['specialization'] ?? '',
          'department': userData['departmentId'] ?? '',
          'qualification': '',
          'experience': userData['experience']?.toString() ?? '0 years',
          'rating': 0.0,
          'totalPatients': 0,
          'bio': '',
          'isAvailable': true,
          'profileImageUrl': userData['profileImage'] ?? '',
          'createdAt': userData['createdAt'] ?? FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('doctors').doc(userId).set(doctorData);
        print('✅ Created doctor record for ${userData['name']}');

      } else if (role == 'patient') {
        // Check if patient record exists
        final patientDoc = await _firestore
            .collection('patients')
            .doc(userId)
            .get();

        if (patientDoc.exists) {
          print('⏭️  Patient record already exists');
          return;
        }

        // Create patient record
        final patientData = {
          'id': userId,
          'name': userData['name'] ?? 'Unknown',
          'email': userData['email'] ?? '',
          'phone': userData['phone'] ?? '',
          'dateOfBirth': userData['dateOfBirth'],
          'gender': userData['gender'] ?? '',
          'bloodGroup': userData['bloodGroup'] ?? '',
          'address': userData['address'] ?? '',
          'emergencyContact': '',
          'emergencyContactName': '',
          'allergies': [],
          'chronicConditions': [],
          'currentMedications': [],
          'profileImage': userData['profileImage'] ?? '',
          'insuranceProvider': '',
          'insuranceNumber': '',
          'createdAt': userData['createdAt'] ?? FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('patients').doc(userId).set(patientData);
        print('✅ Created patient record for ${userData['name']}');

      } else {
        print('⏭️  User role is "$role" - no collection sync needed');
      }

    } catch (e) {
      print('❌ Error syncing user $userId: ${e.toString()}');
      rethrow;
    }
  }
}

