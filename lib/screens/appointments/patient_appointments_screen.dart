import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import 'book_appointment_screen.dart';
import 'appointment_detail_screen.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() =>
      _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  final AppointmentService _appointmentService = AppointmentService();
  final AuthService _authService = AuthService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.blue;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
      case AppointmentStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Icons.pending;
      case AppointmentStatus.confirmed:
        return Icons.check_circle;
      case AppointmentStatus.completed:
        return Icons.done_all;
      case AppointmentStatus.cancelled:
      case AppointmentStatus.rejected:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: StreamBuilder<List<AppointmentModel>>(
        stream: _appointmentService.getAppointmentsByPatient(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final allAppointments = snapshot.data ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAppointmentList(allAppointments, 'upcoming'),
              _buildAppointmentList(allAppointments, 'past'),
              _buildAppointmentList(allAppointments, 'cancelled'),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const BookAppointmentScreen(),
            ),
          );
          if (result == true && mounted) {
            // Appointments list will auto-refresh via StreamBuilder
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Book Appointment'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildAppointmentList(
    List<AppointmentModel> appointments,
    String filter,
  ) {
    List<AppointmentModel> filteredAppointments;

    switch (filter) {
      case 'upcoming':
        filteredAppointments = appointments.where((apt) {
          return apt.isUpcoming;
        }).toList();
        break;
      case 'past':
        filteredAppointments = appointments.where((apt) {
          return apt.isPast &&
              apt.status != AppointmentStatus.cancelled &&
              apt.status != AppointmentStatus.rejected;
        }).toList();
        break;
      case 'cancelled':
        filteredAppointments = appointments.where((apt) {
          return apt.status == AppointmentStatus.cancelled ||
              apt.status == AppointmentStatus.rejected;
        }).toList();
        break;
      default:
        filteredAppointments = appointments;
    }

    // Sort by date (upcoming: ascending, past: descending)
    filteredAppointments.sort((a, b) {
      if (filter == 'past') {
        return b.startTime.compareTo(a.startTime);
      }
      return a.startTime.compareTo(b.startTime);
    });

    if (filteredAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No $filter appointments',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            if (filter == 'upcoming') ...[
              const SizedBox(height: 8),
              Text(
                'Tap + to book your first appointment',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredAppointments.length,
      itemBuilder: (context, index) {
        final appointment = filteredAppointments[index];
        return _buildAppointmentCard(appointment);
      },
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final date = appointment.startTime.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  AppointmentDetailScreen(appointment: appointment),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      appointment.doctorName.isNotEmpty
                          ? appointment.doctorName[0].toUpperCase()
                          : 'D',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. ${appointment.doctorName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              dateFormat.format(date),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment.status)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(appointment.status),
                          size: 14,
                          color: _getStatusColor(appointment.status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          appointment.status.name.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(appointment.status),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      '${timeFormat.format(date)} (${appointment.durationMinutes} min)',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      appointment.meetingType == 'video'
                          ? Icons.videocam
                          : Icons.local_hospital,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      appointment.meetingType == 'video'
                          ? 'Video'
                          : 'In-Person',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (appointment.reason != null &&
                  appointment.reason!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  appointment.reason!,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

