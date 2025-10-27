import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethod {
  bkash,
  nagad,
  rocket,
  bankTransfer,
  cash,
  card,
}

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
}

class Payment {
  final String id;
  final String billId;
  final String patientId;
  final String patientName;
  final double amount;
  final String currency;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? transactionId;
  final String? mobileNumber; // For mobile banking
  final String? bankAccount; // For bank transfers
  final String? reference;
  final String? failureReason;
  final Map<String, dynamic> metadata;

  Payment({
    required this.id,
    required this.billId,
    required this.patientId,
    required this.patientName,
    required this.amount,
    this.currency = 'BDT',
    required this.paymentMethod,
    this.status = PaymentStatus.pending,
    required this.createdAt,
    this.completedAt,
    this.transactionId,
    this.mobileNumber,
    this.bankAccount,
    this.reference,
    this.failureReason,
    this.metadata = const {},
  });

  factory Payment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Payment(
      id: doc.id,
      billId: data['billId'] ?? '',
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'BDT',
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.${data['paymentMethod']}',
        orElse: () => PaymentMethod.cash,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${data['status']}',
        orElse: () => PaymentStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
      transactionId: data['transactionId'],
      mobileNumber: data['mobileNumber'],
      bankAccount: data['bankAccount'],
      reference: data['reference'],
      failureReason: data['failureReason'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'billId': billId,
      'patientId': patientId,
      'patientName': patientName,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'transactionId': transactionId,
      'mobileNumber': mobileNumber,
      'bankAccount': bankAccount,
      'reference': reference,
      'failureReason': failureReason,
      'metadata': metadata,
    };
  }

  String get paymentMethodDisplayName {
    switch (paymentMethod) {
      case PaymentMethod.bkash:
        return 'bKash';
      case PaymentMethod.nagad:
        return 'Nagad';
      case PaymentMethod.rocket:
        return 'Rocket';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  Payment copyWith({
    String? id,
    String? billId,
    String? patientId,
    String? patientName,
    double? amount,
    String? currency,
    PaymentMethod? paymentMethod,
    PaymentStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? transactionId,
    String? mobileNumber,
    String? bankAccount,
    String? reference,
    String? failureReason,
    Map<String, dynamic>? metadata,
  }) {
    return Payment(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      transactionId: transactionId ?? this.transactionId,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      bankAccount: bankAccount ?? this.bankAccount,
      reference: reference ?? this.reference,
      failureReason: failureReason ?? this.failureReason,
      metadata: metadata ?? this.metadata,
    );
  }
}