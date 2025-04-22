import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:animate_do/animate_do.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class Crop {
  final int? id;
  final int? farmerId;
  final String name;
  final String description;
  final double price;
  final int availability;
  final String? imagePath;
  final String category;

  Crop({
    this.id,
    this.farmerId,
    required this.name,
    required this.description,
    required this.price,
    required this.availability,
    this.imagePath,
    required this.category,
  });

 

  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop(
      id: json['crop_id'],
      farmerId: json['farmer_id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      availability: json['availability'],
      imagePath: json['image_path'],
      category: json['category'] ?? 'Other',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farmer_id': farmerId,
      'name': name,
      'description': description,
      'price': price,
      'availability': availability,
      'category': category,
    };
  }
}

class CropManagementScreen extends StatefulWidget {
  const CropManagementScreen({Key? key}) : super(key: key);

  @override
  _CropManagementScreenState createState() => _CropManagementScreenState();
}

class _CropManagementScreenState extends State<CropManagementScreen>
    with TickerProviderStateMixin {
  List<Crop> _crops = [];
  List<Crop> _filteredCrops = [];
  bool _isLoading = true;
  final String _baseUrl = 'http://localhost:3000/api';
  final ImagePicker _picker = ImagePicker();
  final currencyFormat = NumberFormat("#,##0.00", "en_US");
  late AnimationController _fabAnimationController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All Crops';
  String _sortBy = 'Name (A-Z)';

  @override
  void initState() {
    super.initState();
    _fetchCrops();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _searchController.addListener(_filterCrops);
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterCrops() {
    final searchTerm = _searchController.text.toLowerCase();
    setState(() {
      _filteredCrops =
          _crops.where((crop) {
            final matchesSearch =
                crop.name.toLowerCase().contains(searchTerm) ||
                crop.description.toLowerCase().contains(searchTerm) ||
                crop.category.toLowerCase().contains(searchTerm);
            final matchesCategory =
                _selectedCategory == 'All Crops' ||
                crop.category == _selectedCategory;
            return matchesSearch && matchesCategory;
          }).toList();

      _applySorting();
    });
  }

  void _applySorting() {
    switch (_sortBy) {
      case 'Name (A-Z)':
        _filteredCrops.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Name (Z-A)':
        _filteredCrops.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'Price (Low-High)':
        _filteredCrops.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price (High-Low)':
        _filteredCrops.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Availability':
        _filteredCrops.sort((a, b) => b.availability.compareTo(a.availability));
        break;
    }
  }

  void _resetFilters() {
    _searchController.clear();
    _selectedCategory = 'All Crops';
    _sortBy = 'Name (A-Z)';
    _filterCrops();
  }

  Future<void> _fetchCrops() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('$_baseUrl/crops'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _crops = data.map((crop) => Crop.fromJson(crop)).toList();
          _filteredCrops = List.from(_crops);
          _applySorting();
        });
      } else {
        _showSnackBar('Failed to load crops: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, int> _getCropStatistics() {
    Map<String, int> stats = {};
    for (var crop in _crops) {
      stats.update(crop.category, (value) => value + 1, ifAbsent: () => 1);
    }
    return stats;
  }

  Widget _buildStatistics() {
    final stats = _getCropStatistics();
    final total = _crops.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total product: $total',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...stats.entries.map((entry) {
            final percentage = (entry.value / total * 100).toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text(entry.key)),
                  Expanded(
                    flex: 3,
                    child: LinearProgressIndicator(
                      value: entry.value / total,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.teal.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$entry.value ($percentage%)'),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFilterControls() {
    final categories = ['All Crops', ..._getCropStatistics().keys.toList()];
    final sortOptions = [
      'Name (A-Z)',
      'Name (Z-A)',
      'Price (Low-High)',
      'Price (High-Low)',
      'Availability',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter & Sort',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items:
                      categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                      _filterCrops();
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  isExpanded: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  items:
                      sortOptions.map((option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                      _applySorting();
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Sort By',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  isExpanded: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.filter_alt_outlined, size: 18),
                  label: const Text('Apply Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _filterCrops,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: const Text('Reset'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.grey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _resetFilters,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCropCard(Crop crop, int index) {
    return FadeInUp(
      duration: Duration(milliseconds: 300 + (index * 100)),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showCropDialog(crop: crop),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image section
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      child:
                          crop.imagePath != null
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  '$_baseUrl/${crop.imagePath}',
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          _buildPlaceholderImage(),
                                ),
                              )
                              : _buildPlaceholderImage(),
                    ),
                    const SizedBox(width: 16),
                    // Details section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  crop.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      crop.availability > 0
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  crop.availability > 0 ? 'In Stock' : 'Out',
                                  style: TextStyle(
                                    color:
                                        crop.availability > 0
                                            ? Colors.green[800]
                                            : Colors.red[800],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            crop.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            crop.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey[300], height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Tsh ${currencyFormat.format(crop.price)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Available: ${crop.availability}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      color: Colors.teal,
                      onPressed: () => _showCropDialog(crop: crop),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      color: Colors.red[400],
                      onPressed: () => _confirmDeleteCrop(crop),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteCrop(Crop crop) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Crop'),
            content: Text('Are you sure you want to delete ${crop.name}?'),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _deleteCrop(crop.id!);
                },
              ),
            ],
          ),
    );
  }

  Future<void> _deleteCrop(int id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/crops/$id'));
      if (response.statusCode == 200) {
        setState(() {
          _crops.removeWhere((crop) => crop.id == id);
          _filterCrops();
        });
        _showSnackBar('Crop deleted successfully');
      } else {
        _showSnackBar('Failed to delete crop: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<File?> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } on Exception catch (e) {
      _showSnackBar("Error accessing media: ${e.toString()}");
      return null;
    }
  }

  Future<void> _showCropDialog({Crop? crop}) async {
    final TextEditingController nameController = TextEditingController(
      text: crop?.name ?? '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: crop?.description ?? '',
    );
    final TextEditingController priceController = TextEditingController(
      text: crop?.price.toString() ?? '',
    );
    final TextEditingController availabilityController = TextEditingController(
      text: crop?.availability.toString() ?? '',
    );
    final TextEditingController farmerIdController = TextEditingController(
      text: crop?.farmerId?.toString() ?? '1',
    );
    final TextEditingController categoryController = TextEditingController(
      text: crop?.category ?? 'Vegetables',
    );

    File? imageFile;

    await showDialog(
      context: context,
      builder:
          (context) => FadeInUp(
            duration: const Duration(milliseconds: 300),
            child: StatefulBuilder(
              builder:
                  (context, setDialogState) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text(
                      crop == null ? 'Add New Crop' : 'Edit Crop',
                      style: const TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: 'Name',
                              labelStyle: TextStyle(
                                color: Colors.teal.shade300,
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.teal.shade400,
                                ),
                              ),
                            ),
                          ),
                          TextField(
                            controller: descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              labelStyle: TextStyle(
                                color: Colors.teal.shade300,
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.teal.shade400,
                                ),
                              ),
                            ),
                            maxLines: 3,
                          ),
                          TextField(
                            controller: priceController,
                            decoration: InputDecoration(
                              labelText: 'Price',
                              labelStyle: TextStyle(
                                color: Colors.teal.shade300,
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.teal.shade400,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          TextField(
                            controller: availabilityController,
                            decoration: InputDecoration(
                              labelText: 'Availability',
                              labelStyle: TextStyle(
                                color: Colors.teal.shade300,
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.teal.shade400,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          TextField(
                            controller: farmerIdController,
                            decoration: InputDecoration(
                              labelText: 'Farmer ID',
                              labelStyle: TextStyle(
                                color: Colors.teal.shade300,
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.teal.shade400,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          TextField(
                            controller: categoryController,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              labelStyle: TextStyle(
                                color: Colors.teal.shade300,
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.teal.shade400,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (imageFile != null)
                            Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                image: DecorationImage(
                                  image: FileImage(imageFile!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ).animate().fadeIn(duration: 300.ms).scale(),
                          if (crop?.imagePath != null && imageFile == null)
                            Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                image: DecorationImage(
                                  image: NetworkImage(
                                    '$_baseUrl/${crop!.imagePath}',
                                  ),
                                  fit: BoxFit.cover,
                                  onError: (object, stackTrace) {},
                                ),
                              ),
                            ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.photo_library, size: 18),
                                label: const Text('Gallery'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade400,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 10,
                                  ),
                                ),
                                onPressed: () async {
                                  final File? selectedImage = await _pickImage(
                                    ImageSource.gallery,
                                  );
                                  if (selectedImage != null) {
                                    setDialogState(() {
                                      imageFile = selectedImage;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.camera_alt, size: 18),
                                label: const Text('Camera'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey.shade400,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 10,
                                  ),
                                ),
                                onPressed: () async {
                                  final File? capturedImage = await _pickImage(
                                    ImageSource.camera,
                                  );
                                  if (capturedImage != null) {
                                    setDialogState(() {
                                      imageFile = capturedImage;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        child: Text(crop == null ? 'Add' : 'Update'),
                        onPressed: () async {
                          Navigator.pop(context);

                          try {
                            final newCrop = Crop(
                              id: crop?.id,
                              farmerId:
                                  int.tryParse(farmerIdController.text) ?? 1,
                              name: nameController.text,
                              description: descriptionController.text,
                              price:
                                  double.tryParse(priceController.text) ?? 0.0,
                              availability:
                                  int.tryParse(availabilityController.text) ??
                                  0,
                              category: categoryController.text,
                            );

                            if (crop == null) {
                              await _addCrop(newCrop, imageFile);
                            } else {
                              await _updateCrop(newCrop, imageFile);
                            }
                          } catch (e) {
                            _showSnackBar('Error: ${e.toString()}');
                          }
                        },
                      ),
                    ],
                  ),
            ),
          ),
    );
  }

  Future<void> _addCrop(Crop crop, File? imageFile) async {
    try {
      if (imageFile == null) {
        final response = await http.post(
          Uri.parse('$_baseUrl/crops'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(crop.toJson()),
        );

        if (response.statusCode == 201) {
          _showSnackBar('Crop added successfully');
          _fetchCrops();
        } else {
          _showSnackBar('Failed to add crop: ${response.statusCode}');
        }
      } else {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl/crops'),
        );

        request.fields['name'] = crop.name;
        request.fields['description'] = crop.description;
        request.fields['price'] = crop.price.toString();
        request.fields['availability'] = crop.availability.toString();
        request.fields['farmer_id'] = crop.farmerId.toString();
        request.fields['category'] = crop.category;

        final fileStream = http.ByteStream(imageFile.openRead());
        final fileLength = await imageFile.length();

        final multipartFile = http.MultipartFile(
          'image',
          fileStream,
          fileLength,
          filename: path.basename(imageFile.path),
        );

        request.files.add(multipartFile);

        try {
          final streamedResponse = await request.send();
          final response = await http.Response.fromStream(streamedResponse);

          if (response.statusCode == 201) {
            _showSnackBar('Crop added successfully with image');
            _fetchCrops();
          } else {
            _showSnackBar(
              'Failed to add crop: ${response.statusCode} - ${response.body}',
            );
          }
        } catch (e) {
          _showSnackBar('Network error during upload: $e');
        }
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    }
  }

  Future<void> _updateCrop(Crop crop, File? imageFile) async {
    try {
      if (imageFile == null) {
        final response = await http.put(
          Uri.parse('$_baseUrl/crops/${crop.id}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(crop.toJson()),
        );

        if (response.statusCode == 200) {
          _showSnackBar('Crop updated successfully');
          _fetchCrops();
        } else {
          _showSnackBar('Failed to update crop: ${response.statusCode}');
        }
      } else {
        var request = http.MultipartRequest(
          'PUT',
          Uri.parse('$_baseUrl/crops/${crop.id}'),
        );

        request.fields['name'] = crop.name;
        request.fields['description'] = crop.description;
        request.fields['price'] = crop.price.toString();
        request.fields['availability'] = crop.availability.toString();
        request.fields['farmer_id'] = crop.farmerId.toString();
        request.fields['category'] = crop.category;

        final fileStream = http.ByteStream(imageFile.openRead());
        final fileLength = await imageFile.length();

        final multipartFile = http.MultipartFile(
          'image',
          fileStream,
          fileLength,
          filename: path.basename(imageFile.path),
        );

        request.files.add(multipartFile);

        try {
          final streamedResponse = await request.send();
          final response = await http.Response.fromStream(streamedResponse);

          if (response.statusCode == 200) {
            _showSnackBar('Crop updated successfully with image');
            _fetchCrops();
          } else {
            _showSnackBar(
              'Failed to update crop: ${response.statusCode} - ${response.body}',
            );
          }
        } catch (e) {
          _showSnackBar('Network error during upload: $e');
        }
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    }
  }

  Widget _buildPlaceholderImage() {
    return Center(
      child: Icon(Icons.eco_outlined, size: 30, color: Colors.grey[400]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.production_quantity_limits, color: Colors.teal),
            const SizedBox(width: 8),
            const Text(
              'Product Management',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchCrops,
                tooltip: 'Refresh',
              )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 1000.ms, begin: 0, end: 1)
              .then(),
        ],
      ),

      //  float Action button for add products
      floatingActionButton:
          FloatingActionButton.extended(
            onPressed: () {
              _fabAnimationController.reset();
              _fabAnimationController.forward();
              _showCropDialog();
            },
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: RotationTransition(
              turns: Tween(begin: 0.0, end: 0.5).animate(
                CurvedAnimation(
                  parent: _fabAnimationController,
                  curve: Curves.elasticOut,
                ),
              ),
              child: const Icon(Icons.inventory, color: Colors.white),
            ),
            label: const Text(
              'Add Product',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate().scale(duration: 300.ms, curve: Curves.elasticOut).fade(),
      // body start here
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Loading Product...',
                      style: TextStyle(color: Colors.grey[600]),
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              )
              : _crops.isEmpty
              ? FadeIn(
                duration: const Duration(milliseconds: 500),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.eco_outlined,
                        size: 70,
                        color: Colors.teal.withOpacity(0.5),
                      ).animate().scale(
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No product available',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Your First product'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 3,
                            ),
                            onPressed: () => _showCropDialog(),
                          )
                          .animate()
                          .fadeIn(delay: 400.ms)
                          .moveY(begin: 20, end: 0),
                    ],
                  ),
                ),
              )
              : RefreshIndicator(
                color: Colors.teal,
                onRefresh: _fetchCrops,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Search bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search Product...',
                            filled: true,
                            fillColor: Color(0xFFE8F5E9),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.teal.withOpacity(0.7),
                            ),
                            border: InputBorder.none,
                            suffixIcon:
                                _searchController.text.isNotEmpty
                                    ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: Colors.grey[500],
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        _filterCrops();
                                      },
                                    )
                                    : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Statistics
                      _buildStatistics(),
                      const SizedBox(height: 16),
                      // Filter controls
                      _buildFilterControls(),
                      const SizedBox(height: 16),
                      // Results count
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Text(
                              'Found ${_filteredCrops.length} Product',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Crop list
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _filteredCrops.length,
                        itemBuilder: (context, index) {
                          final crop = _filteredCrops[index];
                          return _buildCropCard(crop, index);
                        },
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
