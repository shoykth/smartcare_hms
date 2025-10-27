import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bill_model.dart';
import '../models/payment_model.dart';
import 'database_service.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _databaseService = DatabaseService();

  // Collections
  CollectionReference get _billsCollection => _firestore.collection('bills');
  CollectionReference get _paymentsCollection => _firestore.collection('payments');

  // Generate dummy bills for testing
  Future<void> generateDummyBills(String patientId, String patientName) async {
    final bills = [
      Bill(
        id: '',
        patientId: patientId,
        patientName: patientName,
        doctorId: 'doc1',
        doctorName: 'Dr. Rahman',
        appointmentId: 'apt1',
        description: 'General Consultation',
        amount: 800.0,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        dueDate: DateTime.now().add(const Duration(days: 25)),
        services: {
          'consultation': 500.0,
          'prescription': 200.0,
          'lab_test': 100.0,
        },
        tax: 50.0,
        totalAmount: 850.0,
      ),
      Bill(
        id: '',
        patientId: patientId,
        patientName: patientName,
        doctorId: 'doc2',
        doctorName: 'Dr. Fatima',
        appointmentId: 'apt2',
        description: 'Blood Test & X-Ray',
        amount: 1200.0,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        dueDate: DateTime.now().add(const Duration(days: 20)),
        services: {
          'blood_test': 600.0,
          'x_ray': 500.0,
          'consultation': 100.0,
        },
        tax: 75.0,
        totalAmount: 1275.0,
      ),
      Bill(
        id: '',
        patientId: patientId,
        patientName: patientName,
        doctorId: 'doc3',
        doctorName: 'Dr. Ahmed',
        appointmentId: 'apt3',
        description: 'Dental Checkup',
        amount: 1500.0,
        status: 'paid',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        dueDate: DateTime.now().subtract(const Duration(days: 5)),
        paidAt: DateTime.now().subtract(const Duration(days: 3)),
        services: {
          'dental_checkup': 800.0,
          'cleaning': 400.0,
          'consultation': 300.0,
        },
        tax: 100.0,
        totalAmount: 1600.0,
      ),
    ];

    for (Bill bill in bills) {
      await _billsCollection.add(bill.toFirestore());
    }
  }

  // Get bills for a patient
  Stream<List<Bill>> getBillsByPatient(String patientId) {
    return _billsCollection
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Bill.fromFirestore(doc)).toList());
  }

  // Get payments for a patient
  Stream<List<Payment>> getPaymentsByPatient(String patientId) {
    return _paymentsCollection
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList());
  }

  // Get a specific bill
  Future<Bill?> getBillById(String billId) async {
    try {
      DocumentSnapshot doc = await _billsCollection.doc(billId).get();
      if (doc.exists) {
        return Bill.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting bill: $e');
      return null;
    }
  }

  // Process payment (dummy implementation)
  Future<Map<String, dynamic>> processPayment({
    required String billId,
    required String patientId,
    required String patientName,
    required double amount,
    required PaymentMethod paymentMethod,
    String? mobileNumber,
    String? bankAccount,
    String? pin,
  }) async {
    try {
      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Generate dummy transaction ID
      String transactionId = _generateTransactionId(paymentMethod);

      // Simulate payment success/failure (90% success rate)
      bool isSuccess = Random().nextInt(100) < 90;

      Payment payment = Payment(
        id: '',
        billId: billId,
        patientId: patientId,
        patientName: patientName,
        amount: amount,
        paymentMethod: paymentMethod,
        status: isSuccess ? PaymentStatus.completed : PaymentStatus.failed,
        createdAt: DateTime.now(),
        completedAt: isSuccess ? DateTime.now() : null,
        transactionId: isSuccess ? transactionId : null,
        mobileNumber: mobileNumber,
        bankAccount: bankAccount,
        failureReason: isSuccess ? null : 'Insufficient balance or network error',
        metadata: {
          'pin_verified': pin != null,
          'processing_time': '2.3s',
          'gateway': _getPaymentGateway(paymentMethod),
        },
      );

      // Save payment record
      DocumentReference paymentRef = await _paymentsCollection.add(payment.toFirestore());

      if (isSuccess) {
        // Update bill status to paid
        await _billsCollection.doc(billId).update({
          'status': 'paid',
          'paidAt': Timestamp.fromDate(DateTime.now()),
          'paymentId': paymentRef.id,
        });
      }

      return {
        'success': isSuccess,
        'paymentId': paymentRef.id,
        'transactionId': transactionId,
        'message': isSuccess 
            ? 'Payment successful! Transaction ID: $transactionId'
            : 'Payment failed. Please try again.',
        'payment': payment,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Payment processing error: $e',
      };
    }
  }

  // Generate dummy transaction ID based on payment method
  String _generateTransactionId(PaymentMethod method) {
    String prefix;
    switch (method) {
      case PaymentMethod.bkash:
        prefix = 'BKS';
        break;
      case PaymentMethod.nagad:
        prefix = 'NGD';
        break;
      case PaymentMethod.rocket:
        prefix = 'RKT';
        break;
      case PaymentMethod.bankTransfer:
        prefix = 'BNK';
        break;
      case PaymentMethod.card:
        prefix = 'CRD';
        break;
      case PaymentMethod.cash:
        prefix = 'CSH';
        break;
    }
    
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String random = Random().nextInt(9999).toString().padLeft(4, '0');
    return '$prefix$timestamp$random';
  }

  // Get payment gateway name
  String _getPaymentGateway(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bkash:
        return 'bKash Gateway';
      case PaymentMethod.nagad:
        return 'Nagad Gateway';
      case PaymentMethod.rocket:
        return 'Rocket Gateway';
      case PaymentMethod.bankTransfer:
        return 'Bank Gateway';
      case PaymentMethod.card:
        return 'Card Gateway';
      case PaymentMethod.cash:
        return 'Cash Payment';
    }
  }

  // Get payment statistics for a patient
  Future<Map<String, dynamic>> getPaymentStats(String patientId) async {
    try {
      QuerySnapshot billsSnapshot = await _billsCollection
          .where('patientId', isEqualTo: patientId)
          .get();

      QuerySnapshot paymentsSnapshot = await _paymentsCollection
          .where('patientId', isEqualTo: patientId)
          .where('status', isEqualTo: 'completed')
          .get();

      double totalBilled = 0;
      double totalPaid = 0;
      double totalPending = 0;
      int totalBills = billsSnapshot.docs.length;
      int paidBills = 0;

      for (var doc in billsSnapshot.docs) {
        Bill bill = Bill.fromFirestore(doc);
        totalBilled += bill.totalAmount;
        if (bill.status == 'paid') {
          totalPaid += bill.totalAmount;
          paidBills++;
        } else {
          totalPending += bill.totalAmount;
        }
      }

      return {
        'totalBilled': totalBilled,
        'totalPaid': totalPaid,
        'totalPending': totalPending,
        'totalBills': totalBills,
        'paidBills': paidBills,
        'pendingBills': totalBills - paidBills,
        'totalTransactions': paymentsSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting payment stats: $e');
      return {
        'totalBilled': 0.0,
        'totalPaid': 0.0,
        'totalPending': 0.0,
        'totalBills': 0,
        'paidBills': 0,
        'pendingBills': 0,
        'totalTransactions': 0,
      };
    }
  }

  // Validate mobile number for mobile banking
  bool validateMobileNumber(String number, PaymentMethod method) {
    // Remove any spaces or special characters
    String cleanNumber = number.replaceAll(RegExp(r'[^\d]'), '');
    
    // Bangladesh mobile number validation
    if (cleanNumber.length == 11 && cleanNumber.startsWith('01')) {
      return true;
    }
    if (cleanNumber.length == 13 && cleanNumber.startsWith('880')) {
      return true;
    }
    return false;
  }

  // Get supported payment methods
  List<PaymentMethod> getSupportedPaymentMethods() {
    return [
      PaymentMethod.bkash,
      PaymentMethod.nagad,
      PaymentMethod.rocket,
      PaymentMethod.bankTransfer,
      PaymentMethod.cash,
    ];
  }
}