import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/bill_model.dart';
import '../../models/payment_model.dart';
import '../../services/payment_service.dart';
import '../../services/auth_service.dart';
import 'payment_screen.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> with SingleTickerProviderStateMixin {
  final PaymentService _paymentService = PaymentService();
  final AuthService _authService = AuthService();
  late TabController _tabController;
  Map<String, dynamic>? _paymentStats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPaymentStats();
    _generateDummyDataIfNeeded();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentStats() async {
    final user = _authService.currentUser;
    if (user != null) {
      final stats = await _paymentService.getPaymentStats(user.uid);
      setState(() {
        _paymentStats = stats;
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _generateDummyDataIfNeeded() async {
    final user = _authService.currentUser;
    if (user != null) {
      // Generate dummy bills for demonstration
      await _paymentService.generateDummyBills(user.uid, user.displayName ?? 'Patient');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing & Payments'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Bills'),
            Tab(icon: Icon(Icons.payment), text: 'Payments'),
            Tab(icon: Icon(Icons.analytics), text: 'Overview'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBillsTab(),
          _buildPaymentsTab(),
          _buildOverviewTab(),
        ],
      ),
    );
  }

  Widget _buildBillsTab() {
    final user = _authService.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view bills'));
    }

    return StreamBuilder<List<Bill>>(
      stream: _paymentService.getBillsByPatient(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final bills = snapshot.data ?? [];

        if (bills.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No bills found', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadPaymentStats,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index];
              return _buildBillCard(bill);
            },
          ),
        );
      },
    );
  }

  Widget _buildBillCard(Bill bill) {
    Color statusColor;
    IconData statusIcon;
    
    switch (bill.status) {
      case 'paid':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'overdue':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    bill.description,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        bill.status.toUpperCase(),
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Doctor: ${bill.doctorName}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text('Date: ${_formatDate(bill.createdAt)}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '৳${bill.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                if (bill.status == 'pending')
                  ElevatedButton(
                    onPressed: () => _navigateToPayment(bill),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Pay Now'),
                  ),
              ],
            ),
            if (bill.services.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const Text('Services:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...bill.services.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key.replaceAll('_', ' ').toUpperCase()),
                    Text('৳${entry.value.toStringAsFixed(2)}'),
                  ],
                ),
              )),
              if (bill.tax != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tax'),
                    Text('৳${bill.tax!.toStringAsFixed(2)}'),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsTab() {
    final user = _authService.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view payments'));
    }

    return StreamBuilder<List<Payment>>(
      stream: _paymentService.getPaymentsByPatient(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final payments = snapshot.data ?? [];

        if (payments.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No payments found', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            return _buildPaymentCard(payment);
          },
        );
      },
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    Color statusColor;
    IconData statusIcon;
    
    switch (payment.status) {
      case PaymentStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case PaymentStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case PaymentStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  payment.paymentMethodDisplayName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        payment.statusDisplayName,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (payment.transactionId != null)
              Text('Transaction ID: ${payment.transactionId}', style: const TextStyle(color: Colors.grey)),
            Text('Date: ${_formatDate(payment.createdAt)}', style: const TextStyle(color: Colors.grey)),
            if (payment.mobileNumber != null)
              Text('Mobile: ${payment.mobileNumber}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              '৳${payment.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            if (payment.failureReason != null) ...[
              const SizedBox(height: 8),
              Text(
                'Reason: ${payment.failureReason}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_paymentStats == null) {
      return const Center(child: Text('Unable to load payment statistics'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Overview',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildStatCard(
            'Total Billed',
            '৳${_paymentStats!['totalBilled'].toStringAsFixed(2)}',
            Icons.receipt_long,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            'Total Paid',
            '৳${_paymentStats!['totalPaid'].toStringAsFixed(2)}',
            Icons.check_circle,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            'Pending Amount',
            '৳${_paymentStats!['totalPending'].toStringAsFixed(2)}',
            Icons.pending,
            Colors.orange,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Bills',
                  '${_paymentStats!['totalBills']}',
                  Icons.description,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Paid Bills',
                  '${_paymentStats!['paidBills']}',
                  Icons.done_all,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Pending Bills',
                  '${_paymentStats!['pendingBills']}',
                  Icons.pending_actions,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Transactions',
                  '${_paymentStats!['totalTransactions']}',
                  Icons.swap_horiz,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPayment(Bill bill) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentScreen(bill: bill),
      ),
    ).then((_) => _loadPaymentStats());
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}