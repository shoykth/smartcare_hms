import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final AppointmentModel appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final AuthService _authService = AuthService();
  UserRole? _currentUserRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _authService.getUserData(user.uid);
        if (userData != null && mounted) {
          setState(() {
            _currentUserRole = userData.role;
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _cancelAppointment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text(
          'Are you sure you want to cancel this appointment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _appointmentService.cancelAppointment(
          id: widget.appointment.id,
          cancelledBy: user.uid,
          cancellationReason: 'Cancelled by patient',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment cancelled successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  bool get _canCancel {
    return widget.appointment.status == AppointmentStatus.pending ||
        widget.appointment.status == AppointmentStatus.confirmed;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final startDate = widget.appointment.startTime.toDate();
    final endDate = widget.appointment.endTime.toDate();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppStyles.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _getStatusColor(widget.appointment.status)
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.appointment.status ==
                                    AppointmentStatus.completed
                                ? Icons.check_circle
                                : widget.appointment.status ==
                                        AppointmentStatus.confirmed
                                    ? Icons.event_available
                                    : widget.appointment.status ==
                                            AppointmentStatus.pending
                                        ? Icons.pending
                                        : Icons.cancel,
                            color:
                                _getStatusColor(widget.appointment.status),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.appointment.status.name.toUpperCase(),
                            style: TextStyle(
                              color:
                                  _getStatusColor(widget.appointment.status),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Doctor Information
                  _buildInfoCard(
                    title: 'Doctor Information',
                    icon: Icons.person,
                    children: [
                      _buildInfoRow('Name', 'Dr. ${widget.appointment.doctorName}'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Appointment Information
                  _buildInfoCard(
                    title: 'Appointment Information',
                    icon: Icons.event,
                    children: [
                      _buildInfoRow('Date', dateFormat.format(startDate)),
                      _buildInfoRow(
                        'Time',
                        '${timeFormat.format(startDate)} - ${timeFormat.format(endDate)}',
                      ),
                      _buildInfoRow(
                        'Duration',
                        '${widget.appointment.durationMinutes} minutes',
                      ),
                      _buildInfoRow(
                        'Type',
                        widget.appointment.meetingType == 'video'
                            ? 'Video Consultation'
                            : 'In-Person Visit',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Visit Details
                  if (widget.appointment.reason != null &&
                      widget.appointment.reason!.isNotEmpty)
                    _buildInfoCard(
                      title: 'Visit Details',
                      icon: Icons.info,
                      children: [
                        _buildInfoSection(
                          'Reason for Visit',
                          widget.appointment.reason!,
                        ),
                        if (widget.appointment.notes != null &&
                            widget.appointment.notes!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildInfoSection(
                            'Additional Notes',
                            widget.appointment.notes!,
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Cancellation Info
                  if (widget.appointment.status ==
                          AppointmentStatus.cancelled &&
                      widget.appointment.cancellationReason != null)
                    _buildInfoCard(
                      title: 'Cancellation Information',
                      icon: Icons.cancel,
                      iconColor: AppColors.error,
                      children: [
                        _buildInfoSection(
                          'Reason',
                          widget.appointment.cancellationReason!,
                        ),
                      ],
                    ),

                  const SizedBox(height: 32),

                  // Actions
                  if (_canCancel && _currentUserRole == UserRole.patient)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _cancelAppointment,
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancel Appointment'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),

                  if (widget.appointment.meetingType == 'video' &&
                      widget.appointment.status ==
                          AppointmentStatus.confirmed)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement video call launch
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Video consultation feature coming soon'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.videocam),
                        label: const Text('Join Video Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? iconColor,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor ?? AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

