import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({Key? key}) : super(key: key);

  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  List<dynamic> transactions = [];
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _transactionTypeController = TextEditingController();
  String? _selectedTransactionId;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final response = await http.get(Uri.parse('http://your-api-url/transactions'));
    if (response.statusCode == 200) {
      setState(() {
        transactions = json.decode(response.body);
      });
    } else {
      // Handle error
      print('Failed to load transactions');
    }
  }

  Future<void> _createTransaction() async {
    final response = await http.post(
      Uri.parse('http://your-api-url/transactions'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': _userIdController.text,
        'amount': double.parse(_amountController.text),
        'transaction_type': _transactionTypeController.text,
        'status': 'completed', // Default status, modify as needed
      }),
    );

    if (response.statusCode == 201) {
      _fetchTransactions();
      _clearFields();
    } else {
      // Handle error
      print('Failed to create transaction');
    }
  }

  Future<void> _updateTransaction(String id) async {
    final response = await http.put(
      Uri.parse('http://your-api-url/transactions/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': _userIdController.text,
        'amount': double.parse(_amountController.text),
        'transaction_type': _transactionTypeController.text,
        'status': 'completed', // Modify as needed
      }),
    );

    if (response.statusCode == 200) {
      _fetchTransactions();
      _clearFields();
    } else {
      // Handle error
      print('Failed to update transaction');
    }
  }

  Future<void> _deleteTransaction(String id) async {
    final response = await http.delete(Uri.parse('http://your-api-url/transactions/$id'));
    if (response.statusCode == 200) {
      _fetchTransactions();
    } else {
      // Handle error
      print('Failed to delete transaction');
    }
  }

  void _clearFields() {
    _userIdController.clear();
    _amountController.clear();
    _transactionTypeController.clear();
    setState(() {
      _selectedTransactionId = null;
    });
  }

  void _showForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_selectedTransactionId == null ? 'Create Transaction' : 'Update Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _userIdController,
                decoration: const InputDecoration(labelText: 'User ID'),
              ),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _transactionTypeController,
                decoration: const InputDecoration(labelText: 'Transaction Type'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_selectedTransactionId == null) {
                  _createTransaction();
                } else {
                  _updateTransaction(_selectedTransactionId!);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _clearFields();
              _showForm(context);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text('Transaction ID: ${transaction['transaction_id']}'),
              subtitle: Text('Amount: \$${transaction['amount']} - Type: ${transaction['transaction_type']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      _userIdController.text = transaction['user_id'].toString();
                      _amountController.text = transaction['amount'].toString();
                      _transactionTypeController.text = transaction['transaction_type'];
                      setState(() {
                        _selectedTransactionId = transaction['transaction_id'].toString();
                      });
                      _showForm(context);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteTransaction(transaction['transaction_id'].toString()),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}