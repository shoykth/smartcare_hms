# SmartCare HMS - Hospital Management System

A comprehensive Hospital Management System built with Flutter and Firebase, featuring role-based access control (RBAC) for Admin, Doctor, and Patient roles.

## ✨ Features Implemented (Phase 1)

### 🔐 Authentication & Security
- ✅ User registration with role selection (Admin, Doctor, Patient)
- ✅ Email/Password login
- ✅ Email verification (Multi-Factor Authentication)
- ✅ Password reset functionality
- ✅ Secure session management
- ✅ Auto-logout functionality

### 👥 Role-Based Access Control (RBAC)
- ✅ **Admin Dashboard**: User management, analytics, system settings
- ✅ **Doctor Dashboard**: Appointments, patient records, prescriptions
- ✅ **Patient Dashboard**: Book appointments, medical records, billing

### 🎨 UI/UX
- ✅ Modern Material 3 design
- ✅ Beautiful gradient cards and modern components
- ✅ Responsive and intuitive interface
- ✅ Blue-white color scheme
- ✅ Custom widgets for consistency

### 🔄 State Management
- ✅ Flutter Riverpod for state management
- ✅ StreamBuilder for real-time auth state
- ✅ Persistent login sessions

## 📁 Project Structure

```
lib/
├── models/
│   └── user_model.dart          # User data model with roles
├── services/
│   └── auth_service.dart        # Firebase authentication service
├── providers/
│   └── (ready for future state providers)
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart              # Login screen
│   │   ├── register_screen.dart           # Registration screen
│   │   └── email_verification_screen.dart # Email verification
│   ├── admin/
│   │   └── admin_dashboard.dart           # Admin dashboard
│   ├── doctor/
│   │   └── doctor_dashboard.dart          # Doctor dashboard
│   └── patient/
│       └── patient_dashboard.dart         # Patient dashboard
├── widgets/
│   ├── custom_button.dart       # Reusable button widget
│   └── custom_text_field.dart   # Reusable text field widget
├── utils/
│   ├── constants.dart           # App constants and colors
│   └── theme.dart              # App theme configuration
├── firebase_options.dart        # Firebase configuration
└── main.dart                   # App entry point with routing

```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.32.7 or later)
- Dart SDK (3.8.1 or later)
- Firebase account
- Node.js (for Firebase CLI)
- Code editor (VS Code, Android Studio, etc.)

### Installation Steps

#### 1. Clone the Repository

```bash
cd smartcare_hms
```

#### 2. Install Dependencies

```bash
flutter pub get
```

#### 3. Firebase Setup

**Important**: You need to configure Firebase before running the app.

##### Option 1: Using FlutterFire CLI (Recommended)

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (this will create firebase_options.dart)
flutterfire configure
```

The `flutterfire configure` command will:
- Create or select a Firebase project
- Enable Firebase services
- Generate platform-specific configuration files
- Update `firebase_options.dart` with your credentials

##### Option 2: Manual Configuration

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project
3. Add your Flutter app for each platform (Android, iOS, Web)
4. Download configuration files:
   - Android: `google-services.json` → `android/app/`
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`
5. Update `lib/firebase_options.dart` with your credentials

#### 4. Enable Firebase Services

In your Firebase Console:

##### a) Authentication
1. Go to **Authentication** → **Sign-in method**
2. Enable **Email/Password**
3. (Optional) Enable **Google** sign-in

##### b) Firestore Database
1. Go to **Firestore Database**
2. Click **Create database**
3. Start in **test mode** (for development)
4. Choose a location

##### c) Storage (Optional)
1. Go to **Storage**
2. Click **Get started**
3. Start in **test mode** (for development)

#### 5. Configure Firestore Security Rules

In Firestore → Rules, update to:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - users can read all, but only write their own
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

#### 6. Run the App

```bash
# Check connected devices
flutter devices

# Run on specific device
flutter run -d <device_id>

# Or run on Chrome (web)
flutter run -d chrome

# Or run on Android emulator
flutter run -d android

# Or run on iOS simulator (macOS only)
flutter run -d ios
```

## 📱 How to Use

### First Time Setup

1. **Run the app** - You'll see the login screen
2. **Create an account** - Click "Sign Up"
3. **Fill in details**:
   - Full Name
   - Email
   - Password
   - Select Role (Admin, Doctor, or Patient)
4. **Verify email** - Check your email and click the verification link
5. **Login** - Return to app and login with your credentials
6. **Dashboard** - You'll be redirected to your role-specific dashboard

### User Roles

#### 👨‍💼 Admin
- View system statistics
- Manage users (coming in Phase 2)
- Access to all hospital operations
- System settings and configuration

#### 👨‍⚕️ Doctor
- View appointment schedule
- Access patient records
- Write prescriptions
- Review lab reports

#### 🧑‍🤝‍🧑 Patient
- Book appointments
- View medical records
- Access prescriptions
- Check billing information

## 🔒 Security Features

1. **Email Verification**: All new users must verify their email before accessing the system
2. **Password Security**: Minimum 6 characters required
3. **Session Management**: Automatic session persistence
4. **Role-Based Access**: Users only see features relevant to their role
5. **Firestore Security Rules**: Database-level access control

## 🎨 Design System

### Color Scheme
- **Primary**: Blue (#1976D2)
- **Secondary**: Light Blue (#42A5F5)
- **Success**: Green (#388E3C)
- **Error**: Red (#D32F2F)
- **Background**: Light Gray (#F5F5F5)

### Components
- Custom buttons with loading states
- Custom text fields with validation
- Gradient cards for visual appeal
- Modern Material 3 design

## 🛠️ Technologies Used

- **Flutter**: UI framework
- **Firebase Auth**: User authentication
- **Cloud Firestore**: NoSQL database
- **Firebase Storage**: File storage
- **Flutter Riverpod**: State management
- **Material 3**: Design system

## 📦 Dependencies

```yaml
firebase_core: ^3.8.0
firebase_auth: ^5.3.4
cloud_firestore: ^5.5.2
firebase_storage: ^12.3.8
flutter_riverpod: ^2.6.1
google_sign_in: ^6.2.2
intl: ^0.19.0
url_launcher: ^6.3.1
go_router: ^14.6.2
```

## 🐛 Troubleshooting

### Firebase initialization error
- Make sure you've run `flutterfire configure`
- Check that `firebase_options.dart` has your actual credentials
- Verify that Firebase services are enabled in the console

### Email not sending
- Check that Email/Password authentication is enabled in Firebase Console
- Verify your email settings in Firebase Authentication

### Build errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### iOS build issues
```bash
cd ios
pod install
cd ..
flutter run
```

## 🚧 Future Phases

**Phase 2**: Appointments Module
- Book appointments
- Doctor scheduling
- Appointment management

**Phase 3**: Patient Management
- Medical records
- Prescriptions
- Lab reports

**Phase 4**: Billing & Payments
- Invoice generation
- Payment processing
- Payment history

**Phase 5**: Advanced Features
- Video consultations
- Push notifications
- Analytics dashboard

## 📝 License

This project is for educational purposes.

## 🤝 Contributing

This is a learning project. Feel free to fork and experiment!

## 📧 Support

For issues or questions, please check the Firebase setup documentation:
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)

## ✅ Phase 1 Completion Checklist

- [x] Flutter project setup
- [x] Firebase integration
- [x] User authentication (register/login)
- [x] Email verification
- [x] Role-based access control
- [x] Admin dashboard
- [x] Doctor dashboard
- [x] Patient dashboard
- [x] Session management
- [x] Modern UI/UX design
- [x] Password reset functionality
- [x] Security rules

**Phase 1 is complete and ready for testing!** 🎉

---

Built with ❤️ using Flutter and Firebase
