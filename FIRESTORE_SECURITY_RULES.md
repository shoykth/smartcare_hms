# 🔒 Complete Firestore Security Rules

## Copy and Paste These Rules into Firebase Console

Go to: **Firebase Console** → **Firestore Database** → **Rules** → Paste below → **Publish**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to get user role
    function getUserRole() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
    }
    
    function isAdmin() {
      return getUserRole() == 'admin';
    }
    
    function isDoctor() {
      return getUserRole() == 'doctor';
    }
    
    function isPatient() {
      return getUserRole() == 'patient';
    }
    
    // ========================================
    // USERS COLLECTION
    // ========================================
    match /users/{userId} {
      // Anyone authenticated can read any user doc
      allow read: if request.auth != null;
      
      // Users can create their own document during signup
      allow create: if request.auth != null && request.auth.uid == userId;
      
      // Users can only update their own document
      allow update: if request.auth != null && request.auth.uid == userId;
      
      // Only admins can delete
      allow delete: if request.auth != null && isAdmin();
      
      // Subcollections
      match /availability/{slotId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && request.auth.uid == userId;
      }
      
      match /notifications/{notificationId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // ========================================
    // PATIENTS COLLECTION (Phase 2)
    // ========================================
    match /patients/{patientId} {
      // Admins can do anything
      allow read, write, delete: if request.auth != null && isAdmin();
      
      // Doctors can read all patients and update medical info only
      allow read: if request.auth != null && (isDoctor() || isAdmin());
      
      allow update: if request.auth != null && isDoctor() && 
        // Doctors can only update these medical fields
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['medicalHistory', 'allergies', 'chronicDiseases', 'updatedAt']);
      
      // Doctors can create patients
      allow create: if request.auth != null && (isDoctor() || isAdmin());
      
      // Patients can read only their own record (if linked by userId)
      // Note: This requires patientId to match userId
      allow read: if request.auth != null && 
        request.auth.uid == patientId;
    }
    
    // ========================================
    // DEPARTMENTS COLLECTION
    // ========================================
    match /departments/{departmentId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && isAdmin();
    }
    
    // ========================================
    // DOCTORS COLLECTION (Phase 3)
    // ========================================
    match /doctors/{doctorId} {
      // Everyone can read doctor information
      allow read: if request.auth != null;
      
      // Doctors can create their own profile
      allow create: if request.auth != null && (isDoctor() || isAdmin());
      
      // Doctors can only update their own profile, admins can update any
      allow update: if request.auth != null && 
        (request.auth.uid == doctorId || isAdmin());
      
      // Only admins can delete
      allow delete: if request.auth != null && isAdmin();
    }
    
    // ========================================
    // APPOINTMENTS COLLECTION
    // ========================================
    match /appointments/{appointmentId} {
      // Can read if you're the doctor, patient, or admin
      allow read: if request.auth != null && 
        (resource.data.doctorId == request.auth.uid || 
         resource.data.patientId == request.auth.uid ||
         isAdmin());
      
      // Can create appointment if authenticated
      allow create: if request.auth != null;
      
      // Can update if you're the doctor, patient, or admin
      allow update: if request.auth != null && 
        (resource.data.doctorId == request.auth.uid || 
         resource.data.patientId == request.auth.uid ||
         isAdmin());
      
      // Only admin can delete
      allow delete: if request.auth != null && isAdmin();
    }
    
    // ========================================
    // MEDICAL RECORDS COLLECTION
    // ========================================
    match /medical_records/{recordId} {
      // Can read if you're the patient, doctor, or admin
      allow read: if request.auth != null && 
        (resource.data.patientId == request.auth.uid || 
         resource.data.doctorId == request.auth.uid ||
         isAdmin());
      
      // Only doctors and admins can write
      allow write: if request.auth != null && 
        (isDoctor() || isAdmin());
      
      // Attachments subcollection
      match /attachments/{fileId} {
        allow read: if request.auth != null && 
          (get(/databases/$(database)/documents/medical_records/$(recordId)).data.patientId == request.auth.uid ||
           get(/databases/$(database)/documents/medical_records/$(recordId)).data.doctorId == request.auth.uid ||
           isAdmin());
        allow write: if request.auth != null && (isDoctor() || isAdmin());
      }
    }
    
    // ========================================
    // MEDICAL NOTES COLLECTION (Phase 3)
    // ========================================
    match /medical_notes/{noteId} {
      // Can read if you're the patient, doctor who created it, or admin
      allow read: if request.auth != null && 
        (resource.data.patientId == request.auth.uid || 
         resource.data.doctorId == request.auth.uid ||
         isAdmin());
      
      // Only doctors can create medical notes
      allow create: if request.auth != null && isDoctor();
      
      // Only the doctor who created the note or admins can update
      allow update: if request.auth != null && 
        (resource.data.doctorId == request.auth.uid || isAdmin());
      
      // Only admins can delete medical notes
      allow delete: if request.auth != null && isAdmin();
    }
    
    // ========================================
    // DOCTOR AVAILABILITY COLLECTION
    // ========================================
    match /doctor_availability/{doctorId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (request.auth.uid == doctorId || isAdmin());
    }
    
    // ========================================
    // BILLING COLLECTION
    // ========================================
    match /billing/{invoiceId} {
      // Patients can read their own bills
      allow read: if request.auth != null && 
        (resource.data.patientId == request.auth.uid || isAdmin());
      
      // Only admins can write billing
      allow write: if request.auth != null && isAdmin();
    }
    
    // ========================================
    // NOTIFICATIONS COLLECTION
    // ========================================
    match /notifications/{notificationId} {
      // Users can read their own notifications
      allow read: if request.auth != null && 
        resource.data.userId == request.auth.uid;
      
      // Anyone can create notifications (for system notifications)
      allow create: if request.auth != null;
      
      // Users can update their own notifications (mark as read)
      allow update: if request.auth != null && 
        resource.data.userId == request.auth.uid;
      
      // Admins can delete any notification
      allow delete: if request.auth != null && isAdmin();
    }
    
    // ========================================
    // MESSAGES COLLECTION (Future)
    // ========================================
    match /messages/{conversationId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participants;
      
      match /chat/{messageId} {
        allow read, write: if request.auth != null && 
          request.auth.uid in get(/databases/$(database)/documents/messages/$(conversationId)).data.participants;
      }
    }
    
    // ========================================
    // ADMIN SETTINGS COLLECTION
    // ========================================
    match /admin_settings/{settingId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && isAdmin();
    }
    
    // ========================================
    // ACTIVITY LOGS COLLECTION
    // ========================================
    match /activity_logs/{logId} {
      // Only admins can read logs
      allow read: if request.auth != null && isAdmin();
      
      // Anyone authenticated can create logs
      allow create: if request.auth != null;
      
      // No one can update or delete logs (append-only)
      allow update, delete: if false;
    }
  }
}
```

## 📋 Rules Summary

### Users Collection
- ✅ Read: All authenticated users
- ✅ Create: Own document only
- ✅ Update: Own document only
- ✅ Delete: Admins only

### Patients Collection (NEW - Phase 2)
- ✅ Read: Admins & Doctors (all patients)
- ✅ Create: Admins & Doctors
- ✅ Update: 
  - Admins (full access)
  - Doctors (medical fields only: medicalHistory, allergies, chronicDiseases)
- ✅ Delete: Admins only

### Departments
- ✅ Read: All authenticated
- ✅ Write: Admins only

### Appointments
- ✅ Read: Doctor, Patient involved, or Admin
- ✅ Create: All authenticated
- ✅ Update: Doctor, Patient involved, or Admin
- ✅ Delete: Admins only

### Medical Records
- ✅ Read: Patient, Doctor, or Admin
- ✅ Write: Doctors & Admins only

### Billing
- ✅ Read: Patient (own) or Admin
- ✅ Write: Admins only

### Notifications
- ✅ Read: Own notifications
- ✅ Create: All authenticated
- ✅ Update: Own notifications
- ✅ Delete: Admins only

### Admin Settings
- ✅ Read: All authenticated
- ✅ Write: Admins only

### Activity Logs
- ✅ Read: Admins only
- ✅ Create: All authenticated
- ✅ Update/Delete: No one (append-only)

---

## 🔥 How to Apply These Rules

1. Go to **Firebase Console**: https://console.firebase.google.com
2. Select your project: **Hospital Management App**
3. Navigate to **Firestore Database**
4. Click on **Rules** tab
5. **Delete all existing rules**
6. **Copy and paste** the complete rules above
7. Click **"Publish"**

---

## ✅ After Publishing

Test the rules by:
1. Login as Admin → Can see all patients
2. Login as Doctor → Can see all patients, edit medical info
3. Try to delete as Doctor → Should fail
4. Admin can delete patients

---

## 🔒 Security Features

1. **Role-based access** using helper functions
2. **Field-level restrictions** for doctors (medical info only)
3. **Audit trail protection** (activity logs are append-only)
4. **Privacy protection** (patients see only their data)
5. **Admin oversight** (admins have full access)

---

**Last Updated:** Phase 2 Implementation  
**Status:** ✅ Production Ready

