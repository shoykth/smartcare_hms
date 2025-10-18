import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/doctor_availability_model.dart';
import '../../services/doctor_availability_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class DoctorAvailabilityScreen extends StatefulWidget {
  const DoctorAvailabilityScreen({super.key});

  @override
  State<DoctorAvailabilityScreen> createState() =>
      _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
  final DoctorAvailabilityService _availabilityService =
      DoctorAvailabilityService();
  final AuthService _authService = AuthService();

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
        title: const Text('My Availability'),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<DoctorAvailabilityModel>>(
        stream: _availabilityService.getAvailabilityForDoctor(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final availabilities = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: AppStyles.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card
                Card(
                  color: AppColors.primary.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Set your weekly availability. Patients will be able to book appointments during these times.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Weekly Schedule
                Text(
                  'Weekly Schedule',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                // Days of week
                ...List.generate(7, (index) {
                  final dayOfWeek = index + 1;
                  final availability = availabilities.firstWhere(
                    (a) => a.dayOfWeek == dayOfWeek,
                    orElse: () => DoctorAvailabilityModel(
                      id: '',
                      doctorId: user.uid,
                      dayOfWeek: dayOfWeek,
                      startTime: '09:00',
                      endTime: '17:00',
                      slotDurationMinutes: 30,
                      isActive: false,
                      createdAt: Timestamp.now(),
                    ),
                  );

                  return _buildDayCard(availability);
                }),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayCard(DoctorAvailabilityModel availability) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: availability.isActive ? AppColors.success : Colors.grey.shade300,
          width: availability.isActive ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Day name
                SizedBox(
                  width: 80,
                  child: Text(
                    availability.dayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                
                // Active toggle
                Expanded(
                  child: Switch(
                    value: availability.isActive,
                    onChanged: (value) async {
                      try {
                        if (availability.id.isEmpty) {
                          // Create new availability
                          final newAvailability = availability.copyWith(
                            isActive: value,
                          );
                          await _availabilityService.setAvailability(
                            newAvailability,
                          );
                        } else {
                          // Toggle existing
                          final user = _authService.currentUser;
                          if (user != null) {
                            await _availabilityService.toggleAvailability(
                              availability.id,
                              user.uid,
                              value,
                            );
                          }
                        }

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value ? 'Availability enabled' : 'Availability disabled',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
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
                      }
                    },
                    activeColor: AppColors.success,
                  ),
                ),

                // Edit button
                if (availability.isActive)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () {
                      _showEditDialog(availability);
                    },
                  ),
              ],
            ),

            if (availability.isActive) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '${availability.startTime} - ${availability.endTime}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.timelapse, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '${availability.slotDurationMinutes} min slots',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              if (availability.exceptions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: availability.exceptions.map((exception) {
                    return Chip(
                      label: Text(
                        '${exception.date.month}/${exception.date.day} Off',
                        style: const TextStyle(fontSize: 11),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () async {
                        try {
                          final user = _authService.currentUser;
                          if (user != null) {
                            await _availabilityService.removeException(
                              availability.id,
                              user.uid,
                              exception.date,
                            );
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
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _showEditDialog(DoctorAvailabilityModel availability) {
    final startTimeController = TextEditingController(text: availability.startTime);
    final endTimeController = TextEditingController(text: availability.endTime);
    int slotDuration = availability.slotDurationMinutes;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${availability.dayName}'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Start Time
              TextField(
                controller: startTimeController,
                decoration: const InputDecoration(
                  labelText: 'Start Time',
                  hintText: '09:00',
                  prefixIcon: Icon(Icons.access_time),
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: int.parse(availability.startTime.split(':')[0]),
                      minute: int.parse(availability.startTime.split(':')[1]),
                    ),
                  );
                  if (time != null) {
                    startTimeController.text =
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  }
                },
              ),
              const SizedBox(height: 16),

              // End Time
              TextField(
                controller: endTimeController,
                decoration: const InputDecoration(
                  labelText: 'End Time',
                  hintText: '17:00',
                  prefixIcon: Icon(Icons.access_time),
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: int.parse(availability.endTime.split(':')[0]),
                      minute: int.parse(availability.endTime.split(':')[1]),
                    ),
                  );
                  if (time != null) {
                    endTimeController.text =
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  }
                },
              ),
              const SizedBox(height: 16),

              // Slot Duration
              DropdownButtonFormField<int>(
                value: slotDuration,
                decoration: const InputDecoration(
                  labelText: 'Slot Duration',
                  prefixIcon: Icon(Icons.timelapse),
                ),
                items: const [
                  DropdownMenuItem(value: 15, child: Text('15 minutes')),
                  DropdownMenuItem(value: 20, child: Text('20 minutes')),
                  DropdownMenuItem(value: 30, child: Text('30 minutes')),
                  DropdownMenuItem(value: 45, child: Text('45 minutes')),
                  DropdownMenuItem(value: 60, child: Text('1 hour')),
                ],
                onChanged: (value) {
                  setState(() => slotDuration = value!);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final updatedAvailability = availability.copyWith(
                  startTime: startTimeController.text,
                  endTime: endTimeController.text,
                  slotDurationMinutes: slotDuration,
                );

                await _availabilityService.setAvailability(updatedAvailability);

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Availability updated!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
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
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

