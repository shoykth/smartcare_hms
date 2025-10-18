# 🚀 Run Your App - Quick Commands

## After Completing Firebase Setup

Once you've enabled Authentication and Firestore in Firebase Console, run:

### Option 1: Run on Android (Recommended)
```bash
cd smartcare_hms
flutter clean
flutter pub get
flutter run
```

### Option 2: Run on Web Browser
```bash
cd smartcare_hms
flutter run -d chrome
```

### Option 3: Build Android APK
```bash
cd smartcare_hms
flutter build apk --release
```
APK will be in: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🎯 What to Test:

1. **Sign Up:**
   - Click "Sign Up"
   - Enter name, email, password
   - Select role (Admin, Doctor, or Patient)
   - Create account

2. **Email Verification:**
   - Check your email inbox
   - Click verification link
   - Return to app (it auto-detects)

3. **Login:**
   - Enter email and password
   - Click "Login"
   - Should redirect to your role-specific dashboard

4. **Test Different Roles:**
   - Create accounts for each role
   - See different dashboards

---

## ✅ Firebase Services Required:

Before running, make sure these are enabled in Firebase Console:
- [x] Authentication → Email/Password
- [x] Firestore Database (test mode)
- [ ] Storage (optional)

---

## 🐛 If You Get Errors:

### "No Firebase App created"
- Make sure Authentication and Firestore are enabled

### Build errors
```bash
cd smartcare_hms
flutter clean
flutter pub get
flutter run
```

### "PERMISSION_DENIED"
- Check Firestore is in test mode

---

Ready to run! 🎉

