import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/doctor_model.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../services/doctor_service.dart';
import '../../services/appointment_service.dart';
import '../../services/doctor_availability_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final DoctorService _doctorService = DoctorService();
  final AppointmentService _appointmentService = AppointmentService();
  final DoctorAvailabilityService _availabilityService = DoctorAvailabilityService();
  final AuthService _authService = AuthService();

  // State
  DoctorModel? _selectedDoctor;
  DateTime? _selectedDate;
  DateTime? _selectedTimeSlot;
  Map<DateTime, List<DateTime>> _availableSlots = {};
  bool _isLoadingSlots = false;
  String _meetingType = 'physical';

  // Controllers
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableSlots() async {
    if (_selectedDoctor == null || _selectedDate == null) return;

    setState(() => _isLoadingSlots = true);

    try {
      // Get existing appointments for the doctor
      final existingAppointments = await _appointmentService
          .getAppointmentsByDoctor(_selectedDoctor!.id)
          .first;

      // Generate available slots
      final slots = await _availabilityService.generateAvailableSlots(
        doctorId: _selectedDoctor!.id,
        startDate: _selectedDate!,
        endDate: _selectedDate!.add(const Duration(days: 1)),
        existingAppointments: existingAppointments,
      );

      setState(() {
        _availableSlots = slots;
        _isLoadingSlots = false;
      });
    } catch (e) {
      setState(() => _isLoadingSlots = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading slots: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedDoctor == null ||
        _selectedDate == null ||
        _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select doctor, date, and time'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter reason for visit'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userData = await _authService.getUserData(user.uid);
      if (userData == null) throw Exception('User data not found');

      // Calculate end time (30 minutes default)
      final endTime = _selectedTimeSlot!.add(const Duration(minutes: 30));

      final appointment = AppointmentModel(
        id: '',
        doctorId: _selectedDoctor!.id,
        patientId: user.uid,
        doctorName: _selectedDoctor!.name,
        patientName: userData.name,
        startTime: Timestamp.fromDate(_selectedTimeSlot!.toUtc()),
        endTime: Timestamp.fromDate(endTime.toUtc()),
        status: AppointmentStatus.pending,
        reason: _reasonController.text.trim(),
        notes: _notesController.text.trim(),
        createdBy: user.uid,
        createdAt: Timestamp.now(),
        meetingType: _meetingType,
      );

      await _appointmentService.createAppointment(appointment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to book appointment';
        if (e.toString().contains('no longer available')) {
          errorMessage = 'This time slot was just taken. Please choose another.';
          _loadAvailableSlots(); // Refresh slots
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: AppStyles.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            _buildStepIndicator(),
            const SizedBox(height: 24),

            // Step 1: Select Doctor
            if (_selectedDoctor == null) _buildDoctorSelection(),

            // Step 2: Select Date
            if (_selectedDoctor != null && _selectedDate == null)
              _buildDateSelection(),

            // Step 3: Select Time
            if (_selectedDoctor != null && _selectedDate != null && _selectedTimeSlot == null)
              _buildTimeSelection(),

            // Step 4: Enter Details
            if (_selectedTimeSlot != null) _buildDetailsForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    int currentStep = 1;
    if (_selectedDoctor != null) currentStep = 2;
    if (_selectedDate != null) currentStep = 3;
    if (_selectedTimeSlot != null) currentStep = 4;

    return Row(
      children: [
        _buildStepCircle(1, 'Doctor', currentStep >= 1),
        Expanded(child: Divider(color: currentStep >= 2 ? AppColors.primary : Colors.grey)),
        _buildStepCircle(2, 'Date', currentStep >= 2),
        Expanded(child: Divider(color: currentStep >= 3 ? AppColors.primary : Colors.grey)),
        _buildStepCircle(3, 'Time', currentStep >= 3),
        Expanded(child: Divider(color: currentStep >= 4 ? AppColors.primary : Colors.grey)),
        _buildStepCircle(4, 'Details', currentStep >= 4),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? AppColors.primary : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Doctor',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<DoctorModel>>(
          stream: _doctorService.getDoctors(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No doctors available'));
            }

            final doctors = snapshot.data!;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final doctor = doctors[index];
                return _buildDoctorCard(doctor);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDoctorCard(DoctorModel doctor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            doctor.name.isNotEmpty ? doctor.name[0].toUpperCase() : 'D',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(
          'Dr. ${doctor.name}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(doctor.specialization),
            const SizedBox(height: 2),
            Text('${doctor.experience} experience'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          setState(() {
            _selectedDoctor = doctor;
          });
        },
      ),
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _selectedDoctor = null),
            ),
            const Text(
              'Select Date',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildCalendar(),
      ],
    );
  }

  Widget _buildCalendar() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: daysInMonth,
      itemBuilder: (context, index) {
        final date = DateTime(now.year, now.month, index + 1);
        final isPast = date.isBefore(DateTime(now.year, now.month, now.day));

        return InkWell(
          onTap: isPast
              ? null
              : () {
                  setState(() {
                    _selectedDate = date;
                  });
                  _loadAvailableSlots();
                },
          child: Container(
            decoration: BoxDecoration(
              color: isPast
                  ? Colors.grey.shade200
                  : Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: isPast ? Colors.grey.shade400 : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() {
                _selectedDate = null;
                _availableSlots = {};
              }),
            ),
            Text(
              'Select Time - ${DateFormat('MMM dd').format(_selectedDate!)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isLoadingSlots)
          const Center(child: CircularProgressIndicator())
        else if (_availableSlots.isEmpty || _availableSlots[_selectedDate] == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No available slots for this date'),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableSlots[_selectedDate]!.map((slot) {
              final timeStr = DateFormat('hh:mm a').format(slot);
              return InkWell(
                onTap: () => setState(() => _selectedTimeSlot = slot),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    timeStr,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDetailsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _selectedTimeSlot = null),
            ),
            const Text(
              'Appointment Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Summary card
        Card(
          color: AppColors.primary.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dr. ${_selectedDoctor!.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_selectedDoctor!.specialization),
                const Divider(height: 16),
                Text('📅 ${DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate!)}'),
                const SizedBox(height: 4),
                Text('⏰ ${DateFormat('hh:mm a').format(_selectedTimeSlot!)}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Reason
        TextField(
          controller: _reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for Visit *',
            hintText: 'e.g., Routine checkup, Consultation',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),

        // Notes
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Additional Notes (Optional)',
            hintText: 'Any specific concerns or symptoms',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Meeting type
        const Text('Meeting Type:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('In-Person'),
                value: 'physical',
                groupValue: _meetingType,
                onChanged: (value) => setState(() => _meetingType = value!),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Video'),
                value: 'video',
                groupValue: _meetingType,
                onChanged: (value) => setState(() => _meetingType = value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Confirm button
        CustomButton(
          text: 'Confirm Booking',
          onPressed: _bookAppointment,
        ),
      ],
    );
  }
}

