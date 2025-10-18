# 🗂️ SmartCare HMS - Complete Database Structure

## Overview

SmartCare HMS uses **Cloud Firestore** as the NoSQL database. All collections and documents are automatically created when users interact with the system.

---

## 📊 Collections & Documents

### 1️⃣ **users** Collection
**Path:** `/users/{userId}`

Stores all user profiles (Admin, Doctor, Patient)

**Fields:**
```javascript
{
  uid: string,                    // Firebase Auth UID
  name: string,                   // Full name
  email: string,                  // Email address
  role: string,                   // "admin" | "doctor" | "patient"
  phone: string?,                 // Phone number (optional)
  gender: string?,                // "male" | "female" | "other"
  dateOfBirth: string?,           // Format: "YYYY-MM-DD"
  address: string?,               // Full address
  profileImage: string?,          // Firebase Storage URL
  
  // Doctor-specific fields
  specialization: string?,        // e.g., "Cardiology"
  departmentId: string?,          // Reference to department
  registrationNo: string?,        // Medical registration number
  experience: number?,            // Years of experience
  
  // General fields
  bloodGroup: string?,            // e.g., "A+", "O-"
  status: string,                 // "active" | "inactive"
  isEmailVerified: boolean,       // Email verification status
  createdAt: Timestamp,           // Account creation time
  updatedAt: Timestamp            // Last update time
}
```

**Example Document:**
```javascript
/users/abc123def456 {
  uid: "abc123def456",
  name: "Dr. Sarah Johnson",
  email: "sarah.johnson@smartcare.com",
  role: "doctor",
  phone: "+1234567890",
  gender: "female",
  dateOfBirth: "1985-06-15",
  address: "123 Medical Plaza, City",
  profileImage: "https://firebasestorage.googleapis.com/...",
  specialization: "Cardiology",
  departmentId: "dept_cardio",
  registrationNo: "MD-12345",
  experience: 10,
  bloodGroup: "A+",
  status: "active",
  isEmailVerified: true,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**Subcollections:**
- `/users/{userId}/availability/{slotId}` - Doctor availability slots
- `/users/{userId}/notifications/{notificationId}` - User notifications

---

### 2️⃣ **departments** Collection
**Path:** `/departments/{departmentId}`

Stores hospital departments

**Fields:**
```javascript
{
  name: string,              // Department name
  description: string,       // Department description
  headId: string,           // User ID of department head
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**Default Departments Created:**
- `dept_cardio` - Cardiology
- `dept_neuro` - Neurology
- `dept_ortho` - Orthopedics
- `dept_pedia` - Pediatrics
- `dept_general` - General Medicine
- `dept_derma` - Dermatology
- `dept_ent` - ENT
- `dept_gyno` - Gynecology

---

### 3️⃣ **appointments** Collection
**Path:** `/appointments/{appointmentId}`

Stores all appointment bookings

**Fields:**
```javascript
{
  doctorId: string,           // Reference to doctor user
  patientId: string,          // Reference to patient user
  createdBy: string,          // User who created appointment
  startTime: Timestamp,       // Appointment start time
  endTime: Timestamp,         // Appointment end time
  status: string,             // "pending" | "confirmed" | "cancelled" | "completed"
  notes: string,              // Patient notes/complaints
  reason: string,             // Reason for visit
  paymentStatus: string,      // "paid" | "unpaid"
  meetingType: string,        // "physical" | "video"
  meetingLink: string?,       // For telemedicine
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**Composite Index Needed:**
- `(doctorId, startTime)` - For doctor schedule queries

---

### 4️⃣ **doctor_availability** Collection
**Path:** `/doctor_availability/{doctorId}`

Stores doctor working hours and availability

**Fields:**
```javascript
{
  doctorId: string,
  dayOfWeek: number,          // 0=Sunday, 1=Monday, ..., 6=Saturday
  startTime: string,          // "09:00"
  endTime: string,            // "17:00"
  slotDurationMinutes: number, // 20, 30, etc.
  exceptions: [
    {
      date: string,           // "2025-10-31"
      isOff: boolean          // true if doctor is off
    }
  ],
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

---

### 5️⃣ **medical_records** Collection
**Path:** `/medical_records/{recordId}`

Stores patient medical records

**Fields:**
```javascript
{
  patientId: string,
  doctorId: string,
  appointmentId: string?,
  diagnosis: string,
  prescriptions: [
    {
      name: string,           // Medicine name
      dosage: string,         // "1 tablet daily"
      duration: string        // "30 days"
    }
  ],
  labTests: [
    {
      testName: string,       // "ECG", "Blood Test"
      result: string,         // "Normal"
      date: string           // "2025-10-17"
    }
  ],
  remarks: string,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**Subcollection:**
- `/medical_records/{recordId}/attachments/{fileId}` - Lab reports, images (PDFs stored in Firebase Storage)

---

### 6️⃣ **billing** Collection
**Path:** `/billing/{invoiceId}`

Stores billing and payment information

**Fields:**
```javascript
{
  appointmentId: string?,
  patientId: string,
  doctorId: string?,
  amount: number,             // Base amount
  discount: number,           // Discount amount
  total: number,              // Final total
  paymentMethod: string,      // "cash" | "card" | "bkash" | "online"
  paymentStatus: string,      // "paid" | "pending" | "failed"
  transactionId: string?,     // Payment transaction ID
  issuedBy: string,          // Admin/staff user ID
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

---

### 7️⃣ **notifications** Collection
**Path:** `/notifications/{notificationId}`

Stores user notifications

**Fields:**
```javascript
{
  userId: string,
  title: string,              // Notification title
  message: string,            // Notification message
  type: string,               // "appointment" | "system" | "reminder"
  read: boolean,              // Read status
  createdAt: Timestamp
}
```

**Auto-Created Notifications:**
- Welcome message on registration
- Email verification reminder
- Appointment confirmations (Phase 2)

---

### 8️⃣ **messages** Collection (Future - Phase 5)
**Path:** `/messages/{conversationId}`

For chat/messaging system

**Fields:**
```javascript
{
  participants: [string],     // Array of user IDs
  lastMessage: string,
  lastMessageTime: Timestamp,
  createdAt: Timestamp
}
```

**Subcollection:**
- `/messages/{conversationId}/chat/{messageId}` - Individual messages

---

### 9️⃣ **admin_settings** Collection
**Path:** `/admin_settings/{settingId}`

System-wide configuration

**Document: `general`**
```javascript
{
  hospitalName: "SmartCare Hospital",
  logoUrl: string,
  supportEmail: "support@smartcare.com",
  appointmentFeeDefault: 500,
  timezone: "Asia/Dhaka",
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**Auto-initialized on first user registration**

---

### 🔟 **activity_logs** Collection
**Path:** `/activity_logs/{logId}`

Audit trail for all system activities

**Fields:**
```javascript
{
  userId: string,             // User who performed action
  action: string,             // "user_registered", "user_login", "created_appointment"
  resourceType: string,       // "user", "appointment", "medical_record"
  resourceId: string?,        // ID of affected resource
  details: object,            // Additional action details
  timestamp: Timestamp
}
```

**Logged Actions:**
- User registration
- User login
- Google sign-in
- Profile updates
- Appointment CRUD (Phase 2)
- Medical record access (Phase 3)

---

## 🔄 Automatic Data Creation

### On User Registration (Email/Password or Google):

1. ✅ **User document created** in `/users/{userId}`
2. ✅ **Departments initialized** (if not exists)
3. ✅ **Admin settings initialized** (if not exists)
4. ✅ **Activity logged** in `/activity_logs`
5. ✅ **Welcome notification created** in `/notifications`

### Database Initialization Service:

The `DatabaseService` class automatically:
- Creates 8 default departments
- Sets up admin settings
- Logs all user activities
- Manages notifications

---

## 🔐 Security Rules

All collections have proper Firestore Security Rules:

- ✅ **users**: Read all (authenticated), write own only
- ✅ **departments**: Read all, write admin only
- ✅ **appointments**: Read/write own appointments only
- ✅ **medical_records**: Access by patient + doctor only
- ✅ **billing**: Read by patient, write admin only
- ✅ **notifications**: Read/write own notifications only
- ✅ **admin_settings**: Read all, write admin only
- ✅ **activity_logs**: Read admin only, create any authenticated

---

## 📈 Indexes Required

Create these composite indexes in Firestore Console:

1. **appointments**
   - Fields: `doctorId` (Ascending), `startTime` (Ascending)

2. **notifications**
   - Fields: `userId` (Ascending), `createdAt` (Descending)

3. **activity_logs**
   - Fields: `userId` (Ascending), `timestamp` (Descending)

---

## 🎯 Implementation Status

### ✅ Phase 1 (Complete):
- [x] Users collection with complete schema
- [x] Departments collection with defaults
- [x] Admin settings initialization
- [x] Notifications system
- [x] Activity logging
- [x] Database service
- [x] Security rules

### 🚧 Phase 2 (Next):
- [ ] Appointments collection
- [ ] Doctor availability
- [ ] Appointment booking flow
- [ ] Appointment notifications

### 🚧 Phase 3 (Future):
- [ ] Medical records
- [ ] Prescriptions
- [ ] Lab test results

### 🚧 Phase 4 (Future):
- [ ] Billing & invoicing
- [ ] Payment integration

### 🚧 Phase 5 (Future):
- [ ] Chat/messaging system
- [ ] Video consultations

---

## 📝 How to Verify Data

### Check Firestore Console:

1. Go to **Firebase Console** → **Firestore Database**
2. You should see these collections after first user registers:
   ```
   📂 users
      └── 📄 {userId}
   📂 departments
      ├── 📄 dept_cardio
      ├── 📄 dept_neuro
      ├── 📄 dept_ortho
      └── ... (8 total)
   📂 admin_settings
      └── 📄 general
   📂 notifications
      └── 📄 {notificationId}
   📂 activity_logs
      └── 📄 {logId}
   ```

---

## 🔧 Database Service Methods

```dart
// Initialize
- initializeAdminSettings()
- initializeDepartments()

// Activity Logging
- logActivity(userId, action, resourceType, resourceId, details)

// Notifications
- createNotification(userId, title, message, type)
- getUserNotifications(userId) → Stream
- markNotificationAsRead(notificationId)

// Queries
- getDepartments() → Stream
- getAdminSettings() → Future

// Updates
- updateUserProfile(userId, data)
```

---

## 💡 Best Practices

1. **Always use `FieldValue.serverTimestamp()`** for timestamps
2. **Log all important activities** for audit trails
3. **Create notifications** for user actions
4. **Update `updatedAt`** field on all document updates
5. **Use transactions** for critical operations (appointments)
6. **Implement pagination** for large collections
7. **Add indexes** before deploying to production

---

**Database Structure:** ✅ Complete  
**Auto-initialization:** ✅ Implemented  
**Security Rules:** ✅ Configured  
**Ready for Phase 2:** ✅ Yes

---

Built with ❤️ using Cloud Firestore

