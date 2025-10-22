import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/doctor_model.dart';
import '../../services/doctor_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final DoctorService _doctorService = DoctorService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDoctorDialog(context),
            tooltip: 'Add Doctor',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search doctors...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          // Doctors List
          Expanded(
            child: StreamBuilder<List<DoctorModel>>(
              stream: _doctorService.getDoctors(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading doctors',
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(color: Colors.grey.shade500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final doctors = snapshot.data ?? [];
                final filteredDoctors = doctors.where((doctor) {
                  return doctor.name.toLowerCase().contains(_searchQuery) ||
                         doctor.email.toLowerCase().contains(_searchQuery) ||
                         doctor.specialization.toLowerCase().contains(_searchQuery) ||
                         doctor.department.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredDoctors.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'No doctors found' : 'No doctors match your search',
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showAddDoctorDialog(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Doctor'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDoctors.length,
                  itemBuilder: (context, index) {
                    final doctor = filteredDoctors[index];
                    return _buildDoctorCard(doctor);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(DoctorModel doctor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Profile Image
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: doctor.profileImageUrl.isNotEmpty
                      ? NetworkImage(doctor.profileImageUrl)
                      : null,
                  child: doctor.profileImageUrl.isEmpty
                      ? Text(
                          doctor.name.isNotEmpty ? doctor.name[0].toUpperCase() : 'D',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                // Doctor Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctor.specialization,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctor.department,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: doctor.isAvailable ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    doctor.isAvailable ? 'Available' : 'Unavailable',
                    style: TextStyle(
                      fontSize: 12,
                      color: doctor.isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Contact Info
            Row(
              children: [
                Icon(Icons.email_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    doctor.email,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  doctor.phone,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showDoctorDetailsDialog(doctor),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showEditDoctorDialog(doctor),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showDeleteConfirmation(doctor),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDoctorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddEditDoctorDialog(
        onSave: (doctorData) async {
          try {
            final doctor = DoctorModel(
              id: '', // Will be auto-generated
              name: doctorData['name'],
              email: doctorData['email'],
              phone: doctorData['phone'],
              specialization: doctorData['specialization'],
              department: doctorData['department'],
              qualification: doctorData['qualification'],
              experience: doctorData['experience'],
              bio: doctorData['bio'],
              profileImageUrl: '',
              createdAt: Timestamp.now(),
              isAvailable: true,
            );

            await _doctorService.addDoctor(doctor);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Doctor added successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error adding doctor: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditDoctorDialog(DoctorModel doctor) {
    showDialog(
      context: context,
      builder: (context) => AddEditDoctorDialog(
        doctor: doctor,
        onSave: (doctorData) async {
          try {
            await _doctorService.updateDoctor(doctor.id, doctorData);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Doctor updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error updating doctor: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(DoctorModel doctor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Doctor'),
        content: Text('Are you sure you want to delete Dr. ${doctor.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _doctorService.deleteDoctor(doctor.id, doctor.id);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Doctor deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting doctor: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDoctorDetailsDialog(DoctorModel doctor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dr. ${doctor.name}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', doctor.email),
              _buildDetailRow('Phone', doctor.phone),
              _buildDetailRow('Specialization', doctor.specialization),
              _buildDetailRow('Department', doctor.department),
              _buildDetailRow('Qualification', doctor.qualification),
              _buildDetailRow('Experience', doctor.experience),
              _buildDetailRow('Status', doctor.isAvailable ? 'Available' : 'Unavailable'),
              if (doctor.bio.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Bio:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(doctor.bio),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class AddEditDoctorDialog extends StatefulWidget {
  final DoctorModel? doctor;
  final Function(Map<String, dynamic>) onSave;

  const AddEditDoctorDialog({
    super.key,
    this.doctor,
    required this.onSave,
  });

  @override
  State<AddEditDoctorDialog> createState() => _AddEditDoctorDialogState();
}

class _AddEditDoctorDialogState extends State<AddEditDoctorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _specializationController;
  late TextEditingController _departmentController;
  late TextEditingController _qualificationController;
  late TextEditingController _experienceController;
  late TextEditingController _bioController;
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.doctor?.name ?? '');
    _emailController = TextEditingController(text: widget.doctor?.email ?? '');
    _phoneController = TextEditingController(text: widget.doctor?.phone ?? '');
    _specializationController = TextEditingController(text: widget.doctor?.specialization ?? '');
    _departmentController = TextEditingController(text: widget.doctor?.department ?? '');
    _qualificationController = TextEditingController(text: widget.doctor?.qualification ?? '');
    _experienceController = TextEditingController(text: widget.doctor?.experience ?? '');
    _bioController = TextEditingController(text: widget.doctor?.bio ?? '');
    _isAvailable = widget.doctor?.isAvailable ?? true;
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.doctor == null ? 'Add Doctor' : 'Edit Doctor'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter doctor name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
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
                  controller: _specializationController,
                  label: 'Specialization',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter specialization';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _departmentController,
                  label: 'Department',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter department';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _qualificationController,
                  label: 'Qualification',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter qualification';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _experienceController,
                  label: 'Experience (e.g., "5 years")',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter experience';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio (Optional)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Available: '),
                    Switch(
                      value: _isAvailable,
                      onChanged: (value) {
                        setState(() {
                          _isAvailable = value;
                        });
                      },
                      activeThumbColor: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveDoctor,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.doctor == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }

  void _saveDoctor() {
    if (_formKey.currentState!.validate()) {
      final doctorData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'department': _departmentController.text.trim(),
        'qualification': _qualificationController.text.trim(),
        'experience': _experienceController.text.trim(),
        'bio': _bioController.text.trim(),
        'isAvailable': _isAvailable,
      };

      widget.onSave(doctorData);
      Navigator.of(context).pop();
    }
  }
}