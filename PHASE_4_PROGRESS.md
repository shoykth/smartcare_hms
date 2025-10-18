# 🗓️ PHASE 4 PROGRESS - Appointment Scheduling System

## ✅ Completed So Far

### 1. **Enhanced AppointmentModel** ✅
**File:** `lib/models/appointment_model.dart`

**Updates:**
- ✅ Changed from single `date` + `timeSlot` string to `startTime` + `endTime` UTC timestamps
- ✅ Added `createdBy` field (UID of requester)
- ✅ Added `cancelledBy` and `cancellationReason` fields
- ✅ Added helper methods:
  - `durationMinutes` - Calculate appointment duration
  - `isPast` - Check if appointment is in the past
  - `isUpcoming` - Check if appointment is upcoming
  - `timeSlot` - Get formatted time slot string (backward compatible)
  - `overlapsWith(DateTime start, DateTime end)` - Check for time conflicts
  - `parseDateTime(DateTime date, String time)` - Parse time strings to UTC timestamps

**New Fields:**
```dart
final Timestamp startTime;     // UTC timestamp
final Timestamp endTime;       // UTC timestamp  
final String createdBy;        // Patient UID
final String? cancelledBy;     // Who cancelled
final String? cancellationReason;
```

---

### 2. **Doctor Availability Model** ✅
**File:** `lib/models/doctor_availability_model.dart`

**Features:**
- Weekly recurring availability (Monday-Sunday)
- Time ranges per day (e.g., "09:00" to "17:00")
- Configurable slot duration (20, 30, 60 minutes)
- Exception dates (days off, holidays)
- Active/inactive toggle
- Methods to generate time slots and check availability

**Data Structure:**
```dart
{
  doctorId: string,
  dayOfWeek: 1-7,           // 1=Monday, 7=Sunday
  startTime: "09:00",       // 24-hour format
  endTime: "17:00",
  slotDurationMinutes: 30,
  exceptions: [
    {
      date: DateTime,
      isOff: bool,
      reason: string
    }
  ],
  isActive: bool,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

---

### 3. **Doctor Availability Service** ✅
**File:** `lib/services/doctor_availability_service.dart`

**Functions:**
- ✅ `setAvailability()` - Create or update availability for a day
- ✅ `getAvailabilityForDoctor()` - Stream of all availability rules
- ✅ `getAvailabilityForDay()` - Get availability for specific day
- ✅ `deleteAvailability()` - Remove availability rule
- ✅ `addException()` - Add day off or special hours
- ✅ `removeException()` - Remove exception
- ✅ `generateAvailableSlots()` - Generate available time slots for date range
- ✅ `isDoctorAvailableAt()` - Check if doctor available at specific time
- ✅ `toggleAvailability()` - Enable/disable availability

**Key Features:**
- Conflict detection with existing appointments
- Filters past time slots
- Respects exceptions (holidays, days off)
- Activity logging

---

## 🚧 Remaining Tasks

### 4. **Enhance AppointmentService** (In Progress)
**File:** `lib/services/appointment_service.dart`

**Need to Add:**
- [ ] Conflict checking before creating appointment
- [ ] Use Firestore transactions for atomic operations
- [ ] Range queries for overlapping appointments
- [ ] Cancel appointment with reason
- [ ] Reschedule appointment
- [ ] Better error messages for conflicts

**Conflict Check Logic:**
```dart
// Query: Find appointments where:
// startTime < newEndTime AND endTime > newStartTime
final conflicts = await _firestore
  .collection('appointments')
  .where('doctorId', isEqualTo: doctorId)
  .where('startTime', isLessThan: newEndTime)
  .where('endTime', isGreaterThan: newStartTime)
  .where('status', whereIn: ['pending', 'confirmed'])
  .get();

if (conflicts.docs.isNotEmpty) {
  throw Exception('Time slot conflict');
}
```

---

### 5. **Doctor Availability Management Screen** (Pending)
**File:** `lib/screens/doctor/doctor_availability_screen.dart`

**UI Features Needed:**
- [ ] Weekly calendar grid (Mon-Sun)
- [ ] Time picker for start/end times
- [ ] Slot duration selector (15, 20, 30, 60 mins)
- [ ] Add exceptions (date picker + reason)
- [ ] List of upcoming exceptions with delete option
- [ ] Active/inactive toggle per day
- [ ] Save button with validation

**Flow:**
1. Doctor selects day of week
2. Sets time range (e.g., 9 AM - 5 PM)
3. Sets slot duration
4. Can add exceptions (holidays, vacations)
5. Save to Firestore

---

### 6. **Patient Booking Flow** (Pending)
**File:** `lib/screens/appointments/book_appointment_screen.dart`

**UI Flow:**
1. **Select Doctor**
   - List of doctors by specialty
   - Or search by name
   
2. **Select Date**
   - Calendar widget
   - Highlight available dates
   - Disable unavailable dates
   
3. **Select Time Slot**
   - Show available slots for selected date
   - Format: "09:00 AM - 09:30 AM"
   - Disable booked/past slots
   
4. **Enter Details**
   - Reason for visit (required)
   - Additional notes (optional)
   - Meeting type (physical/video)
   
5. **Confirm**
   - Show summary
   - Create appointment
   - Show success/error

**API Calls:**
```dart
// Get available slots
final slots = await availabilityService.generateAvailableSlots(
  doctorId: selectedDoctorId,
  startDate: selectedDate,
  endDate: selectedDate.add(Duration(days: 1)),
  existingAppointments: existingAppointments,
);

// Book appointment
final appointment = AppointmentModel(
  doctorId: doctorId,
  patientId: currentUserId,
  startTime: selectedSlot,
  endTime: selectedSlot.add(Duration(minutes: 30)),
  createdBy: currentUserId,
  // ... other fields
);

await appointmentService.createAppointment(appointment);
```

---

### 7. **Patient Appointments Screen** (Pending)
**File:** `lib/screens/appointments/patient_appointments_screen.dart`

**Features:**
- [ ] List of upcoming appointments
- [ ] List of past appointments
- [ ] Tabs: Upcoming / Past / Cancelled
- [ ] Appointment cards with:
  - Doctor name and specialty
  - Date and time
  - Status badge
  - Tap to view details
- [ ] FAB to book new appointment

---

### 8. **Appointment Details Screen** (Pending)
**File:** `lib/screens/appointments/appointment_detail_screen.dart`

**Features:**
- [ ] Full appointment information
- [ ] Doctor profile card
- [ ] Date, time, duration
- [ ] Reason and notes
- [ ] Actions (role-based):
  - **Patient:** Cancel, Reschedule
  - **Doctor:** Confirm, Reject, Complete, Add Notes
  - **Admin:** All actions
- [ ] Status history timeline

---

### 9. **Calendar Integration** (Pending)
**Dependencies:** Add to `pubspec.yaml`
```yaml
dependencies:
  add_2_calendar: ^3.0.1
  device_calendar: ^4.3.2
```

**Features:**
- [ ] Add confirmed appointment to device calendar
- [ ] Export appointment as ICS file
- [ ] Toggle in settings: Auto-add to calendar
- [ ] Update calendar when rescheduled
- [ ] Remove from calendar when cancelled

---

### 10. **Notifications System** (Pending)
**Dependencies:** Add to `pubspec.yaml`
```yaml
dependencies:
  flutter_local_notifications: ^17.0.0
  firebase_messaging: ^14.7.10
```

**Features:**
- [ ] Local notifications (for testing)
- [ ] Push notifications via FCM
- [ ] Notification types:
  - Booking confirmation
  - Appointment reminder (24 hours before)
  - Appointment reminder (1 hour before)
  - Status changes (confirmed, cancelled)
  - Doctor notes added
- [ ] Notification preferences in settings
- [ ] Notification history

**Cloud Function (Pseudo-code):**
```javascript
// Firestore trigger: onCreate appointment
exports.onAppointmentCreated = functions.firestore
  .document('appointments/{appointmentId}')
  .onCreate(async (snap, context) => {
    const appointment = snap.data();
    
    // Send confirmation notification
    await sendNotification(appointment.patientId, {
      title: 'Appointment Confirmed',
      body: `Your appointment with Dr. ${appointment.doctorName} is confirmed`,
    });
    
    // Schedule reminders
    await scheduleReminder(appointment, '24h');
    await scheduleReminder(appointment, '1h');
  });
```

---

### 11. **Conflict Handling & Race Conditions** (Pending)
**File:** `lib/services/appointment_service.dart` (enhancement)

**Implementation:**
```dart
Future<String> createAppointmentSafe(AppointmentModel appointment) async {
  return await _firestore.runTransaction((transaction) async {
    // 1. Check for conflicts
    final conflictQuery = await _firestore
      .collection('appointments')
      .where('doctorId', isEqualTo: appointment.doctorId)
      .where('startTime', isLessThan: appointment.endTime)
      .get();
    
    final conflicts = conflictQuery.docs.where((doc) {
      final existing = AppointmentModel.fromMap(doc.data(), doc.id);
      return existing.endTime.toDate().isAfter(appointment.startTime.toDate()) &&
             existing.status != AppointmentStatus.cancelled;
    });
    
    if (conflicts.isNotEmpty) {
      throw Exception('Time slot no longer available');
    }
    
    // 2. Create appointment
    final docRef = _firestore.collection('appointments').doc();
    transaction.set(docRef, appointment.toMap());
    
    return docRef.id;
  });
}
```

**UI Handling:**
```dart
try {
  await appointmentService.createAppointmentSafe(appointment);
  showSuccess('Appointment booked!');
} catch (e) {
  if (e.toString().contains('no longer available')) {
    showError('Oops! This slot was just taken. Please choose another time.');
    // Refresh available slots
    refreshSlots();
  } else {
    showError('Failed to book appointment');
  }
}
```

---

### 12. **Firestore Security Rules** (Pending)
**File:** `FIRESTORE_SECURITY_RULES.md` (update)

**Rules to Add:**
```javascript
// Appointments collection
match /appointments/{appointmentId} {
  // Patients can create appointments for themselves
  allow create: if request.auth != null &&
                request.resource.data.patientId == request.auth.uid &&
                request.resource.data.createdBy == request.auth.uid &&
                request.resource.data.status == 'pending';
  
  // Read: Patient, Doctor, or Admin
  allow read: if request.auth != null &&
              (resource.data.patientId == request.auth.uid ||
               resource.data.doctorId == request.auth.uid ||
               isAdmin());
  
  // Update: Patient (cancel only), Doctor (status updates), Admin (all)
  allow update: if request.auth != null &&
                (
                  // Patient can cancel their own appointment
                  (resource.data.patientId == request.auth.uid &&
                   request.resource.data.status == 'cancelled') ||
                  
                  // Doctor can update status and notes
                  (resource.data.doctorId == request.auth.uid &&
                   request.resource.data.diff(resource.data).affectedKeys()
                     .hasOnly(['status', 'notes', 'updatedAt'])) ||
                  
                  // Admin can do anything
                  isAdmin()
                );
  
  // Delete: Only admin
  allow delete: if request.auth != null && isAdmin();
}

// Doctor availability collection
match /doctor_availability/{availabilityId} {
  // Anyone can read availability
  allow read: if request.auth != null;
  
  // Only the doctor or admin can write
  allow write: if request.auth != null &&
               (resource.data.doctorId == request.auth.uid || isAdmin());
}
```

---

### 13. **Testing Checklist** (Pending)
**File:** Create `test/appointment_test.dart`

**Unit Tests:**
- [ ] `overlapsWith()` method with various scenarios
- [ ] `isDoctorAvailableAt()` with conflicts
- [ ] `generateAvailableSlots()` with exceptions
- [ ] Time slot parsing
- [ ] Conflict detection logic

**Integration Tests:**
- [ ] Create appointment successfully
- [ ] Create conflicting appointment (should fail)
- [ ] Cancel appointment
- [ ] Reschedule appointment
- [ ] Doctor confirms appointment
- [ ] Generate slots for week

**Manual Test Cases:**
1. **Concurrent Booking:**
   - Two patients book same slot simultaneously
   - One should succeed, one should get error
   
2. **Timezone Handling:**
   - Book appointment from different timezone
   - Verify stored as UTC
   - Verify displays in local time
   
3. **Availability Exceptions:**
   - Set doctor as unavailable on a date
   - Verify no slots generated for that date
   
4. **Past Slot Prevention:**
   - Try to book appointment in the past
   - Should be blocked

---

## 📊 Progress Summary

| Task | Status | Priority |
|------|--------|----------|
| AppointmentModel Update | ✅ Complete | High |
| DoctorAvailability Model | ✅ Complete | High |
| DoctorAvailability Service | ✅ Complete | High |
| Enhance AppointmentService | 🚧 In Progress | High |
| Availability Management Screen | ⏳ Pending | High |
| Patient Booking Flow | ⏳ Pending | High |
| Patient Appointments Screen | ⏳ Pending | Medium |
| Appointment Details Screen | ⏳ Pending | Medium |
| Calendar Integration | ⏳ Pending | Low |
| Notifications System | ⏳ Pending | Medium |
| Conflict Handling | ⏳ Pending | High |
| Security Rules | ⏳ Pending | High |
| Testing | ⏳ Pending | Medium |

---

## 🎯 Next Steps (In Order)

### Immediate (Phase 4A):
1. **Enhance AppointmentService** with conflict checking
2. **Update Firestore Security Rules** for appointments
3. **Create Patient Booking Flow** (most important for users)
4. **Create Availability Management Screen** (for doctors)

### Short Term (Phase 4B):
5. **Patient Appointments List** screen
6. **Appointment Details** screen with actions
7. **Conflict handling** and better error messages

### Long Term (Phase 4C):
8. **Notifications system** (local + push)
9. **Calendar integration**
10. **Comprehensive testing**

---

## 🔧 Quick Setup Instructions

### 1. Update Existing Files

The AppointmentModel has breaking changes. You need to update:
- `doctor_appointments_screen.dart` - Update to use `startTime`/`endTime`
- Any code that creates appointments

### 2. Add to pubspec.yaml (Later)

```yaml
dependencies:
  # For calendar integration
  add_2_calendar: ^3.0.1
  device_calendar: ^4.3.2
  
  # For notifications
  flutter_local_notifications: ^17.0.0
  firebase_messaging: ^14.7.10
```

### 3. Update Firebase Security Rules

Copy the new rules from the "Security Rules" section above to Firebase Console.

---

## 📝 Notes

- All timestamps are stored as UTC in Firestore
- Time conversions happen in the UI layer
- Conflict detection uses range queries on startTime/endTime
- Transactions prevent race conditions during booking
- Availability exceptions override regular schedules

---

**Status:** Phase 4 is ~30% complete. Core data models and services are ready. UI screens and integrations pending.

**Estimated Completion:** 15-20 more screens and services to build.

**Recommendation:** Focus on Patient Booking Flow first (highest user value), then doctor availability management, then nice-to-have features like calendar export and advanced notifications.

