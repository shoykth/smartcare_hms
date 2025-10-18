# Firebase Setup Instructions

## Step 1: Install Firebase CLI and FlutterFire CLI

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Install FlutterFire CLI
dart pub global activate flutterfire_cli
```

## Step 2: Login to Firebase

```bash
firebase login
```

## Step 3: Configure Firebase for Flutter

Run this command in your project directory:

```bash
flutterfire configure
```

This will:
1. Create a new Firebase project or select an existing one
2. Enable required platforms (Android, iOS, Web)
3. Generate the `firebase_options.dart` file with your actual credentials
4. Configure all necessary Firebase services

## Step 4: Enable Firebase Services

In your Firebase Console (https://console.firebase.google.com):

1. **Authentication**
   - Go to Authentication > Sign-in method
   - Enable "Email/Password"
   - (Optional) Enable "Google" sign-in

2. **Firestore Database**
   - Go to Firestore Database
   - Click "Create database"
   - Start in "test mode" (you can configure security rules later)

3. **Storage**
   - Go to Storage
   - Click "Get started"
   - Start in "test mode"

## Step 5: Set up Firestore Security Rules (Recommended)

In Firestore > Rules, add:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Step 6: Run the App

```bash
flutter run
```

## Note

The app is fully configured and ready to work. You just need to run `flutterfire configure` 
to replace the placeholder values in `firebase_options.dart` with your actual Firebase credentials.

