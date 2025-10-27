import 'package:cloud_firestore/cloud_firestore.dart';

class Bill {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String appointmentId;
  final String description;
  final double amount;
  final String currency;
  final String status; // pending, paid, overdue, cancelled
  final DateTime createdAt;
  final DateTime dueDate;
  final DateTime? paidAt;
  final String? paymentId;
  final Map<String, dynamic> services; // List of services with costs
  final double? discount;
  final double? tax;
  final double totalAmount;

  Bill({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.appointmentId,
    required this.description,
    required this.amount,
    this.currency = 'BDT',
    this.status = 'pending',
    required this.createdAt,
    required this.dueDate,
    this.paidAt,
    this.paymentId,
    this.services = const {},
    this.discount,
    this.tax,
    required this.totalAmount,
  });

  factory Bill.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Bill(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      appointmentId: data['appointmentId'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'BDT',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      paidAt: data['paidAt'] != null ? (data['paidAt'] as Timestamp).toDate() : null,
      paymentId: data['paymentId'],
      services: Map<String, dynamic>.from(data['services'] ?? {}),
      discount: data['discount']?.toDouble(),
      tax: data['tax']?.toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'appointmentId': appointmentId,
      'description': description,
      'amount': amount,
      'currency': currency,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': Timestamp.fromDate(dueDate),
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'paymentId': paymentId,
      'services': services,
      'discount': discount,
      'tax': tax,
      'totalAmount': totalAmount,
    };
  }

  Bill copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? doctorId,
    String? doctorName,
    String? appointmentId,
    String? description,
    double? amount,
    String? currency,
    String? status,
    DateTime? createdAt,
    DateTime? dueDate,
    DateTime? paidAt,
    String? paymentId,
    Map<String, dynamic>? services,
    double? discount,
    double? tax,
    double? totalAmount,
  }) {
    return Bill(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      appointmentId: appointmentId ?? this.appointmentId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      paidAt: paidAt ?? this.paidAt,
      paymentId: paymentId ?? this.paymentId,
      services: services ?? this.services,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }
}