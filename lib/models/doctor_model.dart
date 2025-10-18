import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String specialization;
  final String department;
  final String qualification;
  final String experience; // e.g., "8 years"
  final String bio;
  final String profileImageUrl;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final bool isAvailable; // Online/Offline status
  final double? rating; // Average rating
  final int? totalPatients; // Total patients treated

  DoctorModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.specialization,
    required this.department,
    required this.qualification,
    required this.experience,
    required this.bio,
    required this.profileImageUrl,
    required this.createdAt,
    this.updatedAt,
    this.isAvailable = true,
    this.rating,
    this.totalPatients,
  });

  // Convert DoctorModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'specialization': specialization,
      'department': department,
      'qualification': qualification,
      'experience': experience,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
      'isAvailable': isAvailable,
      'rating': rating ?? 0.0,
      'totalPatients': totalPatients ?? 0,
    };
  }

  // Create DoctorModel from Firestore document
  factory DoctorModel.fromMap(Map<String, dynamic> map, String documentId) {
    return DoctorModel(
      id: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      specialization: map['specialization'] ?? '',
      department: map['department'] ?? '',
      qualification: map['qualification'] ?? '',
      experience: map['experience'] ?? '',
      bio: map['bio'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'],
      isAvailable: map['isAvailable'] ?? true,
      rating: map['rating']?.toDouble(),
      totalPatients: map['totalPatients'],
    );
  }

  // Create a copy with updated fields
  DoctorModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? specialization,
    String? department,
    String? qualification,
    String? experience,
    String? bio,
    String? profileImageUrl,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    bool? isAvailable,
    double? rating,
    int? totalPatients,
  }) {
    return DoctorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      specialization: specialization ?? this.specialization,
      department: department ?? this.department,
      qualification: qualification ?? this.qualification,
      experience: experience ?? this.experience,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      totalPatients: totalPatients ?? this.totalPatients,
    );
  }
}

