# 🚀 Quick Start Guide - SmartCare HMS

Get your Hospital Management System up and running in 5 minutes!

## ⚡ Quick Setup (5 Steps)

### Step 1: Install Firebase Tools (1 min)

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

### Step 2: Login to Firebase (30 sec)

```bash
firebase login
```

### Step 3: Configure Firebase (2 min)

```bash
cd smartcare_hms
flutterfire configure
```

**What this does:**
- Creates/selects Firebase project
- Generates configuration files
- Updates `firebase_options.dart` automatically

**During configuration:**
- Select or create a Firebase project
- Choose platforms: Android, iOS, Web (select all)
- Use default options

### Step 4: Enable Firebase Services (1 min)

Open [Firebase Console](https://console.firebase.google.com):

1. **Authentication** → Sign-in method → Enable "Email/Password" ✅
2. **Firestore Database** → Create database → Start in test mode ✅
3. **Storage** (optional) → Get started → Test mode ✅

### Step 5: Run the App (30 sec)

```bash
flutter pub get
flutter run
```

## 🎯 Test the App

### Create Your First User

1. Click "Sign Up" on login screen
2. Enter details:
   - Name: Admin User
   - Email: admin@hospital.com
   - Password: admin123
   - Role: **Admin**
3. Click "Create Account"
4. Check email and click verification link
5. Return to app and login
6. You're in! 🎉

### Test Different Roles

Create multiple accounts to test different dashboards:

**Admin Account:**
- Email: admin@hospital.com
- Role: Admin
- Features: User management, analytics, settings

**Doctor Account:**
- Email: doctor@hospital.com
- Role: Doctor
- Features: Appointments, patient records, prescriptions

**Patient Account:**
- Email: patient@hospital.com
- Role: Patient
- Features: Book appointments, medical records, billing

## 🎨 What You'll See

### Login Screen
- Clean, modern design
- Email and password fields
- Forgot password link
- Sign up option

### Email Verification
- Automatic email sending
- Real-time verification check
- Resend option

### Dashboards (Role-Based)

**Admin Dashboard:**
- Welcome card with user info
- Quick stats (users, doctors, appointments, revenue)
- Management options
- Modern gradient design

**Doctor Dashboard:**
- Professional greeting (Dr. Name)
- Today's schedule
- Quick actions (appointments, records, prescriptions)
- Green theme

**Patient Dashboard:**
- Friendly greeting
- Health overview
- Service options (book appointments, records, billing)
- Blue theme

## 🔧 Common Issues & Fixes

### Issue 1: "Firebase not initialized"
**Solution:**
```bash
flutterfire configure
flutter clean
flutter pub get
flutter run
```

### Issue 2: "Email not sending"
**Fix:** Enable Email/Password in Firebase Console → Authentication → Sign-in method

### Issue 3: "User data not found"
**Fix:** Make sure Firestore Database is created and in test mode

### Issue 4: Build errors
**Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

## 📱 Running on Different Platforms

### Android
```bash
flutter run -d android
```

### iOS (macOS only)
```bash
cd ios
pod install
cd ..
flutter run -d ios
```

### Web
```bash
flutter run -d chrome
```

### Windows
```bash
flutter run -d windows
```

## ✨ Features to Test

- [x] User registration with role selection
- [x] Email verification
- [x] Login/Logout
- [x] Password reset
- [x] Role-based dashboards
- [x] Session persistence (close and reopen app)
- [x] Different user roles

## 🎓 Next Steps

Once you have Phase 1 working:

1. **Explore the code structure** - Check `lib/` folder organization
2. **Customize the UI** - Modify colors in `lib/utils/constants.dart`
3. **Add features** - Ready for Phase 2 (Appointments module)
4. **Test thoroughly** - Try different scenarios

## 📚 Useful Commands

```bash
# Check Flutter setup
flutter doctor

# List available devices
flutter devices

# Hot reload (during development)
# Press 'r' in terminal or Ctrl+S in editor

# Build APK (Android)
flutter build apk

# Build for web
flutter build web

# Run with specific flavor
flutter run --release
```

## 🎯 Expected Output

After successful setup, you should see:

1. **Login Screen** - Clean blue and white design
2. **Registration** - Role selection with radio buttons
3. **Email Verification** - Checking status with timer
4. **Dashboard** - Role-specific with gradient header
5. **Logout** - Returns to login screen

## 🔐 Default Test Credentials

After creating accounts:

```
Admin:
Email: admin@hospital.com
Password: admin123

Doctor:
Email: doctor@hospital.com
Password: doctor123

Patient:
Email: patient@hospital.com
Password: patient123
```

## 🆘 Need Help?

1. Check `FIREBASE_SETUP.md` for detailed Firebase instructions
2. Read `README.md` for full documentation
3. Run `flutter doctor` to check your setup
4. Verify Firebase Console settings

## ✅ Verification Checklist

Before testing, ensure:

- [ ] Flutter is installed (`flutter --version`)
- [ ] Firebase CLI is installed (`firebase --version`)
- [ ] FlutterFire CLI is activated
- [ ] Firebase project is created
- [ ] `flutterfire configure` completed successfully
- [ ] Email/Password auth enabled in Firebase
- [ ] Firestore database created
- [ ] Dependencies installed (`flutter pub get`)

## 🎉 Success!

If you can:
1. ✅ Create an account
2. ✅ Verify email
3. ✅ Login successfully
4. ✅ See your role-specific dashboard
5. ✅ Logout and login again

**Congratulations! Phase 1 is complete!** 🚀

---

**Time to complete:** ~5 minutes
**Difficulty:** Easy
**Status:** Production Ready ✅

