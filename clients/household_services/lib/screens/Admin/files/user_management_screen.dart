import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> users = [];  // Explicitly typed as Map
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedRole = 'farmer';
  String? _selectedUserId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://your-api-url/users'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        setState(() {
          // Convert each item to Map<String, dynamic> and ensure non-null values
          users = responseData.map((user) => {
            'user_id': user['user_id']?.toString() ?? '',
            'username': user['username']?.toString() ?? '',
            'email': user['email']?.toString() ?? '',
            'phone': user['phone']?.toString() ?? '',
            'role': user['role']?.toString() ?? 'farmer',
          }).toList();
          _isLoading = false;
        });
      } else {
        _showError('Failed to load users');
      }
    } catch (e) {
      _showError('Network error: ${e.toString()}');
    }
    setState(() => _isLoading = false);
  }

  Future<String> _getToken() async {
    // In a real app, get this from secure storage
    return 'your-auth-token';
  }

  void _showError(String message) {
    if (!mounted) return;  // Check if widget is mounted before showing SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final response = await http.post(
        Uri.parse('http://your-api-url/users'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
          'role': _selectedRole,
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;  // Check if widget is mounted
        Navigator.pop(context);
        _fetchUsers();
        _clearFields();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User created successfully'),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _showError('Failed to create user');
      }
    } catch (e) {
      _showError('Network error: ${e.toString()}');
    }
  }

  Future<void> _updateUser(String id) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final Map<String, dynamic> updateData = {
        'username': _usernameController.text.trim(),
        'role': _selectedRole,
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      // Only include password if it's not empty
      if (_passwordController.text.isNotEmpty) {
        updateData['password'] = _passwordController.text;
      }

      final response = await http.put(
        Uri.parse('http://your-api-url/users/$id'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json'
        },
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;  // Check if widget is mounted
        Navigator.pop(context);
        _fetchUsers();
        _clearFields();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User updated successfully'),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _showError('Failed to update user');
      }
    } catch (e) {
      _showError('Network error: ${e.toString()}');
    }
  }

  Future<void> _deleteUser(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://your-api-url/users/$id'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
        },
      );

      if (response.statusCode == 200) {
        _fetchUsers();
        if (!mounted) return;  // Check if widget is mounted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User deleted successfully'),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _showError('Failed to delete user');
      }
    } catch (e) {
      _showError('Network error: ${e.toString()}');
    }
  }

  void _clearFields() {
    _usernameController.clear();
    _passwordController.clear();
    _emailController.clear();
    _phoneController.clear();
    _selectedRole = 'farmer';
    setState(() {
      _selectedUserId = null;
    });
  }

  void _showForm(BuildContext context, [Map<String, dynamic>? user]) {
    if (user != null) {
      _selectedUserId = user['user_id']?.toString() ?? '';
      _usernameController.text = user['username']?.toString() ?? '';
      _emailController.text = user['email']?.toString() ?? '';
      _phoneController.text = user['phone']?.toString() ?? '';
      _selectedRole = user['role']?.toString() ?? 'farmer';
      _passwordController.clear();
    } else {
      _clearFields();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            user == null ? 'Create User' : 'Edit User',
            style: const TextStyle(color: Color(0xFF2E7D32)),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                      ),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Username is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: user == null ? 'Password' : 'New Password (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                      ),
                    ),
                    obscureText: true,
                    validator: (value) => user == null && (value?.isEmpty ?? true)
                        ? 'Password is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                      ),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Email is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                      ),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Phone is required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'farmer', child: Text('farmer')),
                    ],
                    onChanged: (value) {
                      if (value != null) {  // Add null check
                        setState(() {
                          _selectedRole = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_selectedUserId == null) {
                  _createUser();
                } else {
                  _updateUser(_selectedUserId!);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(user == null ? 'Create' : 'Update'),
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
        title: const Text(
          'User Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Handle logout
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  user['username']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (user['role']?.toString() ?? '') == 'admin'
                                      ? const Color(0xFFE8F5E9)
                                      : const Color(0xFFF1F8E9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  user['role']?.toString() ?? 'farmer',
                                  style: TextStyle(
                                    color: (user['role']?.toString() ?? '') == 'admin'
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFF558B2F),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '📧 ${user['email']?.toString() ?? ''}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Text(
                            '📱 ${user['phone']?.toString() ?? ''}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Color(0xFF4CAF50)),
                                onPressed: () => _showForm(context, user),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteUser(user['user_id']?.toString() ?? ''),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}