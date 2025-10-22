import 'package:flutter/material.dart';
import '../../models/medical_note_model.dart';
import '../../services/medical_note_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  final MedicalNoteService _noteService = MedicalNoteService();
  final AuthService _authService = AuthService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Medical Records'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search medical records...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          // Medical Records List
          Expanded(
            child: StreamBuilder<List<MedicalNoteModel>>(
              stream:
              _noteService.getMedicalNotesByPatient(_authService.currentUser?.uid
              ?? ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading medical records',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Medical Records Found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your medical records will appear here once doctors create them.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final notes = snapshot.data!.where((note) {
                  if (_searchQuery.isEmpty) return true;
                  return note.diagnosis?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
                         note.prescription?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
                         note.doctorName.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();

                if (notes.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No records found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try searching with different keywords.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Sort notes by creation date (newest first)
                notes.sort((a, b) => b.createdAt.toDate().compareTo(a.createdAt.toDate()));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return _buildMedicalRecordCard(note);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalRecordCard(MedicalNoteModel note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => _MedicalRecordDetailScreen(note: note),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with doctor info and date
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 20,
                    child: Text(
                      note.doctorName.isNotEmpty ? note.doctorName[0].toUpperCase() : 'D',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. ${note.doctorName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _formatDate(note.createdAt.toDate()),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Chief Complaint
              if (note.chiefComplaint.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.report_problem, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text(
                      'Chief Complaint:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  note.chiefComplaint,
                  style: TextStyle(color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              
              // Diagnosis
              if (note.diagnosis != null && note.diagnosis!.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.local_hospital, size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    const Text(
                      'Diagnosis:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  note.diagnosis!,
                  style: TextStyle(color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              
              // Prescription
              if (note.prescription != null && note.prescription!.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.medication, size: 16, color: AppColors.success),
                    const SizedBox(width: 8),
                    const Text(
                      'Prescription:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  note.prescription!,
                  style: TextStyle(color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${_formatTime(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

// Medical Record Detail Screen
class _MedicalRecordDetailScreen extends StatelessWidget {
  final MedicalNoteModel note;

  const _MedicalRecordDetailScreen({required this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Medical Record Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 24,
                      child: Text(
                        note.doctorName.isNotEmpty ? note.doctorName[0].toUpperCase() : 'D',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dr. ${note.doctorName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            _formatDate(note.createdAt.toDate()),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Chief Complaint
            if (note.chiefComplaint.isNotEmpty)
              _buildSection(
                'Chief Complaint',
                note.chiefComplaint,
                Icons.report_problem,
                Colors.orange,
              ),

            // History of Present Illness
            if (note.historyPresentIllness.isNotEmpty)
              _buildSection(
                'History of Present Illness',
                note.historyPresentIllness,
                Icons.history,
                Colors.blue,
              ),

            // Vital Signs
            if (_hasVitalSigns())
              _buildVitalSignsSection(),

            // Assessment & Plan
            if (note.assessmentPlan.isNotEmpty)
              _buildSection(
                'Assessment & Plan',
                note.assessmentPlan,
                Icons.assignment,
                Colors.green,
              ),

            // Diagnosis
            if (note.diagnosis != null && note.diagnosis!.isNotEmpty)
              _buildSection(
                'Diagnosis',
                note.diagnosis!,
                Icons.local_hospital,
                AppColors.error,
              ),

            // Prescription
            if (note.prescription != null && note.prescription!.isNotEmpty)
              _buildSection(
                'Prescription',
                note.prescription!,
                Icons.medication,
                AppColors.success,
              ),

            // Lab Orders
            if (note.labOrders != null && note.labOrders!.isNotEmpty)
              _buildSection(
                'Lab Orders',
                note.labOrders!,
                Icons.science,
                Colors.teal,
              ),

            // Follow-up Instructions
            if (note.followUpInstructions != null && note.followUpInstructions!.isNotEmpty)
              _buildSection(
                'Follow-up Instructions',
                note.followUpInstructions!,
                Icons.schedule,
                AppColors.primary,
              ),

            // Past Medical History
            if (note.pastMedicalHistory.isNotEmpty)
              _buildSection(
                'Past Medical History',
                note.pastMedicalHistory,
                Icons.medical_services,
                Colors.purple,
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasVitalSigns() {
    return (note.bloodPressure != null && note.bloodPressure!.isNotEmpty) ||
        (note.heartRate != null && note.heartRate!.isNotEmpty) ||
        (note.temperature != null && note.temperature!.isNotEmpty) ||
        (note.respiratoryRate != null && note.respiratoryRate!.isNotEmpty) ||
        (note.oxygenSaturation != null && note.oxygenSaturation!.isNotEmpty);
  }

  Widget _buildVitalSignsSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Vital Signs',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (note.bloodPressure != null && note.bloodPressure!.isNotEmpty)
              _buildVitalSignRow('Blood Pressure', note.bloodPressure!, Icons.monitor_heart),
            if (note.heartRate != null && note.heartRate!.isNotEmpty)
              _buildVitalSignRow('Heart Rate', note.heartRate!, Icons.favorite),
            if (note.temperature != null && note.temperature!.isNotEmpty)
              _buildVitalSignRow('Temperature', note.temperature!, Icons.thermostat),
            if (note.respiratoryRate != null && note.respiratoryRate!.isNotEmpty)
              _buildVitalSignRow('Respiratory Rate', note.respiratoryRate!, Icons.air),
            if (note.oxygenSaturation != null && note.oxygenSaturation!.isNotEmpty)
              _buildVitalSignRow('Oxygen Saturation', note.oxygenSaturation!, Icons.water_drop),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalSignRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${_formatTime(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}