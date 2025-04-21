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

class _CropManagementScreenState extends State<CropManagementScreen>
    with TickerProviderStateMixin {
  List<Crop> _crops = [];
  bool _isLoading = true;
  final String _baseUrl = 'http://localhost:3000/api';
  final ImagePicker _picker = ImagePicker();
  final currencyFormat = NumberFormat("#,##0.00", "en_US");
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _fetchCrops();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
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

  Widget _buildCropCard(Crop crop, int index) {
    return FadeInUp(
      duration: Duration(milliseconds: 300 + (index * 100)),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _showCropDialog(crop: crop),
              backgroundColor: Colors.teal.shade400,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(10),
              ),
            ),
            SlidableAction(
              onPressed: (_) {
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
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _showCropDialog(crop: crop),
                splashColor: Colors.teal.withOpacity(0.1),
                child: SizedBox(
                  height: 110, // Reduced card height
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image section
                      SizedBox(
                        width: 90,
                        height: 110,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            crop.imagePath != null
                                ? Image.network(
                                  '$_baseUrl/${crop.imagePath}',
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          _buildPlaceholderImage(),
                                )
                                : _buildPlaceholderImage(),
                            // Availability tag
                            Positioned(
                              top: 5,
                              right: 5,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      crop.availability > 0
                                          ? Colors.green.shade600
                                          : Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  crop.availability > 0 ? 'In Stock' : 'Out',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content section
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                crop.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.teal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                crop.description,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Text(
                                    '\Tsh: ${currencyFormat.format(crop.price)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Qty: ${crop.availability}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 300.ms)
            .then()
            .shimmer(duration: 400.ms, curve: Curves.easeInOut)
            .scale(
              begin: Offset(0.95, 0.95),
              end: Offset(1, 1),
              duration: 300.ms,
            ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.eco_outlined, size: 30, color: Colors.grey[400]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Product Management',
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
              )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 1000.ms, begin: 0, end: 1)
              .then(),
        ],
      ),
      floatingActionButton:
          FloatingActionButton(
            onPressed: () {
              _fabAnimationController.reset();
              _fabAnimationController.forward();
              _showCropDialog();
            },
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            elevation: 4,
            child: RotationTransition(
              turns: Tween(begin: 0.0, end: 0.5).animate(
                CurvedAnimation(
                  parent: _fabAnimationController,
                  curve: Curves.elasticOut,
                ),
              ),
              child: const Icon(Icons.add),
            ),
          ).animate().scale(duration: 300.ms, curve: Curves.elasticOut).fade(),
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
                      'Loading crops...',
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
                        'No crops available',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ).animate().fadeIn(delay: 200.ms),
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _crops.length,
                    itemBuilder: (context, index) {
                      final crop = _crops[index];
                      return _buildCropCard(crop, index);
                    },
                  ),
                ),
              ),
    );
  }
}
