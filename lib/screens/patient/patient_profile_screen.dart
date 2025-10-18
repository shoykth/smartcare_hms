import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/patient_model.dart';
import '../../models/user_model.dart';
import '../../services/patient_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import 'add_patient_screen.dart';

class PatientProfileScreen extends StatefulWidget {
  final PatientModel patient;

  const PatientProfileScreen({super.key, required this.patient});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final PatientService _patientService = PatientService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  UserRole? _currentUserRole;

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
        if (userData != null) {
          setState(() {
            _currentUserRole = userData.role;
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _deletePatient() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Patient'),
        content: const Text(
          'Are you sure you want to delete this patient? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _patientService.deletePatient(widget.patient.id, user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Patient deleted successfully'),
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

  bool get _canEdit {
    return _currentUserRole == UserRole.admin || 
           _currentUserRole == UserRole.doctor;
  }

  bool get _canDelete {
    return _currentUserRole == UserRole.admin;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patient Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        AddPatientScreen(patient: widget.patient),
                  ),
                );
                if (result == true && mounted) {
                  // Reload patient data
                  setState(() {});
                }
              },
            ),
          if (_canDelete)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _deletePatient,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppStyles.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card with Avatar
                  _buildHeaderCard(),
                  const SizedBox(height: 16),

                  // Basic Information
                  _buildInfoCard(
                    title: 'Basic Information',
                    icon: Icons.person,
                    children: [
                      _buildInfoRow('Name', widget.patient.name),
                      _buildInfoRow('Age', '${widget.patient.age} years'),
                      _buildInfoRow('Gender', widget.patient.gender),
                      _buildInfoRow('Blood Group', widget.patient.bloodGroup),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Contact Information
                  _buildInfoCard(
                    title: 'Contact Information',
                    icon: Icons.contact_phone,
                    children: [
                      _buildInfoRow('Phone', widget.patient.phone),
                      _buildInfoRow('Email', widget.patient.email),
                      _buildInfoRow('Address', widget.patient.address),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Emergency Contact
                  _buildInfoCard(
                    title: 'Emergency Contact',
                    icon: Icons.warning_amber,
                    iconColor: AppColors.error,
                    children: [
                      _buildInfoRow('Name', widget.patient.emergencyContactName),
                      _buildInfoRow('Phone', widget.patient.emergencyContactPhone),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Medical Information
                  _buildInfoCard(
                    title: 'Medical Information',
                    icon: Icons.medical_information,
                    iconColor: AppColors.success,
                    children: [
                      _buildInfoSection(
                        'Medical History',
                        widget.patient.medicalHistory.isEmpty
                            ? 'No medical history recorded'
                            : widget.patient.medicalHistory,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoSection(
                        'Allergies',
                        widget.patient.allergies.isEmpty
                            ? 'No known allergies'
                            : widget.patient.allergies,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoSection(
                        'Chronic Diseases',
                        widget.patient.chronicDiseases.isEmpty
                            ? 'No chronic diseases'
                            : widget.patient.chronicDiseases,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Text(
                widget.patient.name.isNotEmpty
                    ? widget.patient.name[0].toUpperCase()
                    : 'P',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.patient.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.patient.age} years • ${widget.patient.gender}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.patient.bloodGroup,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

