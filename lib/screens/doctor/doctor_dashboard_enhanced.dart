import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/appointment_service.dart';
import '../../services/medical_note_service.dart';
import '../../utils/constants.dart';
import '../patient/patient_list_screen.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_profile_screen.dart';
import 'medical_notes_screen.dart';
import 'doctor_availability_screen.dart';

class DoctorDashboardEnhanced extends StatefulWidget {
  final String userName;
  final String userEmail;

  const DoctorDashboardEnhanced({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<DoctorDashboardEnhanced> createState() => _DoctorDashboardEnhancedState();
}

class _DoctorDashboardEnhancedState extends State<DoctorDashboardEnhanced> {
  final AuthService _authService = AuthService();
  final AppointmentService _appointmentService = AppointmentService();
  final MedicalNoteService _noteService = MedicalNoteService();

  int _todayAppointments = 0;
  int _pendingAppointments = 0;
  int _totalNotes = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final today = await _appointmentService.getTodayAppointmentCount(user.uid);
        final pending = await _appointmentService.getPendingAppointmentCount(user.uid);
        final notes = await _noteService.getMedicalNoteCountByDoctor(user.uid);

        if (!mounted) return;
        setState(() {
          _todayAppointments = today;
          _pendingAppointments = pending;
          _totalNotes = notes;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await _authService.logout();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Welcome, Dr. ${widget.userName.split(' ').first}'),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppStyles.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    _buildWelcomeCard(),
                    const SizedBox(height: 24),

                    // Stats Cards
                    Text(
                      'Today\'s Overview',
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
                            title: 'Today',
                            value: _todayAppointments.toString(),
                            subtitle: 'Appointments',
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.pending_actions,
                            title: 'Pending',
                            value: _pendingAppointments.toString(),
                            subtitle: 'Requests',
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.note_alt,
                            title: 'Notes',
                            value: _totalNotes.toString(),
                            subtitle: 'Medical Notes',
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.trending_up,
                            title: 'Status',
                            value: 'Active',
                            subtitle: 'Online',
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    _buildMenuCard(
                      context: context,
                      icon: Icons.calendar_month,
                      title: 'Appointments',
                      subtitle: 'View and manage your appointments',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const DoctorAppointmentsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildMenuCard(
                      context: context,
                      icon: Icons.people,
                      title: 'Patients',
                      subtitle: 'View patient records and history',
                      color: Colors.teal,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const PatientListScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildMenuCard(
                      context: context,
                      icon: Icons.description,
                      title: 'Medical Notes',
                      subtitle: 'Create and manage medical notes',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const MedicalNotesScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildMenuCard(
                      context: context,
                      icon: Icons.event_available,
                      title: 'Availability',
                      subtitle: 'Set your working hours and schedule',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const DoctorAvailabilityScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildMenuCard(
                      context: context,
                      icon: Icons.person,
                      title: 'My Profile',
                      subtitle: 'View and edit your profile',
                      color: Colors.indigo,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const DoctorProfileScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Text(
                  widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'D',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Dr. ${widget.userName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  widget.userEmail,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
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
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
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
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
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
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

