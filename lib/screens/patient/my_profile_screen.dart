import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/patient_model.dart';
import '../../services/patient_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  final PatientService _patientService = PatientService();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  PatientModel? _currentPatient;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  // Form controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _chronicDiseasesController = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedBloodGroup = 'A+';

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroupOptions = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _medicalHistoryController.dispose();
    _allergiesController.dispose();
    _chronicDiseasesController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    try {
      final currentUser = _authService.currentUser;
      
      if (currentUser?.email != null) {
        final patient = await _patientService.getPatientByEmail(currentUser!.email!);
        if (patient != null) {
          setState(() {
            _currentPatient = patient;
            _populateFormFields();
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Patient profile not found. Please contact administrator.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _populateFormFields() {
    if (_currentPatient != null) {
      _nameController.text = _currentPatient!.name;
      _ageController.text = _currentPatient!.age.toString();
      _phoneController.text = _currentPatient!.phone;
      _addressController.text = _currentPatient!.address;
      _emergencyContactNameController.text = _currentPatient!.emergencyContactName;
      _emergencyContactPhoneController.text = _currentPatient!.emergencyContactPhone;
      _medicalHistoryController.text = _currentPatient!.medicalHistory;
      _allergiesController.text = _currentPatient!.allergies;
      _chronicDiseasesController.text = _currentPatient!.chronicDiseases;
      _selectedGender = _currentPatient!.gender;
      _selectedBloodGroup = _currentPatient!.bloodGroup;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final currentUser = _authService.currentUser;

      if (_currentPatient != null && currentUser != null) {
        final updatedData = {
          'name': _nameController.text.trim(),
          'age': int.parse(_ageController.text.trim()),
          'gender': _selectedGender,
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'emergencyContactName': _emergencyContactNameController.text.trim(),
          'emergencyContactPhone': _emergencyContactPhoneController.text.trim(),
          'bloodGroup': _selectedBloodGroup,
          'medicalHistory': _medicalHistoryController.text.trim(),
          'allergies': _allergiesController.text.trim(),
          'chronicDiseases': _chronicDiseasesController.text.trim(),
          'createdBy': currentUser.uid, // For logging purposes
        };

        await _patientService.updatePatient(_currentPatient!.id, updatedData);

        setState(() {
          _isEditing = false;
          _isSaving = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Reload the data to reflect changes
        await _loadPatientData();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
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
        title: const Text('My Profile'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        actions: [
          if (_currentPatient != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() => _isEditing = false);
                _populateFormFields(); // Reset form fields
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentPatient == null
              ? _buildNoProfileFound()
              : _isEditing
                  ? _buildEditForm()
                  : _buildViewProfile(),
      floatingActionButton: _isEditing
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _saveProfile,
              backgroundColor: AppColors.primary,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
            )
          : null,
    );
  }

  Widget _buildNoProfileFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Profile Not Found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please contact the administrator to set up your profile.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildViewProfile() {
    return SingleChildScrollView(
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
              _buildInfoRow('Name', _currentPatient!.name),
              _buildInfoRow('Age', '${_currentPatient!.age} years'),
              _buildInfoRow('Gender', _currentPatient!.gender),
              _buildInfoRow('Blood Group', _currentPatient!.bloodGroup),
            ],
          ),
          const SizedBox(height: 16),

          // Contact Information
          _buildInfoCard(
            title: 'Contact Information',
            icon: Icons.contact_phone,
            children: [
              _buildInfoRow('Phone', _currentPatient!.phone),
              _buildInfoRow('Email', _currentPatient!.email),
              _buildInfoRow('Address', _currentPatient!.address),
            ],
          ),
          const SizedBox(height: 16),

          // Emergency Contact
          _buildInfoCard(
            title: 'Emergency Contact',
            icon: Icons.warning_amber,
            iconColor: AppColors.error,
            children: [
              _buildInfoRow('Name', _currentPatient!.emergencyContactName),
              _buildInfoRow('Phone', _currentPatient!.emergencyContactPhone),
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
                _safeStringDisplay(_currentPatient!.medicalHistory, 'No medical history recorded'),
              ),
              const SizedBox(height: 12),
              _buildInfoSection(
                'Allergies',
                _safeStringDisplay(_currentPatient!.allergies, 'No known allergies'),
              ),
              const SizedBox(height: 12),
              _buildInfoSection(
                'Chronic Diseases',
                _safeStringDisplay(_currentPatient!.chronicDiseases, 'No chronic diseases'),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: AppStyles.screenPadding,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Information Section
            _buildFormSection(
              title: 'Basic Information',
              icon: Icons.person,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.cake),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your age';
                    }
                    final age = int.tryParse(value.trim());
                    if (age == null || age < 1 || age > 150) {
                      return 'Please enter a valid age';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.wc),
                  ),
                  items: _genderOptions.map((gender) {
                    return DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedGender = value!);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedBloodGroup,
                  decoration: const InputDecoration(
                    labelText: 'Blood Group',
                    prefixIcon: Icon(Icons.bloodtype),
                  ),
                  items: _bloodGroupOptions.map((bloodGroup) {
                    return DropdownMenuItem(
                      value: bloodGroup,
                      child: Text(bloodGroup),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedBloodGroup = value!);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Contact Information Section
            _buildFormSection(
              title: 'Contact Information',
              icon: Icons.contact_phone,
              children: [
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Emergency Contact Section
            _buildFormSection(
              title: 'Emergency Contact',
              icon: Icons.warning_amber,
              iconColor: AppColors.error,
              children: [
                TextFormField(
                  controller: _emergencyContactNameController,
                  decoration: const InputDecoration(
                    labelText: 'Emergency Contact Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter emergency contact name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emergencyContactPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Emergency Contact Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter emergency contact phone';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Medical Information Section
            _buildFormSection(
              title: 'Medical Information',
              icon: Icons.medical_information,
              iconColor: AppColors.success,
              children: [
                TextFormField(
                  controller: _medicalHistoryController,
                  decoration: const InputDecoration(
                    labelText: 'Medical History',
                    prefixIcon: Icon(Icons.history),
                    hintText: 'Enter any relevant medical history...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _allergiesController,
                  decoration: const InputDecoration(
                    labelText: 'Allergies',
                    prefixIcon: Icon(Icons.warning_outlined),
                    hintText: 'Enter any known allergies...',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _chronicDiseasesController,
                  decoration: const InputDecoration(
                    labelText: 'Chronic Diseases',
                    prefixIcon: Icon(Icons.local_hospital),
                    hintText: 'Enter any chronic diseases...',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            const SizedBox(height: 100), // Space for floating action button
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
            colors: [AppColors.secondary, Color(0xFF90CAF9)],
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
                _currentPatient!.name.isNotEmpty
                    ? _currentPatient!.name[0].toUpperCase()
                    : 'P',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentPatient!.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_currentPatient!.age} years • ${_currentPatient!.gender}',
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
                      _currentPatient!.bloodGroup,
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
    Color? iconColor,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: iconColor ?? AppColors.primary,
                  size: 24,
                ),
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

  Widget _buildFormSection({
    required String title,
    required IconData icon,
    Color? iconColor,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: iconColor ?? AppColors.primary,
                  size: 24,
                ),
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
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Not specified',
              style: TextStyle(
                color: value.isNotEmpty ? AppColors.textPrimary : Colors.grey,
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
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: value.contains('No ') ? Colors.grey : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _safeStringDisplay(String? value, String defaultText) {
    return (value == null || value.trim().isEmpty) ? defaultText : value;
  }
}