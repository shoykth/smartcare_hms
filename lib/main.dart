import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'utils/theme.dart';
import 'services/auth_service.dart';
import 'models/user_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/doctor/doctor_dashboard_enhanced.dart';
import 'screens/patient/patient_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartCare HMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      // Add route generator to handle named routes
      onGenerateRoute: (settings) {
        // Handle all routes by returning the AuthWrapper
        // This ensures auth state is always checked
        return MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
          settings: settings,
        );
      },
      // Fallback for unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
        );
      },
    );
  }
}

/// Auth Wrapper that handles authentication state and routing
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Not logged in - show login screen
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // User is logged in
        final user = snapshot.data!;

        // Check if email is verified
        if (!user.emailVerified) {
          return const EmailVerificationScreen();
        }

        // Email is verified - show appropriate dashboard
        return FutureBuilder<UserModel?>(
          future: authService.getUserData(user.uid),
          builder: (context, userSnapshot) {
            // Show loading while fetching user data
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Error or no data
            if (userSnapshot.hasError || !userSnapshot.hasData) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Error loading user data',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await authService.logout();
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final userModel = userSnapshot.data!;

            // Route to appropriate dashboard based on role
            return _getDashboardForRole(userModel);
          },
        );
      },
    );
  }

  Widget _getDashboardForRole(UserModel user) {
    switch (user.role) {
      case UserRole.admin:
        return AdminDashboard(
          userName: user.name,
          userEmail: user.email,
        );
      case UserRole.doctor:
        return DoctorDashboardEnhanced(
          userName: user.name,
          userEmail: user.email,
        );
      case UserRole.patient:
        return PatientDashboard(
          userName: user.name,
          userEmail: user.email,
        );
    }
  }
}
