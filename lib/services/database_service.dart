import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize admin settings
  Future<void> initializeAdminSettings() async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('admin_settings')
          .doc('general')
          .get();

      if (!doc.exists) {
        await _firestore.collection('admin_settings').doc('general').set({
          'hospitalName': 'SmartCare Hospital',
          'logoUrl': '',
          'supportEmail': 'support@smartcare.com',
          'appointmentFeeDefault': 500,
          'timezone': 'Asia/Dhaka',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error initializing admin settings: $e');
    }
  }

  // Initialize default departments
  Future<void> initializeDepartments() async {
    try {
      final departments = [
        {
          'id': 'dept_cardio',
          'name': 'Cardiology',
          'description': 'Heart and vascular care department',
          'headId': '',
        },
        {
          'id': 'dept_neuro',
          'name': 'Neurology',
          'description': 'Brain and nervous system care',
          'headId': '',
        },
        {
          'id': 'dept_ortho',
          'name': 'Orthopedics',
          'description': 'Bone, joint, and muscle care',
          'headId': '',
        },
        {
          'id': 'dept_pedia',
          'name': 'Pediatrics',
          'description': 'Child healthcare and development',
          'headId': '',
        },
        {
          'id': 'dept_general',
          'name': 'General Medicine',
          'description': 'General healthcare and consultation',
          'headId': '',
        },
        {
          'id': 'dept_derma',
          'name': 'Dermatology',
          'description': 'Skin, hair, and nail care',
          'headId': '',
        },
        {
          'id': 'dept_ent',
          'name': 'ENT',
          'description': 'Ear, nose, and throat care',
          'headId': '',
        },
        {
          'id': 'dept_gyno',
          'name': 'Gynecology',
          'description': 'Women\'s health and reproductive care',
          'headId': '',
        },
      ];

      for (var dept in departments) {
        DocumentSnapshot doc = await _firestore
            .collection('departments')
            .doc(dept['id'] as String)
            .get();

        if (!doc.exists) {
          await _firestore
              .collection('departments')
              .doc(dept['id'] as String)
              .set({
            'name': dept['name'],
            'description': dept['description'],
            'headId': dept['headId'],
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Error initializing departments: $e');
    }
  }

  // Log user activity
  Future<void> logActivity({
    required String userId,
    required String action,
    required String resourceType,
    String? resourceId,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _firestore.collection('activity_logs').add({
        'userId': userId,
        'action': action,
        'resourceType': resourceType,
        'resourceId': resourceId,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

  // Create notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Get user notifications
  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Get all departments
  Stream<QuerySnapshot> getDepartments() {
    return _firestore
        .collection('departments')
        .orderBy('name')
        .snapshots();
  }

  // Get admin settings
  Future<DocumentSnapshot> getAdminSettings() {
    return _firestore.collection('admin_settings').doc('general').get();
  }

  // Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }
}

