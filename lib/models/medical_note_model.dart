import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalNoteModel {
  final String id;
  final String doctorId;
  final String patientId;
  final String doctorName;
  final String patientName;
  final String? appointmentId;
  
  // Structured note sections
  final String chiefComplaint;
  final String historyPresentIllness;
  final String pastMedicalHistory;
  final String surgicalHistory;
  final String socialHistory;
  final String familyHistory;
  final String assessmentPlan;
  
  // Vital signs
  final String? bloodPressure;
  final String? heartRate;
  final String? temperature;
  final String? respiratoryRate;
  final String? oxygenSaturation;
  
  // Additional fields
  final String? diagnosis;
  final String? prescription;
  final String? labOrders;
  final String? followUpInstructions;
  
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  MedicalNoteModel({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.doctorName,
    required this.patientName,
    this.appointmentId,
    required this.chiefComplaint,
    required this.historyPresentIllness,
    required this.pastMedicalHistory,
    required this.surgicalHistory,
    required this.socialHistory,
    required this.familyHistory,
    required this.assessmentPlan,
    this.bloodPressure,
    this.heartRate,
    this.temperature,
    this.respiratoryRate,
    this.oxygenSaturation,
    this.diagnosis,
    this.prescription,
    this.labOrders,
    this.followUpInstructions,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorId': doctorId,
      'patientId': patientId,
      'doctorName': doctorName,
      'patientName': patientName,
      'appointmentId': appointmentId ?? '',
      'chiefComplaint': chiefComplaint,
      'historyPresentIllness': historyPresentIllness,
      'pastMedicalHistory': pastMedicalHistory,
      'surgicalHistory': surgicalHistory,
      'socialHistory': socialHistory,
      'familyHistory': familyHistory,
      'assessmentPlan': assessmentPlan,
      'bloodPressure': bloodPressure ?? '',
      'heartRate': heartRate ?? '',
      'temperature': temperature ?? '',
      'respiratoryRate': respiratoryRate ?? '',
      'oxygenSaturation': oxygenSaturation ?? '',
      'diagnosis': diagnosis ?? '',
      'prescription': prescription ?? '',
      'labOrders': labOrders ?? '',
      'followUpInstructions': followUpInstructions ?? '',
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  // Create from Map
  factory MedicalNoteModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MedicalNoteModel(
      id: documentId,
      doctorId: map['doctorId'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      patientName: map['patientName'] ?? '',
      appointmentId: map['appointmentId'],
      chiefComplaint: map['chiefComplaint'] ?? '',
      historyPresentIllness: map['historyPresentIllness'] ?? '',
      pastMedicalHistory: map['pastMedicalHistory'] ?? '',
      surgicalHistory: map['surgicalHistory'] ?? '',
      socialHistory: map['socialHistory'] ?? '',
      familyHistory: map['familyHistory'] ?? '',
      assessmentPlan: map['assessmentPlan'] ?? '',
      bloodPressure: map['bloodPressure'],
      heartRate: map['heartRate'],
      temperature: map['temperature'],
      respiratoryRate: map['respiratoryRate'],
      oxygenSaturation: map['oxygenSaturation'],
      diagnosis: map['diagnosis'],
      prescription: map['prescription'],
      labOrders: map['labOrders'],
      followUpInstructions: map['followUpInstructions'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'],
    );
  }

  // Copy with
  MedicalNoteModel copyWith({
    String? id,
    String? doctorId,
    String? patientId,
    String? doctorName,
    String? patientName,
    String? appointmentId,
    String? chiefComplaint,
    String? historyPresentIllness,
    String? pastMedicalHistory,
    String? surgicalHistory,
    String? socialHistory,
    String? familyHistory,
    String? assessmentPlan,
    String? bloodPressure,
    String? heartRate,
    String? temperature,
    String? respiratoryRate,
    String? oxygenSaturation,
    String? diagnosis,
    String? prescription,
    String? labOrders,
    String? followUpInstructions,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return MedicalNoteModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      doctorName: doctorName ?? this.doctorName,
      patientName: patientName ?? this.patientName,
      appointmentId: appointmentId ?? this.appointmentId,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      historyPresentIllness: historyPresentIllness ?? this.historyPresentIllness,
      pastMedicalHistory: pastMedicalHistory ?? this.pastMedicalHistory,
      surgicalHistory: surgicalHistory ?? this.surgicalHistory,
      socialHistory: socialHistory ?? this.socialHistory,
      familyHistory: familyHistory ?? this.familyHistory,
      assessmentPlan: assessmentPlan ?? this.assessmentPlan,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      heartRate: heartRate ?? this.heartRate,
      temperature: temperature ?? this.temperature,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      oxygenSaturation: oxygenSaturation ?? this.oxygenSaturation,
      diagnosis: diagnosis ?? this.diagnosis,
      prescription: prescription ?? this.prescription,
      labOrders: labOrders ?? this.labOrders,
      followUpInstructions: followUpInstructions ?? this.followUpInstructions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

