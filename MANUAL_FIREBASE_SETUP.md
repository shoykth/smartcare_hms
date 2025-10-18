# 🔥 Manual Firebase Setup Guide

## If Firebase CLI is not available, follow these steps:

### Step 1: Create Firebase Project (5 minutes)

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com
   - Sign in with your Google account

2. **Create New Project**
   - Click "Add project"
   - Project name: `smartcare-hms` (or your choice)
   - Accept terms → Continue
   - (Optional) Disable Google Analytics
   - Click "Create project"
   - Wait for setup to complete
   - Click "Continue"

### Step 2: Register Your Flutter App (2 minutes)

#### For Android:
1. In Firebase Console, go to **Project Overview** (top left)
2. Click the **Settings icon** ⚙️ → **Project settings**
3. Scroll down to "Your apps"
4. Click the **Android icon** (robot)
5. Fill in:
   - **Android package name:** `com.example.smartcare_hms`
   - **App nickname:** SmartCare HMS Android
   - Click "Register app"
6. **Download `google-services.json`**
7. **Important:** Save this file to:
   ```
   smartcare_hms/android/app/google-services.json
   ```
8. Click "Next" → "Next" → "Continue to console"

#### For Web:
1. In Project settings, scroll to "Your apps"
2. Click the **Web icon** (</>)
3. Fill in:
   - **App nickname:** SmartCare HMS Web
   - Click "Register app"
4. **Copy the Firebase configuration** (you'll see code like this):
   ```javascript
   const firebaseConfig = {
     apiKey: "AIza...",
     authDomain: "...",
     projectId: "...",
     storageBucket: "...",
     messagingSenderId: "...",
     appId: "..."
   };
   ```
5. Keep this handy - we'll use it in the next step

### Step 3: Update firebase_options.dart (3 minutes)

Open: `smartcare_hms/lib/firebase_options.dart`

Replace the placeholder values with your actual Firebase config:

```dart
// For Web
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_WEB_API_KEY',           // From Firebase config
  appId: 'YOUR_WEB_APP_ID',            // From Firebase config
  messagingSenderId: 'YOUR_SENDER_ID',  // From Firebase config
  projectId: 'YOUR_PROJECT_ID',        // From Firebase config
  authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
);

// For Android
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',      // Get from google-services.json
  appId: 'YOUR_ANDROID_APP_ID',       // Get from google-services.json
  messagingSenderId: 'YOUR_SENDER_ID', // Get from google-services.json
  projectId: 'YOUR_PROJECT_ID',       // Get from google-services.json
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
);
```

**To get Android values from google-services.json:**
- Open `android/app/google-services.json`
- Find these values:
  - `project_id` → projectId
  - `mobilesdk_app_id` → appId
  - `current_key` under `api_key` → apiKey
  - `project_number` → messagingSenderId

### Step 4: Enable Firebase Services (3 minutes)

#### Enable Authentication:
1. In Firebase Console, go to **Build** → **Authentication**
2. Click **"Get started"**
3. Select **"Email/Password"** provider
4. Toggle **Enable**
5. Click **"Save"**
6. ✅ Done!

#### Create Firestore Database:
1. Go to **Build** → **Firestore Database**
2. Click **"Create database"**
3. Select **"Start in test mode"** (for development)
4. Choose your location (e.g., us-central, europe-west, asia-south1)
5. Click **"Enable"**
6. Wait for database creation
7. ✅ Done!

#### (Optional) Enable Storage:
1. Go to **Build** → **Storage**
2. Click **"Get started"**
3. Select **"Start in test mode"**
4. Use same location as Firestore
5. Click **"Done"**
6. ✅ Done!

### Step 5: Configure Firestore Security Rules (2 minutes)

1. In **Firestore Database**, go to **Rules** tab
2. Replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      // Anyone authenticated can read user docs
      allow read: if request.auth != null;
      // Users can only write their own document
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Block all other collections for now
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

3. Click **"Publish"**
4. ✅ Done!

### Step 6: Update Android Configuration (2 minutes)

1. Open: `smartcare_hms/android/build.gradle`
2. Make sure it has:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

3. Open: `smartcare_hms/android/app/build.gradle`
4. Make sure at the bottom it has:
```gradle
apply plugin: 'com.google.gms.google-services'
```

### Step 7: Test Your Setup (1 minute)

Run these commands:

```bash
cd smartcare_hms
flutter clean
flutter pub get
flutter run
```

If everything is configured correctly:
- ✅ App should launch without Firebase errors
- ✅ You should see the login screen
- ✅ You can create an account and receive verification email

---

## 🎯 Quick Verification Checklist

Before running the app, verify:

- [ ] Firebase project created
- [ ] Android app registered in Firebase
- [ ] `google-services.json` downloaded and placed in `android/app/`
- [ ] Web app registered in Firebase
- [ ] `firebase_options.dart` updated with actual credentials
- [ ] Email/Password authentication enabled
- [ ] Firestore database created
- [ ] Firestore security rules configured
- [ ] Android build.gradle files updated

---

## 🐛 Troubleshooting

### "No Firebase App '[DEFAULT]' has been created"
**Fix:** Check that `firebase_options.dart` has your actual credentials, not placeholders

### "Unable to resolve dependency"
**Fix:** Make sure `google-services.json` is in the correct location: `android/app/`

### Build errors
**Fix:**
```bash
cd smartcare_hms
flutter clean
flutter pub get
flutter run
```

### "Permission denied" or "PERMISSION_DENIED"
**Fix:** Check Firestore security rules are configured correctly

---

## 📞 Need Help?

If you get stuck:
1. Check Firebase Console → Project settings → Make sure app is registered
2. Verify `google-services.json` file exists in correct location
3. Check `firebase_options.dart` has real values (not "YOUR_...")
4. Make sure Email/Password auth is enabled in Firebase Console

---

## ✅ Success!

Once configured:
- You can create user accounts
- Email verification will work
- Login/logout will work
- Role-based dashboards will appear

**Time to complete:** ~15 minutes (first time)

---

**Alternative:** If you install Node.js later, you can use:
```bash
npm install -g firebase-tools
flutterfire configure
```
This automates all the above steps!

