import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class WorkerScreen extends StatefulWidget {
  const WorkerScreen({Key? key}) : super(key: key);

  @override
  _WorkerScreenState createState() => _WorkerScreenState();
}

class _WorkerScreenState extends State<WorkerScreen>
    with SingleTickerProviderStateMixin {
  // Main data lists
  List<Map<String, dynamic>> workers = [];
  List<Map<String, dynamic>> filteredWorkers = [];
  List<String> specialistOptions = [];

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();
  final TextEditingController _specialistController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _workHourController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // State variables
  String? _selectedWorkerId;
  bool _isLoading = false;
  bool _isGridView = false;
  String _sortBy = 'name';
  bool _sortAscending = true;
  String? _filterSpecialist;

  // Animation controller
  late AnimationController _animationController;

  // Storage for JWT token
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Theme colors
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color lightGreen = const Color(0xFF4CAF50);
  final Color paleGreen = const Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fetchWorkers();
    _searchController.addListener(_filterWorkers);
  }

  void _filterWorkers() {
    if (mounted) {
      setState(() {
        final query = _searchController.text.toLowerCase();
        filteredWorkers =
            workers.where((worker) {
              final matchesSearch =
                  worker['name'].toString().toLowerCase().contains(query) ||
                  worker['phone'].toString().toLowerCase().contains(query) ||
                  worker['age'].toString().toLowerCase().contains(query) ||
                  worker['description'].toString().toLowerCase().contains(
                    query,
                  );

              final matchesSpecialist =
                  _filterSpecialist == null ||
                  worker['specialist'] == _filterSpecialist;

              return matchesSearch && matchesSpecialist;
            }).toList();

        _sortWorkers();
      });
    }
  }

  void _sortWorkers() {
    filteredWorkers.sort((a, b) {
      final aValue = a[_sortBy].toString().toLowerCase();
      final bValue = b[_sortBy].toString().toLowerCase();
      return _sortAscending
          ? aValue.compareTo(bValue)
          : bValue.compareTo(aValue);
    });
  }

  void _changeSortField(String field) {
    setState(() {
      if (_sortBy == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = field;
        _sortAscending = true;
      }
      _sortWorkers();
    });
  }

  Future<void> _fetchWorkers() async {
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/workers'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        setState(() {
          workers =
              responseData.map((worker) {
                return {
                  'worker_id': worker['worker_id'],
                  'name': worker['name'],
                  'description': worker['description'],
                  'price': worker['price'],
                  'availability': worker['availability'],
                  'specialist': worker['specialist'],
                  'age': worker['age'],
                  'location': worker['location'],
                  'phone': worker['phone'],
                  'work_hour': worker['work_hour'],
                };
              }).toList();
          filteredWorkers = List.from(workers);

          // Extract unique specialists
          specialistOptions =
              workers.map((w) => w['specialist'].toString()).toSet().toList();
        });
      } else {
        _showError('Failed to load workers: ${response.body}');
      }
    } catch (e) {
      _showError('Network error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createWorker() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      final token = await _storage.read(key: 'jwt_token');

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/workers'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
          'availability':
              int.tryParse(_availabilityController.text.trim()) ?? 1,
          'specialist': _specialistController.text.trim(),
          'age': int.tryParse(_ageController.text.trim()) ?? 0,
          'location': _locationController.text.trim(),
          'phone': _phoneController.text.trim(),
          'work_hour': _workHourController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context);
        await _fetchWorkers();
        _clearFields();
        _showSuccess('Worker created successfully');
      } else {
        _showError('Failed to create worker: ${response.body}');
      }
    } catch (e) {
      _showError('Network error during worker creation: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateWorker(String workerId) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      final token = await _storage.read(key: 'jwt_token');

      final response = await http.put(
        Uri.parse('http://localhost:3000/api/workers/$workerId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
          'availability':
              int.tryParse(_availabilityController.text.trim()) ?? 1,
          'specialist': _specialistController.text.trim(),
          'age': int.tryParse(_ageController.text.trim()) ?? 0,
          'location': _locationController.text.trim(),
          'phone': _phoneController.text.trim(),
          'work_hour': _workHourController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        await _fetchWorkers();
        _clearFields();
        _showSuccess('Worker updated successfully');
      } else {
        _showError('Failed to update worker: ${response.body}');
      }
    } catch (e) {
      _showError('Network error during worker update: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteWorker(String workerId) async {
    try {
      setState(() => _isLoading = true);
      final token = await _storage.read(key: 'jwt_token');

      final response = await http.delete(
        Uri.parse('http://localhost:3000/api/workers/$workerId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await _fetchWorkers();
        _showSuccess('Worker deleted successfully');
      } else {
        _showError('Failed to delete worker: ${response.body}');
      }
    } catch (e) {
      _showError('Network error during worker deletion: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearFields() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _availabilityController.clear();
    _specialistController.clear();
    _ageController.clear();
    _locationController.clear();
    _phoneController.clear();
    _workHourController.clear();
    _selectedWorkerId = null;
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: lightGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        animation: CurvedAnimation(
          parent: _animationController,
          curve: Curves.elasticOut,
        ),
      ),
    );
    _animationController.forward(from: 0.0);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 5),
        animation: CurvedAnimation(
          parent: _animationController,
          curve: Curves.elasticOut,
        ),
      ),
    );
    _animationController.forward(from: 0.0);
  }

  void _showForm(BuildContext context, [Map<String, dynamic>? worker]) {
    if (worker != null) {
      _selectedWorkerId = worker['worker_id'].toString();
      _nameController.text = worker['name'].toString();
      _descriptionController.text = worker['description'].toString();
      _priceController.text = worker['price'].toString();
      _availabilityController.text = worker['availability'].toString();
      _specialistController.text = worker['specialist'].toString();
      _ageController.text = worker['age'].toString();
      _locationController.text = worker['location'].toString();
      _phoneController.text = worker['phone'].toString();
      _workHourController.text = worker['work_hour'].toString();
    } else {
      _clearFields();
    }

    showGeneralDialog(
      context: context,
      pageBuilder: (_, __, ___) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutBack,
        );

        return ScaleTransition(
          scale: curvedAnimation,
          child: FadeTransition(
            opacity: curvedAnimation,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    worker == null ? Icons.person_add : Icons.edit,
                    color: primaryGreen,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    worker == null ? 'Create Worker' : 'Edit Worker',
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAnimatedField(
                        controller: _nameController,
                        label: 'Name',
                        icon: Icons.person,
                      ),
                      _buildAnimatedField(
                        controller: _descriptionController,
                        label: 'Description',
                        icon: Icons.description,
                      ),
                      _buildAnimatedField(
                        controller: _priceController,
                        label: 'Price',
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                      ),
                      _buildAnimatedField(
                        controller: _availabilityController,
                        label: 'Availability',
                        icon: Icons.access_time,
                        keyboardType: TextInputType.number,
                      ),
                      _buildAnimatedField(
                        controller: _specialistController,
                        label: 'Specialist',
                        icon: Icons.work,
                      ),
                      _buildAnimatedField(
                        controller: _ageController,
                        label: 'Age',
                        icon: Icons.cake,
                        keyboardType: TextInputType.number,
                      ),
                      _buildAnimatedField(
                        controller: _locationController,
                        label: 'Location',
                        icon: Icons.location_on,
                      ),
                      _buildAnimatedField(
                        controller: _phoneController,
                        label: 'Phone',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildAnimatedField(
                        controller: _workHourController,
                        label: 'Work Hour',
                        icon: Icons.schedule,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                      onPressed: () {
                        if (_selectedWorkerId == null) {
                          _createWorker();
                        } else {
                          _updateWorker(_selectedWorkerId!);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lightGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        shadowColor: lightGreen.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        worker == null ? 'Create' : 'Update',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .scale(delay: 100.ms, duration: 300.ms),
              ],
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  Widget _buildAnimatedField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 20,
          ),
          labelText: label,
          labelStyle: TextStyle(color: primaryGreen),
          prefixIcon: Icon(icon, color: primaryGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: lightGreen, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator:
            (value) =>
                value == null || value.trim().isEmpty
                    ? '$label is required'
                    : null,
      ),
    );
  }

  Future<void> _showDeleteConfirmation(Map<String, dynamic> worker) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titlePadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            actionsPadding: const EdgeInsets.only(right: 16, bottom: 12),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Delete Worker',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to delete "${worker['name']}"?',
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteWorker(worker['worker_id'].toString());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Delete', style: TextStyle(fontSize: 15)),
              ),
            ],
          ),
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> worker) {
    final name = worker['name'].toString();
    final phone = worker['phone'].toString();
    final age = worker['age'].toString();
    final specialist = worker['specialist'].toString();
    final workHour = worker['work_hour'].toString();
    final location = worker['location'].toString();
    final price = worker['price'].toString();
    final color = worker['color'] ?? Colors.teal;

    return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          margin: const EdgeInsets.all(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () => _showForm(context, worker),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: paleGreen,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Center(
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: color,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Age: $age',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Specialist: $specialist',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Work Hour: $workHour',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Location: $location',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Price: \$$price',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: lightGreen),
                            onPressed: () => _showForm(context, worker),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteConfirmation(worker),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad);
  }

  Widget _buildWorkerListItem(Map<String, dynamic> worker) {
    final name = worker['name'].toString();
    final phone = worker['phone'].toString();
    final specialist = worker['specialist'].toString();
    final age = worker['age'].toString();
    final location = worker['location'].toString();
    final price = worker['price'].toString();
    final workHour = worker['work_hour'].toString();
    final color = worker['color'] ?? Colors.green;

    return Slidable(
          key: ValueKey(worker['worker_id']),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                onPressed: (_) => _showForm(context, worker),
                backgroundColor: lightGreen,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                label: 'Edit',
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              SlidableAction(
                onPressed: (_) => _showDeleteConfirmation(worker),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete',
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
            ],
          ),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: color,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          phone,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.work, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          specialist,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '\$$price',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          workHour,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$age years',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  specialist,
                  style: TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              onTap: () => _showForm(context, worker),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Workers...',
              prefixIcon: Icon(Icons.search, color: primaryGreen),
              filled: true,
              fillColor: paleGreen,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: Row(
                    children: [
                      Icon(
                        _isGridView ? Icons.grid_view : Icons.list,
                        size: 16,
                        color: primaryGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(_isGridView ? 'Grid View' : 'List View'),
                    ],
                  ),
                  selected: true,
                  selectedColor: paleGreen,
                  checkmarkColor: primaryGreen,
                  onSelected: (_) {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(_filterSpecialist ?? 'All Specialists'),
                  selected: _filterSpecialist != null,
                  selectedColor: paleGreen,
                  onSelected: (_) {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text(
                              'Filter by Specialist',
                              style: TextStyle(color: primaryGreen),
                            ),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView(
                                shrinkWrap: true,
                                children: [
                                  ListTile(
                                    title: const Text('All Specialists'),
                                    leading:
                                        _filterSpecialist == null
                                            ? Icon(
                                              Icons.check_circle,
                                              color: primaryGreen,
                                            )
                                            : const Icon(Icons.circle_outlined),
                                    onTap: () {
                                      setState(() {
                                        _filterSpecialist = null;
                                      });
                                      Navigator.pop(context);
                                      _filterWorkers();
                                    },
                                  ),
                                  ...specialistOptions.map(
                                    (specialist) => ListTile(
                                      title: Text(specialist),
                                      leading:
                                          _filterSpecialist == specialist
                                              ? Icon(
                                                Icons.check_circle,
                                                color: primaryGreen,
                                              )
                                              : const Icon(
                                                Icons.circle_outlined,
                                              ),
                                      onTap: () {
                                        setState(() {
                                          _filterSpecialist = specialist;
                                        });
                                        Navigator.pop(context);
                                        _filterWorkers();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Row(
                    children: [
                      const Text('Sort'),
                      const SizedBox(width: 4),
                      Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 16,
                        color: primaryGreen,
                      ),
                    ],
                  ),
                  selected: true,
                  selectedColor: paleGreen,
                  onSelected: (_) {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text(
                              'Sort Workers',
                              style: TextStyle(color: primaryGreen),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text('By Name'),
                                  leading: Radio<String>(
                                    value: 'name',
                                    groupValue: _sortBy,
                                    onChanged: (value) {
                                      setState(() {
                                        _sortBy = value!;
                                      });
                                      _sortWorkers();
                                      Navigator.pop(context);
                                    },
                                    activeColor: primaryGreen,
                                  ),
                                ),
                                ListTile(
                                  title: const Text('By Price'),
                                  leading: Radio<String>(
                                    value: 'price',
                                    groupValue: _sortBy,
                                    onChanged: (value) {
                                      setState(() {
                                        _sortBy = value!;
                                      });
                                      _sortWorkers();
                                      Navigator.pop(context);
                                    },
                                    activeColor: primaryGreen,
                                  ),
                                ),
                                ListTile(
                                  title: const Text('By Specialist'),
                                  leading: Radio<String>(
                                    value: 'specialist',
                                    groupValue: _sortBy,
                                    onChanged: (value) {
                                      setState(() {
                                        _sortBy = value!;
                                      });
                                      _sortWorkers();
                                      Navigator.pop(context);
                                    },
                                    activeColor: primaryGreen,
                                  ),
                                ),
                                const Divider(),
                                ListTile(
                                  title: Text(
                                    _sortAscending
                                        ? 'Ascending Order'
                                        : 'Descending Order',
                                  ),
                                  trailing: Switch(
                                    value: _sortAscending,
                                    onChanged: (value) {
                                      setState(() {
                                        _sortAscending = value;
                                      });
                                      _sortWorkers();
                                    },
                                    activeColor: primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Reset Filters'),
                  avatar: const Icon(Icons.refresh, size: 16),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _filterSpecialist = null;
                      _sortBy = 'name';
                      _sortAscending = true;
                      filteredWorkers = List.from(workers);
                    });
                    _sortWorkers();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildWorkerStats() {
    final totalWorkers = workers.length;
    final Map<String, int> specialistCounts = {};

    for (final w in workers) {
      final specialist = w['specialist'].toString();
      specialistCounts[specialist] = (specialistCounts[specialist] ?? 0) + 1;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workers Statistics',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Total Workers: $totalWorkers',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...specialistCounts.entries.map((entry) {
              final percent =
                  totalWorkers > 0
                      ? (entry.value / totalWorkers * 100).toStringAsFixed(1)
                      : '0';

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key}: ${entry.value} ($percent%)',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: totalWorkers > 0 ? entry.value / totalWorkers : 0,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.supervisor_account, color: primaryGreen),
            const SizedBox(width: 8),
            const Text(
              'Worker Management',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: primaryGreen),
            onPressed: _fetchWorkers,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(Icons.logout, color: primaryGreen),
            onPressed: () async {
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
                            backgroundColor: primaryGreen,
                          ),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
              );

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Add Worker',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 4,
      ).animate().scale(curve: Curves.elasticOut, duration: 500.ms),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(lightGreen),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading Workers...',
                      style: TextStyle(color: primaryGreen),
                    ),
                  ],
                ),
              )
              : Container(
                color: paleGreen.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilterBar(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(flex: 1, child: _buildWorkerStats()),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Found ${filteredWorkers.length} Workers',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (filteredWorkers.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          _searchController.text.isNotEmpty ||
                                                  _filterSpecialist != null
                                              ? 'No Workers match your search criteria'
                                              : 'No Workers available',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    if (_searchController.text.isNotEmpty ||
                                        _filterSpecialist != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          'Filtered by: ' +
                                              (_searchController.text.isNotEmpty
                                                  ? 'Search '
                                                  : '') +
                                              (_filterSpecialist != null
                                                  ? 'Specialist ($_filterSpecialist)'
                                                  : ''),
                                          style: TextStyle(
                                            color: primaryGreen,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child:
                            filteredWorkers.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_search,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No Workers found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (_searchController.text.isNotEmpty ||
                                          _filterSpecialist != null)
                                        TextButton.icon(
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Clear filters'),
                                          onPressed: () {
                                            setState(() {
                                              _searchController.clear();
                                              _filterSpecialist = null;
                                              filteredWorkers = List.from(
                                                workers,
                                              );
                                            });
                                            _sortWorkers();
                                          },
                                        ),
                                    ],
                                  ),
                                )
                                : _isGridView
                                ? GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        childAspectRatio: 0.8,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                      ),
                                  itemCount: filteredWorkers.length,
                                  itemBuilder: (context, index) {
                                    return _buildWorkerCard(
                                      filteredWorkers[index],
                                    );
                                  },
                                )
                                : ListView.builder(
                                  itemCount: filteredWorkers.length,
                                  itemBuilder: (context, index) {
                                    return _buildWorkerListItem(
                                      filteredWorkers[index],
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _availabilityController.dispose();
    _specialistController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _workHourController.dispose();
    _searchController.dispose();
    _searchController.removeListener(_filterWorkers);
    _animationController.dispose();
    super.dispose();
  }
}
