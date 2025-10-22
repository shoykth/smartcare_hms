import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';
import 'lib/utils/fix_doctor_sync.dart';

/// Main script to fix doctor synchronization issue
/// Run this to sync doctors from users collection to doctors collection
/// 
/// Usage:
/// dart run run_doctor_sync_fix.dart
void main() async {
  print('\n🚀 STARTING DOCTOR SYNC FIX\n');
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    print('✅ Firebase initialized\n');
    
    // Run the fix
    final fixUtil = FixDoctorSync();
    await fixUtil.fixAllDoctorSync();
    
    print('🎉 ALL DONE! Your doctors should now appear in appointment booking.\n');
    
  } catch (e) {
    print('❌ FATAL ERROR: ${e.toString()}');
    print('\n💡 If you see authentication errors, make sure you have:');
    print('   1. Proper Firebase configuration');
    print('   2. Admin privileges for Firestore');
    print('   3. Internet connection\n');
  }
}