import 'package:flutter/material.dart';
import '../services/api_client.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  late Future<List<Map<String, dynamic>>> _paymentsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _paymentsFuture = ApiClient.fetchPayments();
    });
  }

  Future<void> _createPayment() async {
    final formKey = GlobalKey<FormState>();
    String invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';
    String customerName = '';
    double amount = 0.0;
    String status = 'Pending';
    String lane = '';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('New Payment', style: TextStyle(color: Colors.white)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Invoice #', labelStyle: TextStyle(color: Colors.white70)),
                  style: const TextStyle(color: Colors.white),
                  initialValue: invoiceNumber,
                  onSaved: (v) => invoiceNumber = v ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Customer Name', labelStyle: TextStyle(color: Colors.white70)),
                  style: const TextStyle(color: Colors.white),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  onSaved: (v) => customerName = v!,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Amount (INR)', labelStyle: TextStyle(color: Colors.white70)),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || double.tryParse(v) == null ? 'Invalid amount' : null,
                  onSaved: (v) => amount = double.parse(v!),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Status (Paid, Pending, Overdue)', labelStyle: TextStyle(color: Colors.white70)),
                  style: const TextStyle(color: Colors.white),
                  initialValue: status,
                  onSaved: (v) => status = v ?? 'Pending',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Lane', labelStyle: TextStyle(color: Colors.white70)),
                  style: const TextStyle(color: Colors.white),
                  onSaved: (v) => lane = v ?? '',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                try {
                  await ApiClient.createPayment({
                    'invoiceNumber': invoiceNumber,
                    'customerName': customerName,
                    'amount': amount,
                    'currency': 'INR',
                    'status': status,
                    'lane': lane,
                    'method': 'Manual',
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment created successfully')),
                  );
                  _refresh();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _paymentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No payments found'));
          }

          final payments = snapshot.data!;
          return ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.payment),
                  title: Text(payment['invoiceNumber'] ?? 'Unknown'),
                  subtitle: Text('${payment['customerName'] ?? 'Unknown'} - ₹${payment['amount'] ?? 0}'),
                  trailing: Text(
                    payment['status'] ?? 'Unknown',
                    style: TextStyle(
                      color: payment['status'] == 'Paid' ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPayment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
