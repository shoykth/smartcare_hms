import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'fix_doctor_sync.dart';

/// Simple script to run the doctor sync fix
/// This can be called from anywhere in the app to fix doctor synchronization issues
Future<void> runDoctorSyncFix() async {
  print('🚀 Initializing doctor sync fix...\n');
  
  try {
    // Ensure Firebase is initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // Run the fix
    final fixer = FixDoctorSync();
    await fixer.fixAllDoctorSync();
    
    print('\n🎉 Doctor sync fix completed successfully!');
    print('📝 Summary:');
    print('   - All doctor users now have corresponding records in doctors collection');
    print('   - All doctor records use correct UIDs as document IDs');
    print('   - Orphaned records have been cleaned up');
    print('   - Doctors should now appear in appointments and admin panels\n');
    
  } catch (e) {
    print('\n💥 Error running doctor sync fix: ${e.toString()}');
    print('🔍 Please check the error details above and try again.\n');
    rethrow;
  }
}

/// Quick fix for just adding missing doctor records
Future<void> runQuickDoctorSync() async {
  print('⚡ Running quick doctor sync...\n');
  
  try {
    // Ensure Firebase is initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // Run the quick sync
    final fixer = FixDoctorSync();
    await fixer.quickSyncMissingDoctors();
    
    print('✅ Quick sync completed! Missing doctor records have been added.\n');
    
  } catch (e) {
    print('💥 Error running quick sync: ${e.toString()}\n');
    rethrow;
  }
}