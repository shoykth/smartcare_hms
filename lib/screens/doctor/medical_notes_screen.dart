import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/medical_note_model.dart';
import '../../models/patient_model.dart';
import '../../services/medical_note_service.dart';
import '../../services/patient_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';

class MedicalNotesScreen extends StatefulWidget {
  const MedicalNotesScreen({super.key});

  @override
  State<MedicalNotesScreen> createState() => _MedicalNotesScreenState();
}

class _MedicalNotesScreenState extends State<MedicalNotesScreen> {
  final MedicalNoteService _noteService = MedicalNoteService();
  final PatientService _patientService = PatientService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  bool _showPatientsList = true;

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
        title: Text(_showPatientsList ? 'Select Patient' : 'Medical Notes'),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        actions: [
          if (!_showPatientsList)
            IconButton(
              icon: const Icon(Icons.people),
              onPressed: () => setState(() => _showPatientsList = true),
              tooltip: 'Back to Patients',
            ),
        ],
      ),
      body: _showPatientsList 
          ? _buildPatientsListView() 
          : _buildNotesListView(user.uid),
    );
  }

  Widget _buildPatientsListView() {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search patients...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
        // Patients List
        Expanded(
          child: StreamBuilder<List<PatientModel>>(
            stream: _patientService.getPatients(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              final allPatients = snapshot.data ?? [];
              final filteredPatients = allPatients.where((patient) {
                return patient.name.toLowerCase().contains(_searchQuery) ||
                       patient.email.toLowerCase().contains(_searchQuery) ||
                       patient.phone.contains(_searchQuery);
              }).toList();

              if (filteredPatients.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty ? 'No patients found' : 'No patients match your search',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredPatients.length,
                itemBuilder: (context, index) {
                  final patient = filteredPatients[index];
                  return _buildPatientCard(patient);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPatientCard(PatientModel patient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPatientOptions(patient),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      patient.email,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      patient.phone,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPatientOptions(PatientModel patient) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              patient.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              patient.email,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showCreatePrescriptionDialog(patient);
                    },
                    icon: const Icon(Icons.medication),
                    label: const Text('Add Prescription'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _viewPatientNotes(patient);
                    },
                    icon: const Icon(Icons.note_alt),
                    label: const Text('View Notes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showCreateFullNoteDialog(patient);
                },
                icon: const Icon(Icons.note_add),
                label: const Text('Create Full Medical Note'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePrescriptionDialog(PatientModel patient) {
    final diagnosisController = TextEditingController();
    final prescriptionController = TextEditingController();
    final followUpController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add Prescription for ${patient.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: diagnosisController,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosis',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: prescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Prescription',
                    hintText: 'Enter medications, dosage, and instructions...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: followUpController,
                  decoration: const InputDecoration(
                    labelText: 'Follow-up Instructions',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (prescriptionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a prescription'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                setState(() => isLoading = true);

                try {
                  final user = _authService.currentUser;
                  if (user == null) throw Exception('User not logged in');

                  final userData = await _authService.getUserData(user.uid);
                  if (userData == null) throw Exception('User data not found');

                  final note = MedicalNoteModel(
                    id: '',
                    doctorId: user.uid,
                    patientId: patient.id,
                    doctorName: userData.name,
                    patientName: patient.name,
                    chiefComplaint: 'Prescription Visit',
                    historyPresentIllness: '',
                    pastMedicalHistory: '',
                    surgicalHistory: '',
                    socialHistory: '',
                    familyHistory: '',
                    assessmentPlan: '',
                    diagnosis: diagnosisController.text.trim(),
                    prescription: prescriptionController.text.trim(),
                    followUpInstructions: followUpController.text.trim(),
                    createdAt: Timestamp.now(),
                  );

                  await _noteService.createMedicalNote(note);

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Prescription added successfully!'),
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

                setState(() => isLoading = false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              child: isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Add Prescription'),
            ),
          ],
        ),
      ),
    );
  }

  void _viewPatientNotes(PatientModel patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PatientNotesScreen(patient: patient),
      ),
    );
  }

  void _showCreateFullNoteDialog(PatientModel patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _CreateFullNoteScreen(patient: patient),
      ),
    );
  }

  Widget _buildNotesListView(String doctorId) {
    return StreamBuilder<List<MedicalNoteModel>>(
      stream: _noteService.getMedicalNotesByDoctor(doctorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final notes = snapshot.data ?? [];

        if (notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.note_alt, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No medical notes yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a patient to create notes',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return _buildNoteCard(note);
          },
        );
      },
    );
  }

  Widget _buildNoteCard(MedicalNoteModel note) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final date = note.createdAt.toDate();

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
              builder: (context) => _NoteDetailScreen(note: note),
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
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      note.patientName.isNotEmpty
                          ? note.patientName[0].toUpperCase()
                          : 'P',
                      style: const TextStyle(
                        color: AppColors.primary,
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
                          note.patientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${dateFormat.format(date)} at ${timeFormat.format(date)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (note.prescription?.isNotEmpty == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Prescription',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (note.diagnosis?.isNotEmpty == true) ...[
                Text(
                  'Diagnosis: ${note.diagnosis}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],
              if (note.chiefComplaint.isNotEmpty) ...[
                Text(
                  note.chiefComplaint,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
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

// Patient Notes Screen
class _PatientNotesScreen extends StatelessWidget {
  final PatientModel patient;

  const _PatientNotesScreen({required this.patient});

  @override
  Widget build(BuildContext context) {
    final noteService = MedicalNoteService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${patient.name} - Medical Notes'),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<MedicalNoteModel>>(
        stream: noteService.getMedicalNotesByPatient(patient.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final notes = snapshot.data ?? [];

          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_alt, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No medical notes for ${patient.name}',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return _buildNoteCard(context, note);
            },
          );
        },
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, MedicalNoteModel note) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final date = note.createdAt.toDate();

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
              builder: (context) => _NoteDetailScreen(note: note),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. ${note.doctorName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${dateFormat.format(date)} at ${timeFormat.format(date)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (note.prescription?.isNotEmpty == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Prescription',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (note.diagnosis?.isNotEmpty == true) ...[
                Text(
                  'Diagnosis: ${note.diagnosis}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],
              if (note.chiefComplaint.isNotEmpty) ...[
                Text(
                  note.chiefComplaint,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
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

// Note Detail Screen
class _NoteDetailScreen extends StatefulWidget {
  final MedicalNoteModel note;

  const _NoteDetailScreen({required this.note});

  @override
  State<_NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<_NoteDetailScreen> {
  final MedicalNoteService _noteService = MedicalNoteService();
  final AuthService _authService = AuthService();
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final date = widget.note.createdAt.toDate();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Medical Note Details'),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editNote(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmation();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Note'),
                  ],
                ),
              ),
            ],
          ),
        ],
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            widget.note.patientName.isNotEmpty
                                ? widget.note.patientName[0].toUpperCase()
                                : 'P',
                            style: const TextStyle(
                              color: AppColors.primary,
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
                                widget.note.patientName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Dr. ${widget.note.doctorName}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${dateFormat.format(date)} at ${timeFormat.format(date)}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Prescription Section (if available)
            if (widget.note.prescription?.isNotEmpty == true) ...[
              _buildSection(
                'Prescription',
                widget.note.prescription!,
                Icons.medication,
                AppColors.success,
              ),
              const SizedBox(height: 16),
            ],

            // Diagnosis Section (if available)
            if (widget.note.diagnosis?.isNotEmpty == true) ...[
              _buildSection(
                'Diagnosis',
                widget.note.diagnosis!,
                Icons.local_hospital,
                AppColors.error,
              ),
              const SizedBox(height: 16),
            ],

            // Chief Complaint
            if (widget.note.chiefComplaint.isNotEmpty) ...[
              _buildSection(
                'Chief Complaint',
                widget.note.chiefComplaint,
                Icons.report_problem,
                Colors.orange,
              ),
              const SizedBox(height: 16),
            ],

            // Follow-up Instructions (if available)
            if (widget.note.followUpInstructions?.isNotEmpty == true) ...[
              _buildSection(
                'Follow-up Instructions',
                widget.note.followUpInstructions!,
                Icons.schedule,
                AppColors.primary,
              ),
              const SizedBox(height: 16),
            ],

            // Other sections (if available)
            if (widget.note.historyPresentIllness.isNotEmpty) ...[
              _buildSection(
                'History of Present Illness',
                widget.note.historyPresentIllness,
                Icons.history,
                Colors.blue,
              ),
              const SizedBox(height: 16),
            ],

            if (widget.note.assessmentPlan.isNotEmpty) ...[
              _buildSection(
                'Assessment & Plan',
                widget.note.assessmentPlan,
                Icons.assignment,
                Colors.purple,
              ),
              const SizedBox(height: 16),
            ],

            // Vital Signs (if available)
            if (_hasVitalSigns()) ...[
              _buildVitalSignsSection(),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  bool _hasVitalSigns() {
    return (widget.note.bloodPressure?.isNotEmpty == true) ||
           (widget.note.heartRate?.isNotEmpty == true) ||
           (widget.note.temperature?.isNotEmpty == true) ||
           (widget.note.respiratoryRate?.isNotEmpty == true) ||
           (widget.note.oxygenSaturation?.isNotEmpty == true);
  }

  Widget _buildVitalSignsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.red.shade400),
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
            if (widget.note.bloodPressure?.isNotEmpty == true)
              _buildVitalSignRow('Blood Pressure', widget.note.bloodPressure!),
            if (widget.note.heartRate?.isNotEmpty == true)
              _buildVitalSignRow('Heart Rate', widget.note.heartRate!),
            if (widget.note.temperature?.isNotEmpty == true)
              _buildVitalSignRow('Temperature', widget.note.temperature!),
            if (widget.note.respiratoryRate?.isNotEmpty == true)
              _buildVitalSignRow('Respiratory Rate', widget.note.respiratoryRate!),
            if (widget.note.oxygenSaturation?.isNotEmpty == true)
              _buildVitalSignRow('Oxygen Saturation', widget.note.oxygenSaturation!),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalSignRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon, Color color) {
    return Card(
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

  void _editNote() {
    // Navigate to edit screen (we'll create this)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _EditNoteScreen(note: widget.note),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medical Note'),
        content: const Text(
          'Are you sure you want to delete this medical note? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isDeleting ? null : _deleteNote,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: _isDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNote() async {
    setState(() => _isDeleting = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _noteService.deleteMedicalNote(widget.note.id, user.uid);

      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        Navigator.of(context).pop(); // Go back to notes list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medical note deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting note: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Edit Note Screen
class _EditNoteScreen extends StatefulWidget {
  final MedicalNoteModel note;

  const _EditNoteScreen({required this.note});

  @override
  State<_EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<_EditNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final MedicalNoteService _noteService = MedicalNoteService();
  final AuthService _authService = AuthService();
  
  late TextEditingController _chiefComplaintController;
  late TextEditingController _historyPresentIllnessController;
  late TextEditingController _pastMedicalHistoryController;
  late TextEditingController _surgicalHistoryController;
  late TextEditingController _socialHistoryController;
  late TextEditingController _familyHistoryController;
  late TextEditingController _assessmentPlanController;
  late TextEditingController _bloodPressureController;
  late TextEditingController _heartRateController;
  late TextEditingController _temperatureController;
  late TextEditingController _respiratoryRateController;
  late TextEditingController _oxygenSaturationController;
  late TextEditingController _diagnosisController;
  late TextEditingController _prescriptionController;
  late TextEditingController _labOrdersController;
  late TextEditingController _followUpInstructionsController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _chiefComplaintController = TextEditingController(text: widget.note.chiefComplaint);
    _historyPresentIllnessController = TextEditingController(text: widget.note.historyPresentIllness);
    _pastMedicalHistoryController = TextEditingController(text: widget.note.pastMedicalHistory);
    _surgicalHistoryController = TextEditingController(text: widget.note.surgicalHistory);
    _socialHistoryController = TextEditingController(text: widget.note.socialHistory);
    _familyHistoryController = TextEditingController(text: widget.note.familyHistory);
    _assessmentPlanController = TextEditingController(text: widget.note.assessmentPlan);
    _bloodPressureController = TextEditingController(text: widget.note.bloodPressure ?? '');
    _heartRateController = TextEditingController(text: widget.note.heartRate ?? '');
    _temperatureController = TextEditingController(text: widget.note.temperature ?? '');
    _respiratoryRateController = TextEditingController(text: widget.note.respiratoryRate ?? '');
    _oxygenSaturationController = TextEditingController(text: widget.note.oxygenSaturation ?? '');
    _diagnosisController = TextEditingController(text: widget.note.diagnosis ?? '');
    _prescriptionController = TextEditingController(text: widget.note.prescription ?? '');
    _labOrdersController = TextEditingController(text: widget.note.labOrders ?? '');
    _followUpInstructionsController = TextEditingController(text: widget.note.followUpInstructions ?? '');
  }

  @override
  void dispose() {
    _chiefComplaintController.dispose();
    _historyPresentIllnessController.dispose();
    _pastMedicalHistoryController.dispose();
    _surgicalHistoryController.dispose();
    _socialHistoryController.dispose();
    _familyHistoryController.dispose();
    _assessmentPlanController.dispose();
    _bloodPressureController.dispose();
    _heartRateController.dispose();
    _temperatureController.dispose();
    _respiratoryRateController.dispose();
    _oxygenSaturationController.dispose();
    _diagnosisController.dispose();
    _prescriptionController.dispose();
    _labOrdersController.dispose();
    _followUpInstructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Edit Note for ${widget.note.patientName}'),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateNote,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chief Complaint
              _buildSectionCard(
                'Chief Complaint',
                Icons.report_problem,
                Colors.orange,
                [
                  TextFormField(
                    controller: _chiefComplaintController,
                    decoration: const InputDecoration(
                      labelText: 'Chief Complaint',
                      hintText: 'Primary reason for visit',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Chief complaint is required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              
              // History of Present Illness
              _buildSectionCard(
                'History of Present Illness',
                Icons.history,
                Colors.blue,
                [
                  TextFormField(
                    controller: _historyPresentIllnessController,
                    decoration: const InputDecoration(
                      labelText: 'History of Present Illness',
                      hintText: 'Detailed description of current symptoms',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                ],
              ),

              // Past Medical History
              _buildSectionCard(
                'Past Medical History',
                Icons.medical_services,
                Colors.purple,
                [
                  TextFormField(
                    controller: _pastMedicalHistoryController,
                    decoration: const InputDecoration(
                      labelText: 'Past Medical History',
                      hintText: 'Previous medical conditions, surgeries, etc.',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),

              // Vital Signs
              _buildSectionCard(
                'Vital Signs',
                Icons.favorite,
                Colors.red,
                [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bloodPressureController,
                          decoration: const InputDecoration(
                            labelText: 'Blood Pressure',
                            hintText: '120/80',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _heartRateController,
                          decoration: const InputDecoration(
                            labelText: 'Heart Rate',
                            hintText: '72 bpm',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _temperatureController,
                          decoration: const InputDecoration(
                            labelText: 'Temperature',
                            hintText: '98.6°F',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _respiratoryRateController,
                          decoration: const InputDecoration(
                            labelText: 'Respiratory Rate',
                            hintText: '16/min',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _oxygenSaturationController,
                    decoration: const InputDecoration(
                      labelText: 'Oxygen Saturation',
                      hintText: '98%',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),

              // Assessment & Plan
              _buildSectionCard(
                'Assessment & Plan',
                Icons.assignment,
                Colors.green,
                [
                  TextFormField(
                    controller: _assessmentPlanController,
                    decoration: const InputDecoration(
                      labelText: 'Assessment & Plan',
                      hintText: 'Clinical assessment and treatment plan',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                ],
              ),

              // Diagnosis
              _buildSectionCard(
                'Diagnosis',
                Icons.local_hospital,
                AppColors.error,
                [
                  TextFormField(
                    controller: _diagnosisController,
                    decoration: const InputDecoration(
                      labelText: 'Diagnosis',
                      hintText: 'Primary and secondary diagnoses',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),

              // Prescription
              _buildSectionCard(
                'Prescription',
                Icons.medication,
                AppColors.success,
                [
                  TextFormField(
                    controller: _prescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Prescription',
                      hintText: 'Medications and dosages',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),

              // Lab Orders
              _buildSectionCard(
                'Lab Orders',
                Icons.science,
                Colors.teal,
                [
                  TextFormField(
                    controller: _labOrdersController,
                    decoration: const InputDecoration(
                      labelText: 'Lab Orders',
                      hintText: 'Laboratory tests and investigations',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),

              // Follow-up Instructions
              _buildSectionCard(
                'Follow-up Instructions',
                Icons.schedule,
                AppColors.primary,
                [
                  TextFormField(
                    controller: _followUpInstructionsController,
                    decoration: const InputDecoration(
                      labelText: 'Follow-up Instructions',
                      hintText: 'Next steps and follow-up care',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Color color, List<Widget> children) {
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
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<void> _updateNote() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updateData = {
        'chiefComplaint': _chiefComplaintController.text.trim(),
        'historyPresentIllness': _historyPresentIllnessController.text.trim(),
        'pastMedicalHistory': _pastMedicalHistoryController.text.trim(),
        'surgicalHistory': _surgicalHistoryController.text.trim(),
        'socialHistory': _socialHistoryController.text.trim(),
        'familyHistory': _familyHistoryController.text.trim(),
        'assessmentPlan': _assessmentPlanController.text.trim(),
        'bloodPressure': _bloodPressureController.text.trim().isNotEmpty 
            ? _bloodPressureController.text.trim() : null,
        'heartRate': _heartRateController.text.trim().isNotEmpty 
            ? _heartRateController.text.trim() : null,
        'temperature': _temperatureController.text.trim().isNotEmpty 
            ? _temperatureController.text.trim() : null,
        'respiratoryRate': _respiratoryRateController.text.trim().isNotEmpty 
            ? _respiratoryRateController.text.trim() : null,
        'oxygenSaturation': _oxygenSaturationController.text.trim().isNotEmpty 
            ? _oxygenSaturationController.text.trim() : null,
        'diagnosis': _diagnosisController.text.trim().isNotEmpty 
            ? _diagnosisController.text.trim() : null,
        'prescription': _prescriptionController.text.trim().isNotEmpty 
            ? _prescriptionController.text.trim() : null,
        'labOrders': _labOrdersController.text.trim().isNotEmpty 
            ? _labOrdersController.text.trim() : null,
        'followUpInstructions': _followUpInstructionsController.text.trim().isNotEmpty 
            ? _followUpInstructionsController.text.trim() : null,
      };

      await _noteService.updateMedicalNote(widget.note.id, updateData);

      if (mounted) {
        Navigator.of(context).pop(); // Go back to detail screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medical note updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating note: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Create Full Note Screen
class _CreateFullNoteScreen extends StatefulWidget {
  final PatientModel patient;

  const _CreateFullNoteScreen({required this.patient});

  @override
  State<_CreateFullNoteScreen> createState() => _CreateFullNoteScreenState();
}

class _CreateFullNoteScreenState extends State<_CreateFullNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final MedicalNoteService _noteService = MedicalNoteService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  
  // Form controllers
  final _chiefComplaintController = TextEditingController();
  final _historyPresentIllnessController = TextEditingController();
  final _pastMedicalHistoryController = TextEditingController();
  final _surgicalHistoryController = TextEditingController();
  final _socialHistoryController = TextEditingController();
  final _familyHistoryController = TextEditingController();
  final _assessmentPlanController = TextEditingController();
  
  // Vital signs controllers
  final _bloodPressureController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _respiratoryRateController = TextEditingController();
  final _oxygenSaturationController = TextEditingController();
  
  // Additional fields controllers
  final _diagnosisController = TextEditingController();
  final _prescriptionController = TextEditingController();
  final _labOrdersController = TextEditingController();
  final _followUpInstructionsController = TextEditingController();

  @override
  void dispose() {
    _chiefComplaintController.dispose();
    _historyPresentIllnessController.dispose();
    _pastMedicalHistoryController.dispose();
    _surgicalHistoryController.dispose();
    _socialHistoryController.dispose();
    _familyHistoryController.dispose();
    _assessmentPlanController.dispose();
    _bloodPressureController.dispose();
    _heartRateController.dispose();
    _temperatureController.dispose();
    _respiratoryRateController.dispose();
    _oxygenSaturationController.dispose();
    _diagnosisController.dispose();
    _prescriptionController.dispose();
    _labOrdersController.dispose();
    _followUpInstructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Create Note for ${widget.patient.name}'),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          widget.patient.name.isNotEmpty
                              ? widget.patient.name[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            color: AppColors.primary,
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
                              widget.patient.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.patient.email,
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
              const SizedBox(height: 20),

              // Vital Signs Section
              _buildSectionCard(
                'Vital Signs',
                Icons.monitor_heart,
                [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bloodPressureController,
                          decoration: const InputDecoration(
                            labelText: 'Blood Pressure',
                            hintText: 'e.g., 120/80',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _heartRateController,
                          decoration: const InputDecoration(
                            labelText: 'Heart Rate',
                            hintText: 'e.g., 72 bpm',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _temperatureController,
                          decoration: const InputDecoration(
                            labelText: 'Temperature',
                            hintText: 'e.g., 98.6°F',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _respiratoryRateController,
                          decoration: const InputDecoration(
                            labelText: 'Respiratory Rate',
                            hintText: 'e.g., 16/min',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _oxygenSaturationController,
                    decoration: const InputDecoration(
                      labelText: 'Oxygen Saturation',
                      hintText: 'e.g., 98%',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Chief Complaint (Required)
              _buildSectionCard(
                'Chief Complaint *',
                Icons.report_problem,
                [
                  TextFormField(
                    controller: _chiefComplaintController,
                    decoration: const InputDecoration(
                      labelText: 'Chief Complaint',
                      hintText: 'Patient\'s main concern or reason for visit',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Chief complaint is required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // History Sections
              _buildSectionCard(
                'History of Present Illness',
                Icons.history,
                [
                  TextFormField(
                    controller: _historyPresentIllnessController,
                    decoration: const InputDecoration(
                      labelText: 'History of Present Illness',
                      hintText: 'Detailed description of current symptoms',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSectionCard(
                'Past Medical History',
                Icons.medical_information,
                [
                  TextFormField(
                    controller: _pastMedicalHistoryController,
                    decoration: const InputDecoration(
                      labelText: 'Past Medical History',
                      hintText: 'Previous illnesses, conditions, hospitalizations',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSectionCard(
                'Surgical History',
                Icons.local_hospital,
                [
                  TextFormField(
                    controller: _surgicalHistoryController,
                    decoration: const InputDecoration(
                      labelText: 'Surgical History',
                      hintText: 'Previous surgeries and procedures',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSectionCard(
                'Social History',
                Icons.people,
                [
                  TextFormField(
                    controller: _socialHistoryController,
                    decoration: const InputDecoration(
                      labelText: 'Social History',
                      hintText: 'Smoking, alcohol, occupation, lifestyle',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSectionCard(
                'Family History',
                Icons.family_restroom,
                [
                  TextFormField(
                    controller: _familyHistoryController,
                    decoration: const InputDecoration(
                      labelText: 'Family History',
                      hintText: 'Family medical history and genetic conditions',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Diagnosis
              _buildSectionCard(
                'Diagnosis',
                Icons.assignment,
                [
                  TextFormField(
                    controller: _diagnosisController,
                    decoration: const InputDecoration(
                      labelText: 'Diagnosis',
                      hintText: 'Primary and secondary diagnoses',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Assessment and Plan (Required)
              _buildSectionCard(
                'Assessment and Plan *',
                Icons.assignment_turned_in,
                [
                  TextFormField(
                    controller: _assessmentPlanController,
                    decoration: const InputDecoration(
                      labelText: 'Assessment and Plan',
                      hintText: 'Clinical assessment and treatment plan',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Assessment and plan is required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Prescription
              _buildSectionCard(
                'Prescription',
                Icons.medication,
                [
                  TextFormField(
                    controller: _prescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Prescription',
                      hintText: 'Medications, dosage, and instructions',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Lab Orders
              _buildSectionCard(
                'Lab Orders',
                Icons.science,
                [
                  TextFormField(
                    controller: _labOrdersController,
                    decoration: const InputDecoration(
                      labelText: 'Lab Orders',
                      hintText: 'Laboratory tests and investigations',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Follow-up Instructions
              _buildSectionCard(
                'Follow-up Instructions',
                Icons.schedule,
                [
                  TextFormField(
                    controller: _followUpInstructionsController,
                    decoration: const InputDecoration(
                      labelText: 'Follow-up Instructions',
                      hintText: 'Next appointment, care instructions',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveFullNote,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isLoading ? 'Saving...' : 'Save Full Medical Note'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
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

  Future<void> _saveFullNote() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userData = await _authService.getUserData(user.uid);
      if (userData == null) throw Exception('User data not found');

      final note = MedicalNoteModel(
        id: '',
        doctorId: user.uid,
        patientId: widget.patient.id,
        doctorName: userData.name,
        patientName: widget.patient.name,
        chiefComplaint: _chiefComplaintController.text.trim(),
        historyPresentIllness: _historyPresentIllnessController.text.trim(),
        pastMedicalHistory: _pastMedicalHistoryController.text.trim(),
        surgicalHistory: _surgicalHistoryController.text.trim(),
        socialHistory: _socialHistoryController.text.trim(),
        familyHistory: _familyHistoryController.text.trim(),
        assessmentPlan: _assessmentPlanController.text.trim(),
        bloodPressure: _bloodPressureController.text.trim().isNotEmpty 
            ? _bloodPressureController.text.trim() : null,
        heartRate: _heartRateController.text.trim().isNotEmpty 
            ? _heartRateController.text.trim() : null,
        temperature: _temperatureController.text.trim().isNotEmpty 
            ? _temperatureController.text.trim() : null,
        respiratoryRate: _respiratoryRateController.text.trim().isNotEmpty 
            ? _respiratoryRateController.text.trim() : null,
        oxygenSaturation: _oxygenSaturationController.text.trim().isNotEmpty 
            ? _oxygenSaturationController.text.trim() : null,
        diagnosis: _diagnosisController.text.trim().isNotEmpty 
            ? _diagnosisController.text.trim() : null,
        prescription: _prescriptionController.text.trim().isNotEmpty 
            ? _prescriptionController.text.trim() : null,
        labOrders: _labOrdersController.text.trim().isNotEmpty 
            ? _labOrdersController.text.trim() : null,
        followUpInstructions: _followUpInstructionsController.text.trim().isNotEmpty 
            ? _followUpInstructionsController.text.trim() : null,
        createdAt: Timestamp.now(),
      );

      await _noteService.createMedicalNote(note);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Full medical note saved successfully!'),
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

    setState(() => _isLoading = false);
  }
}

