import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/patient_model.dart';
import '../../services/patient_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddPatientScreen extends StatefulWidget {
  final PatientModel? patient; // For editing existing patient

  const AddPatientScreen({super.key, this.patient});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientService = PatientService();
  final _authService = AuthService();

  // Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _chronicDiseasesController = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedBloodGroup = 'A+';
  bool _isLoading = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      _loadPatientData();
    }
  }

  void _loadPatientData() {
    final patient = widget.patient!;
    _nameController.text = patient.name;
    _ageController.text = patient.age.toString();
    _phoneController.text = patient.phone;
    _emailController.text = patient.email;
    _addressController.text = patient.address;
    _emergencyNameController.text = patient.emergencyContactName;
    _emergencyPhoneController.text = patient.emergencyContactPhone;
    _medicalHistoryController.text = patient.medicalHistory;
    _allergiesController.text = patient.allergies;
    _chronicDiseasesController.text = patient.chronicDiseases;
    
    // Ensure gender value exists in options, otherwise use default
    _selectedGender = _genderOptions.contains(patient.gender) 
        ? patient.gender 
        : _genderOptions.first;
    
    // Ensure blood group value exists in options, otherwise use default
    _selectedBloodGroup = _bloodGroups.contains(patient.bloodGroup) 
        ? patient.bloodGroup 
        : _bloodGroups.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _medicalHistoryController.dispose();
    _allergiesController.dispose();
    _chronicDiseasesController.dispose();
    super.dispose();
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      if (widget.patient == null) {
        // Add new patient
        final patient = PatientModel(
          id: '', // Will be set by Firestore
          name: _nameController.text.trim(),
          age: int.parse(_ageController.text.trim()),
          gender: _selectedGender,
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          address: _addressController.text.trim(),
          emergencyContactName: _emergencyNameController.text.trim(),
          emergencyContactPhone: _emergencyPhoneController.text.trim(),
          bloodGroup: _selectedBloodGroup,
          medicalHistory: _medicalHistoryController.text.trim(),
          allergies: _allergiesController.text.trim(),
          chronicDiseases: _chronicDiseasesController.text.trim(),
          createdAt: Timestamp.now(),
          createdBy: currentUser.uid,
        );

        await _patientService.addPatient(patient);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Patient added successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        // Update existing patient
        final data = {
          'name': _nameController.text.trim(),
          'age': int.parse(_ageController.text.trim()),
          'gender': _selectedGender,
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'address': _addressController.text.trim(),
          'emergencyContactName': _emergencyNameController.text.trim(),
          'emergencyContactPhone': _emergencyPhoneController.text.trim(),
          'bloodGroup': _selectedBloodGroup,
          'medicalHistory': _medicalHistoryController.text.trim(),
          'allergies': _allergiesController.text.trim(),
          'chronicDiseases': _chronicDiseasesController.text.trim(),
          'createdBy': currentUser.uid,
        };

        await _patientService.updatePatient(widget.patient!.id, data);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Patient updated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.patient != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Patient' : 'Add New Patient'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: AppStyles.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Section
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _nameController,
                label: 'Full Name',
                prefixIcon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter patient name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _ageController,
                      label: 'Age',
                      prefixIcon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter age';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid age';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Gender',
                      value: _selectedGender,
                      items: _genderOptions,
                      onChanged: (value) {
                        setState(() => _selectedGender = value!);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildDropdown(
                label: 'Blood Group',
                value: _selectedBloodGroup,
                items: _bloodGroups,
                onChanged: (value) {
                  setState(() => _selectedBloodGroup = value!);
                },
              ),
              const SizedBox(height: 24),

              // Contact Information Section
              _buildSectionTitle('Contact Information'),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _emailController,
                label: 'Email Address',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _addressController,
                label: 'Address',
                prefixIcon: Icons.location_on,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Emergency Contact Section
              _buildSectionTitle('Emergency Contact'),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _emergencyNameController,
                label: 'Emergency Contact Name',
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter emergency contact name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _emergencyPhoneController,
                label: 'Emergency Contact Phone',
                prefixIcon: Icons.phone_in_talk,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter emergency contact phone';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Medical Information Section
              _buildSectionTitle('Medical Information'),
              const SizedBox(height: 16),

              _buildMultilineField(
                controller: _medicalHistoryController,
                label: 'Medical History',
                hint: 'Enter previous medical conditions, surgeries, etc.',
              ),
              const SizedBox(height: 16),

              _buildMultilineField(
                controller: _allergiesController,
                label: 'Allergies',
                hint: 'List any known allergies',
              ),
              const SizedBox(height: 16),

              _buildMultilineField(
                controller: _chronicDiseasesController,
                label: 'Chronic Diseases',
                hint: 'Enter any chronic conditions',
              ),
              const SizedBox(height: 32),

              // Save Button
              CustomButton(
                text: isEdit ? 'Update Patient' : 'Save Patient',
                onPressed: _savePatient,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    // Ensure the value exists in items, otherwise use the first item
    String validValue = items.contains(value) ? value : items.first;
    
    return DropdownButtonFormField<String>(
      value: validValue,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildMultilineField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

