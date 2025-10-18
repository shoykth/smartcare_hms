import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/doctor_model.dart';
import '../../services/doctor_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final DoctorService _doctorService = DoctorService();
  final AuthService _authService = AuthService();
  
  DoctorModel? _doctor;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specializationController = TextEditingController();
  final _departmentController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _departmentController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorProfile() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final doctor = await _doctorService.getDoctorByUserId(user.uid);
      
      if (doctor != null) {
        setState(() {
          _doctor = doctor;
          _nameController.text = doctor.name;
          _emailController.text = doctor.email;
          _phoneController.text = doctor.phone;
          _specializationController.text = doctor.specialization;
          _departmentController.text = doctor.department;
          _qualificationController.text = doctor.qualification;
          _experienceController.text = doctor.experience;
          _bioController.text = doctor.bio;
          _isLoading = false;
        });
      } else {
        // Create doctor profile if it doesn't exist
        await _createDoctorProfile(user.uid);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createDoctorProfile(String userId) async {
    try {
      final userData = await _authService.getUserData(userId);
      if (userData == null) return;

      final newDoctor = DoctorModel(
        id: userId,
        name: userData.name,
        email: userData.email,
        phone: '',
        specialization: userData.specialization ?? '',
        department: userData.departmentId ?? '',
        qualification: '',
        experience: '0 years',
        bio: '',
        profileImageUrl: userData.profileImage ?? '',
        createdAt: Timestamp.now(),
      );

      await _doctorService.addDoctor(newDoctor);
      
      setState(() {
        _doctor = newDoctor;
        _nameController.text = newDoctor.name;
        _emailController.text = newDoctor.email;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating profile: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      if (_doctor == null) return;

      final updates = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'department': _departmentController.text.trim(),
        'qualification': _qualificationController.text.trim(),
        'experience': _experienceController.text.trim(),
        'bio': _bioController.text.trim(),
      };

      await _doctorService.updateDoctor(_doctor!.id, updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() => _isEditing = false);
        _loadDoctorProfile();
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
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_doctor == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Doctor Profile'),
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Profile not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isEditing ? _buildEditForm() : _buildProfileView(),
    );
  }

  Widget _buildProfileView() {
    return SingleChildScrollView(
      padding: AppStyles.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          _buildHeaderCard(),
          const SizedBox(height: 24),

          // Basic Information
          _buildInfoCard(
            title: 'Basic Information',
            icon: Icons.person,
            children: [
              _buildInfoRow('Name', _doctor!.name),
              _buildInfoRow('Email', _doctor!.email),
              _buildInfoRow('Phone', _doctor!.phone.isEmpty ? 'Not provided' : _doctor!.phone),
            ],
          ),
          const SizedBox(height: 16),

          // Professional Information
          _buildInfoCard(
            title: 'Professional Information',
            icon: Icons.work,
            children: [
              _buildInfoRow('Specialization', _doctor!.specialization),
              _buildInfoRow('Department', _doctor!.department),
              _buildInfoRow('Qualification', _doctor!.qualification.isEmpty ? 'Not provided' : _doctor!.qualification),
              _buildInfoRow('Experience', _doctor!.experience),
            ],
          ),
          const SizedBox(height: 16),

          // Bio
          if (_doctor!.bio.isNotEmpty)
            _buildInfoCard(
              title: 'About',
              icon: Icons.info,
              children: [
                Text(
                  _doctor!.bio,
                  style: const TextStyle(height: 1.5),
                ),
              ],
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: AppStyles.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Picture
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    _doctor!.name.isNotEmpty ? _doctor!.name[0].toUpperCase() : 'D',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Form Fields
          _buildSectionTitle('Basic Information'),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _nameController,
            label: 'Full Name',
            prefixIcon: Icons.person,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _emailController,
            label: 'Email',
            prefixIcon: Icons.email,
            enabled: false,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _phoneController,
            label: 'Phone Number',
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('Professional Information'),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _specializationController,
            label: 'Specialization',
            prefixIcon: Icons.medical_services,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _departmentController,
            label: 'Department',
            prefixIcon: Icons.business,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _qualificationController,
            label: 'Qualification',
            prefixIcon: Icons.school,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _experienceController,
            label: 'Experience',
            prefixIcon: Icons.work_history,
            hint: 'e.g., 8 years',
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('About Me'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bioController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tell us about yourself...',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _isEditing = false);
                    _loadDoctorProfile();
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Save Changes',
                  onPressed: _saveProfile,
                  isLoading: _isSaving,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
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
            colors: [AppColors.success, Color(0xFF81C784)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Text(
                _doctor!.name.isNotEmpty ? _doctor!.name[0].toUpperCase() : 'D',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Dr. ${_doctor!.name}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _doctor!.specialization,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatBadge(Icons.people, '${_doctor!.totalPatients ?? 0}', 'Patients'),
                const SizedBox(width: 24),
                _buildStatBadge(Icons.star, '${_doctor!.rating?.toStringAsFixed(1) ?? '0.0'}', 'Rating'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
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
                Icon(icon, color: AppColors.success, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }
}

