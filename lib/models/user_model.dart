import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  admin,
  doctor,
  patient,
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final DateTime createdAt;
  final bool isEmailVerified;
  final String? phone;
  final String? gender;
  final String? dateOfBirth;
  final String? address;
  final String? profileImage;
  final String? specialization; // For doctors
  final String? departmentId; // For doctors
  final String? registrationNo; // For doctors
  final int? experience; // For doctors, in years
  final String? bloodGroup;
  final String status;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.isEmailVerified = false,
    this.phone,
    this.gender,
    this.dateOfBirth,
    this.address,
    this.profileImage,
    this.specialization,
    this.departmentId,
    this.registrationNo,
    this.experience,
    this.bloodGroup,
    this.status = 'active',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isEmailVerified': isEmailVerified,
      'phone': phone,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'address': address,
      'profileImage': profileImage,
      'specialization': specialization,
      'departmentId': departmentId,
      'registrationNo': registrationNo,
      'experience': experience,
      'bloodGroup': bloodGroup,
      'status': status,
    };
  }

  // Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.patient,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isEmailVerified: map['isEmailVerified'] ?? false,
      phone: map['phone'],
      gender: map['gender'],
      dateOfBirth: map['dateOfBirth'],
      address: map['address'],
      profileImage: map['profileImage'],
      specialization: map['specialization'],
      departmentId: map['departmentId'],
      registrationNo: map['registrationNo'],
      experience: map['experience'],
      bloodGroup: map['bloodGroup'],
      status: map['status'] ?? 'active',
    );
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    UserRole? role,
    DateTime? createdAt,
    bool? isEmailVerified,
    String? phone,
    String? gender,
    String? dateOfBirth,
    String? address,
    String? profileImage,
    String? specialization,
    String? departmentId,
    String? registrationNo,
    int? experience,
    String? bloodGroup,
    String? status,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      specialization: specialization ?? this.specialization,
      departmentId: departmentId ?? this.departmentId,
      registrationNo: registrationNo ?? this.registrationNo,
      experience: experience ?? this.experience,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      status: status ?? this.status,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

