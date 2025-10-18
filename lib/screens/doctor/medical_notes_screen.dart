import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/medical_note_model.dart';
import '../../models/patient_model.dart';
import '../../services/medical_note_service.dart';
import '../../services/patient_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class MedicalNotesScreen extends StatefulWidget {
  const MedicalNotesScreen({super.key});

  @override
  State<MedicalNotesScreen> createState() => _MedicalNotesScreenState();
}

class _MedicalNotesScreenState extends State<MedicalNotesScreen> {
  final MedicalNoteService _noteService = MedicalNoteService();
  final PatientService _patientService = PatientService();
  final AuthService _authService = AuthService();

  bool _showCreateForm = false;

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
        title: const Text('Medical Notes'),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
      ),
      body: _showCreateForm
          ? _CreateNoteForm(
              onCancel: () => setState(() => _showCreateForm = false),
              onSaved: () => setState(() => _showCreateForm = false),
            )
          : _buildNotesList(user.uid),
      floatingActionButton: _showCreateForm
          ? null
          : FloatingActionButton.extended(
              onPressed: () => setState(() => _showCreateForm = true),
              icon: const Icon(Icons.add),
              label: const Text('New Note'),
              backgroundColor: AppColors.success,
            ),
    );
  }

  Widget _buildNotesList(String doctorId) {
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
                  'Tap + to create your first note',
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
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dateFormat.format(date)} • ${timeFormat.format(date)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              if (note.diagnosis != null && note.diagnosis!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.medical_information,
                          size: 16, color: Colors.purple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Diagnosis: ${note.diagnosis}',
                          style: const TextStyle(
                            color: Colors.purple,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (note.chiefComplaint.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note.chiefComplaint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Create Note Form
class _CreateNoteForm extends StatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onSaved;

  const _CreateNoteForm({
    required this.onCancel,
    required this.onSaved,
  });

  @override
  State<_CreateNoteForm> createState() => _CreateNoteFormState();
}

class _CreateNoteFormState extends State<_CreateNoteForm> {
  final _formKey = GlobalKey<FormState>();
  final MedicalNoteService _noteService = MedicalNoteService();
  final PatientService _patientService = PatientService();
  final AuthService _authService = AuthService();

  PatientModel? _selectedPatient;
  bool _isLoading = false;

  // Controllers
  final _chiefComplaintController = TextEditingController();
  final _historyPresentIllnessController = TextEditingController();
  final _pastMedicalHistoryController = TextEditingController();
  final _surgicalHistoryController = TextEditingController();
  final _socialHistoryController = TextEditingController();
  final _familyHistoryController = TextEditingController();
  final _assessmentPlanController = TextEditingController();
  final _bloodPressureController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _respiratoryRateController = TextEditingController();
  final _oxygenSaturationController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _prescriptionController = TextEditingController();
  final _labOrdersController = TextEditingController();
  final _followUpController = TextEditingController();

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
    _followUpController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a patient'),
          backgroundColor: AppColors.error,
        ),
      );
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
        patientId: _selectedPatient!.id,
        doctorName: userData.name,
        patientName: _selectedPatient!.name,
        chiefComplaint: _chiefComplaintController.text.trim(),
        historyPresentIllness: _historyPresentIllnessController.text.trim(),
        pastMedicalHistory: _pastMedicalHistoryController.text.trim(),
        surgicalHistory: _surgicalHistoryController.text.trim(),
        socialHistory: _socialHistoryController.text.trim(),
        familyHistory: _familyHistoryController.text.trim(),
        assessmentPlan: _assessmentPlanController.text.trim(),
        bloodPressure: _bloodPressureController.text.trim(),
        heartRate: _heartRateController.text.trim(),
        temperature: _temperatureController.text.trim(),
        respiratoryRate: _respiratoryRateController.text.trim(),
        oxygenSaturation: _oxygenSaturationController.text.trim(),
        diagnosis: _diagnosisController.text.trim(),
        prescription: _prescriptionController.text.trim(),
        labOrders: _labOrdersController.text.trim(),
        followUpInstructions: _followUpController.text.trim(),
        createdAt: Timestamp.now(),
      );

      await _noteService.createMedicalNote(note);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medical note created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onSaved();
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
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: AppStyles.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Selection
            _buildSectionTitle('Patient Information'),
            const SizedBox(height: 16),
            _buildPatientSelector(),
            const SizedBox(height: 24),

            // Vital Signs
            _buildSectionTitle('Vital Signs'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _bloodPressureController,
                    label: 'Blood Pressure',
                    hint: 'e.g., 120/80',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _heartRateController,
                    label: 'Heart Rate',
                    hint: 'e.g., 72 bpm',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _temperatureController,
                    label: 'Temperature',
                    hint: 'e.g., 98.6°F',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _oxygenSaturationController,
                    label: 'O2 Saturation',
                    hint: 'e.g., 98%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Structured Note Sections
            _buildSectionTitle('Chief Complaint'),
            const SizedBox(height: 16),
            _buildMultilineField(
              controller: _chiefComplaintController,
              hint: 'Main reason for visit',
              required: true,
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('History of Present Illness'),
            const SizedBox(height: 16),
            _buildMultilineField(
              controller: _historyPresentIllnessController,
              hint: 'Detailed history of current condition',
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Past Medical History'),
            const SizedBox(height: 16),
            _buildMultilineField(
              controller: _pastMedicalHistoryController,
              hint: 'Previous medical conditions, medications',
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Surgical History'),
            const SizedBox(height: 16),
            _buildMultilineField(
              controller: _surgicalHistoryController,
              hint: 'Previous surgeries and procedures',
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Social History'),
            const SizedBox(height: 16),
            _buildMultilineField(
              controller: _socialHistoryController,
              hint: 'Smoking, alcohol, occupation',
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Family History'),
            const SizedBox(height: 16),
            _buildMultilineField(
              controller: _familyHistoryController,
              hint: 'Family medical conditions',
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Diagnosis'),
            const SizedBox(height: 16),
            _buildMultilineField(
              controller: _diagnosisController,
              hint: 'Primary and differential diagnoses',
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Assessment and Plan'),
            const SizedBox(height: 16),
            _buildMultilineField(
              controller: _assessmentPlanController,
              hint: 'Treatment plan and recommendations',
              required: true,
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Prescription'),
            const SizedBox(height: 16),
            _buildMultilineField(
              controller: _prescriptionController,
              hint: 'Medications with dosage and duration',
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Lab Orders'),
            const SizedBox(height: 16),
            _buildMultilineField(
              controller: _labOrdersController,
              hint: 'Lab tests and imaging ordered',
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Follow-up Instructions'),
            const SizedBox(height: 16),
            _buildMultilineField(
              controller: _followUpController,
              hint: 'When to return, what to monitor',
            ),
            const SizedBox(height: 32),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Save Note',
                    onPressed: _saveNote,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
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

  Widget _buildPatientSelector() {
    return StreamBuilder<List<PatientModel>>(
      stream: _patientService.getPatients(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final patients = snapshot.data!;

        return DropdownButtonFormField<PatientModel>(
          value: _selectedPatient,
          decoration: InputDecoration(
            labelText: 'Select Patient',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: patients.map((patient) {
            return DropdownMenuItem<PatientModel>(
              value: patient,
              child: Text('${patient.name} - ${patient.age} yrs'),
            );
          }).toList(),
          onChanged: (patient) {
            setState(() => _selectedPatient = patient);
          },
          validator: (value) {
            if (value == null) {
              return 'Please select a patient';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildMultilineField({
    required TextEditingController controller,
    required String hint,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: required
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            }
          : null,
    );
  }
}

// Note Detail Screen
class _NoteDetailScreen extends StatelessWidget {
  final MedicalNoteModel note;

  const _NoteDetailScreen({required this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Medical Note Details'),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: AppStyles.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard('Patient', note.patientName),
            _buildInfoCard('Doctor', note.doctorName),
            _buildInfoCard('Date', DateFormat('MMM dd, yyyy').format(note.createdAt.toDate())),
            if (note.bloodPressure != null && note.bloodPressure!.isNotEmpty)
              _buildInfoCard('Blood Pressure', note.bloodPressure!),
            if (note.heartRate != null && note.heartRate!.isNotEmpty)
              _buildInfoCard('Heart Rate', note.heartRate!),
            if (note.temperature != null && note.temperature!.isNotEmpty)
              _buildInfoCard('Temperature', note.temperature!),
            _buildSectionCard('Chief Complaint', note.chiefComplaint),
            _buildSectionCard('History of Present Illness', note.historyPresentIllness),
            _buildSectionCard('Past Medical History', note.pastMedicalHistory),
            _buildSectionCard('Surgical History', note.surgicalHistory),
            _buildSectionCard('Social History', note.socialHistory),
            _buildSectionCard('Family History', note.familyHistory),
            if (note.diagnosis != null && note.diagnosis!.isNotEmpty)
              _buildSectionCard('Diagnosis', note.diagnosis!),
            _buildSectionCard('Assessment & Plan', note.assessmentPlan),
            if (note.prescription != null && note.prescription!.isNotEmpty)
              _buildSectionCard('Prescription', note.prescription!),
            if (note.labOrders != null && note.labOrders!.isNotEmpty)
              _buildSectionCard('Lab Orders', note.labOrders!),
            if (note.followUpInstructions != null && note.followUpInstructions!.isNotEmpty)
              _buildSectionCard('Follow-up Instructions', note.followUpInstructions!),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(value),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, String content) {
    if (content.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

