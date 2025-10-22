import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../appointments/patient_appointments_screen.dart';
import '../appointments/book_appointment_screen.dart';
import 'prescriptions_screen.dart';
import 'medical_records_screen.dart';

class PatientDashboard extends ConsumerWidget {
  final String userName;
  final String userEmail;

  const PatientDashboard({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppStyles.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppStyles.cardBorderRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hello,',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.person, color: Colors.white70, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Patient',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Stats
            Text(
              'Your Health Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.calendar_today,
                    title: 'Appointments',
                    value: '3',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.description,
                    title: 'Reports',
                    value: '7',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Services
            Text(
              'Services',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              context: context,
              icon: Icons.add_circle_outline,
              title: 'Book Appointment',
              subtitle: 'Schedule a consultation with our doctors',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BookAppointmentScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildMenuCard(
              context: context,
              icon: Icons.event_note,
              title: 'My Appointments',
              subtitle: 'View and manage your appointments',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PatientAppointmentsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildMenuCard(
              context: context,
              icon: Icons.folder_open,
              title: 'Medical Records',
              subtitle: 'Access your medical history and reports',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MedicalRecordsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildMenuCard(
              context: context,
              icon: Icons.medication,
              title: 'Prescriptions',
              subtitle: 'View your active prescriptions',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrescriptionsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildMenuCard(
              context: context,
              icon: Icons.payment,
              title: 'Billing & Payments',
              subtitle: 'View bills and payment history',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildMenuCard(
              context: context,
              icon: Icons.person_outline,
              title: 'My Profile',
              subtitle: 'Update your personal information',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.secondary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await AuthService().logout();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

