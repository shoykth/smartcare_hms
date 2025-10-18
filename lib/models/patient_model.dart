import 'package:cloud_firestore/cloud_firestore.dart';

class PatientModel {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String phone;
  final String email;
  final String address;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String bloodGroup;
  final String medicalHistory;
  final String allergies;
  final String chronicDiseases;
  final Timestamp createdAt;
  final String createdBy; // doctor or admin UID
  final Timestamp? updatedAt;

  PatientModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.phone,
    required this.email,
    required this.address,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.bloodGroup,
    required this.medicalHistory,
    required this.allergies,
    required this.chronicDiseases,
    required this.createdAt,
    required this.createdBy,
    this.updatedAt,
  });

  // Convert PatientModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'phone': phone,
      'email': email,
      'address': address,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'bloodGroup': bloodGroup,
      'medicalHistory': medicalHistory,
      'allergies': allergies,
      'chronicDiseases': chronicDiseases,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  // Create PatientModel from Firestore document
  factory PatientModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PatientModel(
      id: documentId,
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      emergencyContactName: map['emergencyContactName'] ?? '',
      emergencyContactPhone: map['emergencyContactPhone'] ?? '',
      bloodGroup: map['bloodGroup'] ?? '',
      medicalHistory: map['medicalHistory'] ?? '',
      allergies: map['allergies'] ?? '',
      chronicDiseases: map['chronicDiseases'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      createdBy: map['createdBy'] ?? '',
      updatedAt: map['updatedAt'],
    );
  }

  // Create a copy with updated fields
  PatientModel copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? phone,
    String? email,
    String? address,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? bloodGroup,
    String? medicalHistory,
    String? allergies,
    String? chronicDiseases,
    Timestamp? createdAt,
    String? createdBy,
    Timestamp? updatedAt,
  }) {
    return PatientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      allergies: allergies ?? this.allergies,
      chronicDiseases: chronicDiseases ?? this.chronicDiseases,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

