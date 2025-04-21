import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Order {
  final int orderId;
  final int? customerId;
  final int? cropId;
  final int quantity;
  final double totalPrice;
  final String? orderStatus;
  final DateTime createdAt;
  final bool isDeleted;

  Order({
    required this.orderId,
    this.customerId,
    this.cropId,
    required this.quantity,
    required this.totalPrice,
    this.orderStatus,
    required this.createdAt,
    required this.isDeleted,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['order_id'] ?? 0,
      customerId: json['customer_id'],
      cropId: json['crop_id'],
      quantity: json['quantity'] ?? 0,
      totalPrice:
          double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      orderStatus: json['order_status'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      isDeleted: json['is_deleted'] == 1,
    );
  }
}

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  _OrderManagementScreenState createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen>
    with TickerProviderStateMixin {
  List<Order> orders = [];
  List<Order> filteredOrders = [];
  bool isLoading = false;
  String errorMessage = '';
  String selectedStatus = 'pending';
  String searchQuery = '';
  late AnimationController _refreshAnimationController;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final Map<String, Color> statusColors = {
    'pending': Colors.orange,
    'processed': Colors.blue,
    'shipped': Colors.purple,
    'delivered': Colors.green,
    'cancelled': Colors.red,
    'unknown': Colors.grey, // Handle unknown status
  };

  final TextEditingController _customerIdController = TextEditingController();
  final TextEditingController _cropIdController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _totalPriceController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    fetchOrders();
  }

  @override
  void dispose() {
    _customerIdController.dispose();
    _cropIdController.dispose();
    _quantityController.dispose();
    _totalPriceController.dispose();
    _searchController.dispose();
    _refreshAnimationController.dispose();
    super.dispose();
  }

  Future<void> fetchOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/orders'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          orders = data.map((order) => Order.fromJson(order)).toList();
          filterOrders();
        });
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading orders: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterOrders() {
    setState(() {
      if (searchQuery.isEmpty) {
        filteredOrders = orders.where((order) => !order.isDeleted).toList();
      } else {
        filteredOrders =
            orders
                .where(
                  (order) =>
                      !order.isDeleted &&
                      (order.orderId.toString().contains(searchQuery) ||
                          (order.customerId?.toString() ?? '').contains(
                            searchQuery,
                          ) ||
                          (order.cropId?.toString() ?? '').contains(
                            searchQuery,
                          )),
                )
                .toList();
      }
    });
  }

  Future<void> createOrder() async {
    if (_customerIdController.text.isEmpty ||
        _cropIdController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _totalPriceController.text.isEmpty) {
      setState(() {
        errorMessage = 'Please fill all fields';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customer_id': int.parse(_customerIdController.text),
          'crop_id': int.parse(_cropIdController.text),
          'quantity': int.parse(_quantityController.text),
          'total_price': double.parse(_totalPriceController.text),
          'order_status': selectedStatus,
        }),
      );

      if (response.statusCode == 201) {
        await fetchOrders();
        _clearFields();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order created successfully'),
            backgroundColor: Colors.teal,
          ),
        );
      } else {
        throw Exception('Failed to create order: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error creating order: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateOrderStatus(int orderId, String newStatus) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.put(
        Uri.parse('http://localhost:3000/api/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'order_status': newStatus}),
      );

      if (response.statusCode == 200) {
        await fetchOrders();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to $newStatus'),
            backgroundColor: Colors.teal,
          ),
        );
      } else {
        throw Exception(
          'Failed to update order status: ${response.statusCode}',
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error updating status: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteOrder(int orderId) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.put(
        Uri.parse('http://localhost:3000/api/orders/$orderId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'is_delete': 1}),
      );

      if (response.statusCode == 200) {
        await fetchOrders();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order deleted successfully'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        throw Exception('Failed to delete order: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error deleting order: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _clearFields() {
    _customerIdController.clear();
    _cropIdController.clear();
    _quantityController.clear();
    _totalPriceController.clear();
    setState(() {
      selectedStatus = 'pending';
    });
  }

  void _showStatusDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) {
        String newStatus = order.orderStatus ?? 'pending';

        return AlertDialog(
          title: const Text(
            'Update Order Status',
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final status in [
                'pending',
                'processed',
                'shipped',
                'delivered',
                'cancelled',
              ])
                RadioListTile<String>(
                  title: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColors[status],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  value: status,
                  groupValue: newStatus,
                  onChanged: (value) {
                    if (value != null) {
                      newStatus = value;
                      Navigator.pop(context);
                      updateOrderStatus(order.orderId, newStatus);
                    }
                  },
                ).animate().fadeIn(
                  delay:
                      100.ms *
                      [
                        'pending',
                        'processed',
                        'shipped',
                        'delivered',
                        'cancelled',
                      ].indexOf(status),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showAddOrderDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Create New Order',
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _customerIdController,
                  decoration: const InputDecoration(labelText: 'Customer ID'),
                  keyboardType: TextInputType.number,
                ).animate().fadeIn(delay: 100.ms),
                TextField(
                  controller: _cropIdController,
                  decoration: const InputDecoration(labelText: 'Crop ID'),
                  keyboardType: TextInputType.number,
                ).animate().fadeIn(delay: 200.ms),
                TextField(
                  controller: _quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ).animate().fadeIn(delay: 300.ms),
                TextField(
                  controller: _totalPriceController,
                  decoration: const InputDecoration(labelText: 'Total Price'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  items:
                      [
                            'pending',
                            'processed',
                            'shipped',
                            'delivered',
                            'cancelled',
                          ]
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(color: statusColors[status]),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedStatus = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Status'),
                ).animate().fadeIn(delay: 500.ms),
                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ).animate().fadeIn(delay: 600.ms).shake(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: createOrder,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text(
                'Create',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            errorMessage,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ).animate().fadeIn().shake(),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: AnimatedBuilder(
              animation: _refreshAnimationController,
              builder: (_, child) {
                return Transform.rotate(
                  angle: _refreshAnimationController.value * 2 * 3.14,
                  child: const Icon(Icons.refresh),
                );
              },
            ),
            label: const Text('Try Again'),
            onPressed: () {
              _refreshAnimationController.reset();
              _refreshAnimationController.forward();
              fetchOrders();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ).animate().fadeIn(delay: 300.ms).scale(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '\Tsh: ');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shopping_bag, color: Colors.teal),
            const SizedBox(width: 8),
            const Text(
              'Order Management',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Refresh button
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.teal),
            onPressed: fetchOrders,
            tooltip: 'Refresh',
          ).animate().fadeIn(),
          // Logout button
          IconButton(
            icon: Icon(Icons.logout, color: Colors.teal),
            onPressed: () async {
              // Show logout confirmation
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                          ),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
              );

              // Process logout if confirmed
              if (confirm == true) {
                await _storage.delete(key: 'jwt_token');
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),

      //body start here
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search Orders...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                          filterOrders();
                        });
                      },
                    ),
                  ),
                ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Sort ↑',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Reset Filters'),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      searchQuery = '';
                      filterOrders();
                    });
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),
              ],
            ),
          ),

          // Statistics bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Orders Statistics',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Total Orders: ${filteredOrders.length}'),
                  ],
                ),
                const Spacer(),
                Text(
                  'Found ${filteredOrders.length} Orders',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.2, end: 0),

          // Orders list or error message
          Expanded(
            child:
                isLoading
                    ? Center(
                      child:
                          CircularProgressIndicator(
                            color: Colors.teal,
                          ).animate().fadeIn().scale(),
                    )
                    : errorMessage.isNotEmpty
                    ? _buildErrorView()
                    : filteredOrders.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ).animate().fadeIn().scale(),
                          const SizedBox(height: 16),
                          Text(
                            'No orders found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ).animate().fadeIn(delay: 200.ms),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];

                        return Slidable(
                          key: ValueKey(order.orderId),
                          endActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (_) => _showStatusDialog(order),
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                icon: Icons.edit,
                                label: 'Status',
                              ),
                              SlidableAction(
                                onPressed: (_) => deleteOrder(order.orderId),
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: 'Delete',
                              ),
                            ],
                          ),
                          child: Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.teal.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '#${order.orderId}',
                                                style: const TextStyle(
                                                  color: Colors.teal,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Customer ID: ${order.customerId ?? 'N/A'}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            statusColors[order
                                                                    .orderStatus]
                                                                ?.withOpacity(
                                                                  0.1,
                                                                ) ??
                                                            Colors.grey
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        (order.orderStatus ??
                                                                'Unknown')
                                                            .toUpperCase(),
                                                        style: TextStyle(
                                                          color:
                                                              statusColors[order
                                                                  .orderStatus] ??
                                                              Colors.grey,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Crop ID: ${order.cropId ?? 'N/A'}',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  'Date: ${DateFormat('MMM dd, yyyy - HH:mm').format(order.createdAt)}',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Quantity',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                '${order.quantity} units',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              const Text(
                                                'Total Price',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                formatter.format(
                                                  order.totalPrice,
                                                ),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.teal,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            icon: const Icon(Icons.edit),
                                            label: const Text('Update Status'),
                                            onPressed:
                                                () => _showStatusDialog(order),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.teal,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton.icon(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                            label: const Text('Delete'),
                                            onPressed:
                                                () =>
                                                    deleteOrder(order.orderId),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .animate()
                              .fadeIn(
                                delay: Duration(
                                  milliseconds: (100 * index) % 500,
                                ),
                              )
                              .slideY(
                                begin: 0.1,
                                end: 0,
                                delay: Duration(
                                  milliseconds: (100 * index) % 500,
                                ),
                              ),
                        );
                      },
                    ),
          ),
        ],
      ),
      // float action button to add order
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOrderDialog,
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.assignment, color: Colors.white),
        label: const Text(
          'Create Order',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 4,
      ).animate().scale(curve: Curves.elasticOut, duration: 500.ms),
    );
  }
}
