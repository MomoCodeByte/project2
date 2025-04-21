import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

// Make sure to add these permission configs to your app:
// For Android: Add to android/app/src/main/AndroidManifest.xml:
// <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
// <uses-permission android:name="android.permission.CAMERA" />
//
// For iOS: Add to ios/Runner/Info.plist:
// <key>NSPhotoLibraryUsageDescription</key>
// <string>This app needs access to your photo library to select crop images</string>
// <key>NSCameraUsageDescription</key>
// <string>This app needs access to your camera to take crop photos</string>

class Crop {
  final int? id;
  final int? farmerId;
  final String name;
  final String description;
  final double price;
  final int availability;
  final String? imagePath;

  Crop({
    this.id,
    this.farmerId,
    required this.name,
    required this.description,
    required this.price,
    required this.availability,
    this.imagePath,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farmer_id': farmerId,
      'name': name,
      'description': description,
      'price': price,
      'availability': availability,
    };
  }
}

class CropManagementScreen extends StatefulWidget {
  const CropManagementScreen({Key? key}) : super(key: key);

  @override
  _CropManagementScreenState createState() => _CropManagementScreenState();
}

class _CropManagementScreenState extends State<CropManagementScreen> {
  List<Crop> _crops = [];
  bool _isLoading = true;
  final String _baseUrl = 'http://localhost:3000/api';
  final ImagePicker _picker = ImagePicker();
  final currencyFormat = NumberFormat("#,##0.00", "en_US");

  @override
  void initState() {
    super.initState();
    _fetchCrops();
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

  Future<void> _deleteCrop(int id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/crops/$id'));
      if (response.statusCode == 200) {
        setState(() {
          _crops.removeWhere((crop) => crop.id == id);
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

  // Fixed image picker method
  Future<File?> _pickImage(ImageSource source) async {
    try {
      // Use XFile instead of File
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

    File? imageFile;

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(crop == null ? 'Add New Crop' : 'Edit Crop'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: 'Name'),
                        ),
                        TextField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                          maxLines: 3,
                        ),
                        TextField(
                          controller: priceController,
                          decoration: const InputDecoration(labelText: 'Price'),
                          keyboardType: TextInputType.number,
                        ),
                        TextField(
                          controller: availabilityController,
                          decoration: const InputDecoration(
                            labelText: 'Availability',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        TextField(
                          controller: farmerIdController,
                          decoration: const InputDecoration(
                            labelText: 'Farmer ID',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 20),
                        if (imageFile != null)
                          Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(imageFile!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        if (crop?.imagePath != null && imageFile == null)
                          Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(
                                  '$_baseUrl/${crop!.imagePath}',
                                ),
                                fit: BoxFit.cover,
                                onError: (object, stackTrace) {
                                  // If the image fails to load, don't show an error
                                },
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Gallery'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                // Use the fixed _pickImage method
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
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Camera'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                // Use the fixed _pickImage method
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
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
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
                            price: double.tryParse(priceController.text) ?? 0.0,
                            availability:
                                int.tryParse(availabilityController.text) ?? 0,
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
    );
  }

  Future<void> _addCrop(Crop crop, File? imageFile) async {
    try {
      if (imageFile == null) {
        // If no image, just create the crop with JSON
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
        // If image exists, use multipart request
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl/crops'),
        );

        // Add text fields
        request.fields['name'] = crop.name;
        request.fields['description'] = crop.description;
        request.fields['price'] = crop.price.toString();
        request.fields['availability'] = crop.availability.toString();
        request.fields['farmer_id'] = crop.farmerId.toString();

        // Add image file - make sure to use 'image' as the field name
        final fileStream = http.ByteStream(imageFile.openRead());
        final fileLength = await imageFile.length();

        final multipartFile = http.MultipartFile(
          'image', // This must match the field name expected by your server
          fileStream,
          fileLength,
          filename: path.basename(imageFile.path),
        );

        request.files.add(multipartFile);

        // Send the request
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
        // If no image, just update the crop with JSON
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
        // If image exists, use multipart request
        var request = http.MultipartRequest(
          'PUT',
          Uri.parse('$_baseUrl/crops/${crop.id}'),
        );

        // Add text fields
        request.fields['name'] = crop.name;
        request.fields['description'] = crop.description;
        request.fields['price'] = crop.price.toString();
        request.fields['availability'] = crop.availability.toString();
        request.fields['farmer_id'] = crop.farmerId.toString();

        // Add image file - make sure to use 'image' as the field name
        final fileStream = http.ByteStream(imageFile.openRead());
        final fileLength = await imageFile.length();

        final multipartFile = http.MultipartFile(
          'image', // This must match the field name expected by your server
          fileStream,
          fileLength,
          filename: path.basename(imageFile.path),
        );

        request.files.add(multipartFile);

        // Send the request
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

  Widget _buildCropCard(Crop crop) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          Stack(
            children: [
              crop.imagePath != null
                  ? Image.network(
                    '$_baseUrl/${crop.imagePath}',
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) =>
                            _buildPlaceholderImage(),
                  )
                  : _buildPlaceholderImage(),
              // Availability tag
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: crop.availability > 0 ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    crop.availability > 0 ? 'In Stock' : 'Out of Stock',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Content section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crop.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.teal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    crop.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        '\$${currencyFormat.format(crop.price)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Qty: ${crop.availability}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Button section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.teal),
                  onPressed: () => _showCropDialog(crop: crop),
                  tooltip: 'Edit',
                  iconSize: 20,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Delete Crop'),
                            content: Text(
                              'Are you sure you want to delete ${crop.name}?',
                            ),
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
                  },
                  tooltip: 'Delete',
                  iconSize: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 130,
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.image, size: 40, color: Colors.grey[400]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Crop Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCrops,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        onPressed: () => _showCropDialog(),
        child: const Icon(Icons.add),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
              )
              : _crops.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.eco_outlined,
                      size: 80,
                      color: Colors.teal.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No crops available',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Your First Crop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () => _showCropDialog(),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                color: Colors.teal,
                onRefresh: _fetchCrops,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: _crops.length,
                    itemBuilder: (context, index) {
                      final crop = _crops[index];
                      return _buildCropCard(crop);
                    },
                  ),
                ),
              ),
    );
  }
}
