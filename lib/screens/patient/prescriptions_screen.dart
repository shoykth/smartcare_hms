import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/medical_note_model.dart';
import '../../services/medical_note_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  final MedicalNoteService _noteService = MedicalNoteService();
  final AuthService _authService = AuthService();
  
  String? _currentUserId;
  List<MedicalNoteModel> _allPrescriptions = [];
  Map<String, UserModel> _doctorsMap = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        _currentUserId = user.uid;
        
        // Get all medical notes for this patient
        final notesStream = _noteService.getMedicalNotesByPatient(_currentUserId!);
        final notes = await notesStream.first;
        
        // Filter notes that have prescriptions
        final prescriptions = notes.where((note) => 
          note.prescription != null && note.prescription!.isNotEmpty).toList();
        
        // Get unique doctor IDs
        final doctorIds = prescriptions.map((p) => p.doctorId).toSet();
        
        // Load doctor information
        final doctorsMap = <String, UserModel>{};
        for (final doctorId in doctorIds) {
          final doctor = await _authService.getUserData(doctorId);
          if (doctor != null) {
            doctorsMap[doctorId] = doctor;
          }
        }
        
        setState(() {
          _allPrescriptions = prescriptions;
          _doctorsMap = doctorsMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading prescriptions: $e')),
        );
      }
    }
  }

  List<String> get _filteredDoctorIds {
    if (_searchQuery.isEmpty) {
      return _doctorsMap.keys.toList();
    }
    
    return _doctorsMap.keys.where((doctorId) {
      final doctor = _doctorsMap[doctorId];
      if (doctor == null) return false;
      
      final doctorName = doctor.name.toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      return doctorName.contains(query);
    }).toList();
  }

  List<MedicalNoteModel> _getPrescriptionsForDoctor(String doctorId) {
    return _allPrescriptions.where((p) => p.doctorId == doctorId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Prescriptions'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildPrescriptionsContent(),
    );
  }

  Widget _buildPrescriptionsContent() {
    if (_allPrescriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Prescriptions Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have any prescriptions yet.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: _buildDoctorsList(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search doctors...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[600]!),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildDoctorsList() {
    final filteredDoctorIds = _filteredDoctorIds;
    
    if (filteredDoctorIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No doctors found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredDoctorIds.length,
      itemBuilder: (context, index) {
        final doctorId = filteredDoctorIds[index];
        final doctor = _doctorsMap[doctorId]!;
        final prescriptions = _getPrescriptionsForDoctor(doctorId);
        
        return _buildDoctorCard(doctor, prescriptions);
      },
    );
  }

  Widget _buildDoctorCard(UserModel doctor, List<MedicalNoteModel> prescriptions) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(
            doctor.name.isNotEmpty ? doctor.name[0].toUpperCase() : 'D',
            style: TextStyle(
              color: Colors.blue[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          'Dr. ${doctor.name}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '${prescriptions.length} prescription${prescriptions.length == 1 ? '' : 's'}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        children: prescriptions.map((prescription) => 
          _buildPrescriptionItem(prescription)).toList(),
      ),
    );
  }

  Widget _buildPrescriptionItem(MedicalNoteModel prescription) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prescription',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                  fontSize: 14,
                ),
              ),
              Text(
                _formatDate(prescription.createdAt),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              prescription.prescription ?? 'No prescription details',
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          if (prescription.diagnosis != null && prescription.diagnosis!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Diagnosis: ${prescription.diagnosis}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (prescription.followUpInstructions != null && 
              prescription.followUpInstructions!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Follow-up: ${prescription.followUpInstructions}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}