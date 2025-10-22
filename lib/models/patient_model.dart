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

  // Helper method to safely convert dynamic values to String
  static String _safeStringConversion(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is List) {
      // If it's a list, join the elements with commas
      return value.map((e) => e.toString()).join(', ');
    }
    return value.toString();
  }

  // Helper method to safely convert dynamic values to int
  static int _safeIntConversion(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) return value.toInt();
    return 0;
  }

  // Create PatientModel from Firestore document
  factory PatientModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PatientModel(
      id: documentId,
      name: _safeStringConversion(map['name']),
      age: _safeIntConversion(map['age']),
      gender: _safeStringConversion(map['gender']),
      phone: _safeStringConversion(map['phone']),
      email: _safeStringConversion(map['email']),
      address: _safeStringConversion(map['address']),
      emergencyContactName: _safeStringConversion(map['emergencyContactName']),
      emergencyContactPhone: _safeStringConversion(map['emergencyContactPhone']),
      bloodGroup: _safeStringConversion(map['bloodGroup']),
      medicalHistory: _safeStringConversion(map['medicalHistory']),
      allergies: _safeStringConversion(map['allergies']),
      chronicDiseases: _safeStringConversion(map['chronicDiseases']),
      createdAt: map['createdAt'] ?? Timestamp.now(),
      createdBy: _safeStringConversion(map['createdBy']),
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

