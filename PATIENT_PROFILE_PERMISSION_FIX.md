# Patient Profile Permission Fix

## Issue Description
Patients were unable to view their own profile in the "My Profile" section of the patient dashboard. The error message displayed was "Profile Not Found" with a Firestore permission denied error.

## Root Cause Analysis
The issue was caused by overly restrictive Firestore security rules for the `patients` collection. The problem occurred because:

1. **Query Method**: The `MyProfileScreen` uses `PatientService.getPatientByEmail()` to fetch patient data
2. **Query Type**: This method performs a `where('email', isEqualTo: email)` query across the patients collection
3. **Security Rule Limitation**: The existing rule only allowed patients to read documents where `patientId == userId`, but didn't account for email-based queries
4. **Permission Denied**: When a patient tried to query by email, Firestore denied access because the query required broader read permissions

## Solution Implemented
Updated the Firestore security rules for the `patients` collection to include an additional rule that allows patients to query their own profile by email address.

### New Rule Added
```javascript
// Allow patients to query their own profile by email
allow read: if request.auth != null && 
  request.auth.token.email == resource.data.email;
```

This rule allows authenticated users to read patient documents where the document's email field matches their authenticated email address.

## Files Modified
1. `FIRESTORE_SECURITY_RULES.md` - Added new read permission rule for email-based queries

## How to Apply the Fix
1. Open Firebase Console
2. Navigate to Firestore Database > Rules
3. Copy the updated rules from `FIRESTORE_SECURITY_RULES.md`
4. Paste them into the Firebase Console
5. Click "Publish" to apply the new rules

## Expected Result
After applying the updated rules:
- Patients can successfully view their own profile in the "My Profile" section
- The "Profile Not Found" error will be resolved
- Patient profile data will load correctly
- Security is maintained - patients can only access their own profile data

## Security Considerations
- The new rule maintains security by only allowing users to read documents where their email matches
- Patients still cannot access other patients' profiles
- The rule works alongside existing rules for admins and doctors
- No sensitive data exposure occurs as patients can only see their own information