import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility to fix doctor synchronization issues
/// This script will:
/// 1. Find all doctor users in the users collection
/// 2. Check if they have corresponding records in the doctors collection
/// 3. Create missing doctor records with the correct UID
/// 4. Fix any doctor records that have wrong IDs
class FixDoctorSync {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Main method to fix all doctor synchronization issues
  Future<void> fixAllDoctorSync() async {
    print('🔧 Starting comprehensive doctor sync fix...\n');
    
    try {
      await _syncDoctorUsersToCollection();
      await _fixMismatchedDoctorRecords();
      await _cleanupOrphanedDoctorRecords();
      
      print('\n✅ Doctor sync fix completed successfully!');
    } catch (e) {
      print('\n❌ Error during doctor sync fix: ${e.toString()}');
      rethrow;
    }
  }

  /// Sync all doctor users to doctors collection with correct UIDs
  Future<void> _syncDoctorUsersToCollection() async {
    try {
      print('🔄 Step 1: Syncing doctor users to doctors collection...');
      
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

          // Check if doctor record already exists with correct UID
          final doctorDoc = await _firestore
              .collection('doctors')
              .doc(uid)
              .get();

          if (doctorDoc.exists) {
            print('✅ Doctor record already exists for ${userData['name']} ($uid)');
            skipped++;
            continue;
          }

          // Create doctor record with correct UID
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
      print('   📊 Total: ${usersSnapshot.docs.length}\n');

    } catch (e) {
      print('❌ Fatal error during doctor sync: ${e.toString()}');
      rethrow;
    }
  }

  /// Fix doctor records that have mismatched IDs
  Future<void> _fixMismatchedDoctorRecords() async {
    try {
      print('🔄 Step 2: Fixing mismatched doctor records...');
      
      // Get all doctor records
      final doctorsSnapshot = await _firestore
          .collection('doctors')
          .get();

      print('📊 Found ${doctorsSnapshot.docs.length} doctor records');

      int fixed = 0;
      int correct = 0;
      int errors = 0;

      for (var doctorDoc in doctorsSnapshot.docs) {
        try {
          final doctorData = doctorDoc.data();
          final documentId = doctorDoc.id;
          final doctorId = doctorData['id'];

          // Check if document ID matches the doctor's ID field
          if (documentId == doctorId) {
            correct++;
            continue;
          }

          print('🔧 Fixing mismatched record: Doc ID: $documentId, Doctor ID: $doctorId');

          // Check if there's a user with this doctor ID
          final userDoc = await _firestore
              .collection('users')
              .doc(doctorId)
              .get();

          if (userDoc.exists && userDoc.data()?['role'] == 'doctor') {
            // Create new record with correct UID and delete old one
            await _firestore
                .collection('doctors')
                .doc(doctorId)
                .set(doctorData);

            await _firestore
                .collection('doctors')
                .doc(documentId)
                .delete();

            print('✅ Fixed doctor record for ${doctorData['name']} (moved to correct UID: $doctorId)');
            fixed++;
          } else {
            print('⚠️  No matching user found for doctor ID: $doctorId');
          }

        } catch (e) {
          print('❌ Error fixing doctor record ${doctorDoc.id}: ${e.toString()}');
          errors++;
        }
      }

      print('\n📈 FIX SUMMARY:');
      print('   ✅ Fixed: $fixed');
      print('   ✅ Already correct: $correct');
      print('   ❌ Errors: $errors\n');

    } catch (e) {
      print('❌ Fatal error during mismatch fix: ${e.toString()}');
      rethrow;
    }
  }

  /// Clean up orphaned doctor records (doctors without corresponding users)
  Future<void> _cleanupOrphanedDoctorRecords() async {
    try {
      print('🔄 Step 3: Cleaning up orphaned doctor records...');
      
      // Get all doctor records
      final doctorsSnapshot = await _firestore
          .collection('doctors')
          .get();

      print('📊 Checking ${doctorsSnapshot.docs.length} doctor records for orphans');

      int cleaned = 0;
      int valid = 0;
      int errors = 0;

      for (var doctorDoc in doctorsSnapshot.docs) {
        try {
          final doctorData = doctorDoc.data();
          final doctorId = doctorData['id'];

          // Check if there's a corresponding user
          final userDoc = await _firestore
              .collection('users')
              .doc(doctorId)
              .get();

          if (userDoc.exists && userDoc.data()?['role'] == 'doctor') {
            valid++;
            continue;
          }

          // This is an orphaned record
          print('🗑️  Removing orphaned doctor record: ${doctorData['name']} ($doctorId)');
          
          await _firestore
              .collection('doctors')
              .doc(doctorDoc.id)
              .delete();

          cleaned++;

        } catch (e) {
          print('❌ Error checking doctor record ${doctorDoc.id}: ${e.toString()}');
          errors++;
        }
      }

      print('\n📈 CLEANUP SUMMARY:');
      print('   🗑️  Cleaned: $cleaned');
      print('   ✅ Valid: $valid');
      print('   ❌ Errors: $errors\n');

    } catch (e) {
      print('❌ Fatal error during cleanup: ${e.toString()}');
      rethrow;
    }
  }

  /// Quick method to just sync missing doctors (most common case)
  Future<void> quickSyncMissingDoctors() async {
    print('⚡ Quick sync: Adding missing doctor records...\n');
    await _syncDoctorUsersToCollection();
  }
}