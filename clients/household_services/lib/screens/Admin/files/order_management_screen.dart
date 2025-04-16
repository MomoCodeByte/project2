import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({Key? key}) : super(key: key);

  @override
  _OrderManagementScreenState createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  List<dynamic> orders = [];
  final TextEditingController _customerIdController = TextEditingController();
  final TextEditingController _cropIdController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _totalPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    final response = await http.get(Uri.parse('http://your-api-url/orders'));
    if (response.statusCode == 200) {
      setState(() {
        orders = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load orders');
    }
  }

  Future<void> createOrder() async {
    final response = await http.post(
      Uri.parse('http://your-api-url/orders'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'customer_id': _customerIdController.text,
        'crop_id': _cropIdController.text,
        'quantity': int.parse(_quantityController.text),
        'total_price': double.parse(_totalPriceController.text),
      }),
    );
    
    if (response.statusCode == 201) {
      fetchOrders();
      _clearFields();
    } else {
      throw Exception('Failed to create order');
    }
  }

  Future<void> deleteOrder(String id) async {
    final response = await http.delete(Uri.parse('http://your-api-url/orders/$id'));
    if (response.statusCode == 200) {
      fetchOrders();
    } else {
      throw Exception('Failed to delete order');
    }
  }

  void _clearFields() {
    _customerIdController.clear();
    _cropIdController.clear();
    _quantityController.clear();
    _totalPriceController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Management')),
      body: Column(
        children: [
          _buildOrderForm(),
          Expanded(child: _buildOrderList()),
        ],
      ),
    );
  }

  Widget _buildOrderForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _customerIdController,
            decoration: const InputDecoration(labelText: 'Customer ID'),
          ),
          TextField(
            controller: _cropIdController,
            decoration: const InputDecoration(labelText: 'Crop ID'),
          ),
          TextField(
            controller: _quantityController,
            decoration: const InputDecoration(labelText: 'Quantity'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _totalPriceController,
            decoration: const InputDecoration(labelText: 'Total Price'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: createOrder,
            child: const Text('Create Order'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return ListTile(
          title: Text('Order ID: ${order['order_id']}'),
          subtitle: Text('Customer ID: ${order['customer_id']}, Crop ID: ${order['crop_id']}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => deleteOrder(order['order_id'].toString()),
          ),
        );
      },
    );
  }
}