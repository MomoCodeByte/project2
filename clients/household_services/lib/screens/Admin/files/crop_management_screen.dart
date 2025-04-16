import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CropManagementScreen extends StatefulWidget {
  const CropManagementScreen({Key? key}) : super(key: key);

  @override
  _CropManagementScreenState createState() => _CropManagementScreenState();
}

class _CropManagementScreenState extends State<CropManagementScreen> {
  List<dynamic> crops = [];
  final TextEditingController _farmerIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();
  String? _selectedCropId;

  @override
  void initState() {
    super.initState();
    _fetchCrops();
  }

  Future<void> _fetchCrops() async {
    final response = await http.get(Uri.parse('http://your-api-url/crops'));
    if (response.statusCode == 200) {
      setState(() {
        crops = json.decode(response.body);
      });
    } else {
      // Handle error
      print('Failed to load crops');
    }
  }

  Future<void> _createCrop() async {
    final response = await http.post(
      Uri.parse('http://your-api-url/crops'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'farmer_id': _farmerIdController.text,
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'availability': int.parse(_availabilityController.text),
      }),
    );

    if (response.statusCode == 201) {
      _fetchCrops();
      _clearFields();
    } else {
      // Handle error
      print('Failed to create crop');
    }
  }

  Future<void> _updateCrop(String id) async {
    final response = await http.put(
      Uri.parse('http://your-api-url/crops/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'farmer_id': _farmerIdController.text,
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'availability': int.parse(_availabilityController.text),
      }),
    );

    if (response.statusCode == 200) {
      _fetchCrops();
      _clearFields();
    } else {
      // Handle error
      print('Failed to update crop');
    }
  }

  Future<void> _deleteCrop(String id) async {
    final response = await http.delete(Uri.parse('http://your-api-url/crops/$id'));
    if (response.statusCode == 200) {
      _fetchCrops();
    } else {
      // Handle error
      print('Failed to delete crop');
    }
  }

  void _clearFields() {
    _farmerIdController.clear();
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _availabilityController.clear();
    setState(() {
      _selectedCropId = null;
    });
  }

  void _showForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_selectedCropId == null ? 'Create Crop' : 'Update Crop'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _farmerIdController,
                decoration: const InputDecoration(labelText: 'Farmer ID'),
              ),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Crop Name'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _availabilityController,
                decoration: const InputDecoration(labelText: 'Availability'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_selectedCropId == null) {
                  _createCrop();
                } else {
                  _updateCrop(_selectedCropId!);
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
        title: const Text('Crop Management'),
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
        itemCount: crops.length,
        itemBuilder: (context, index) {
          final crop = crops[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(crop['name']),
              subtitle: Text('Price: \$${crop['price']} - Availability: ${crop['availability']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      _farmerIdController.text = crop['farmer_id'].toString();
                      _nameController.text = crop['name'];
                      _descriptionController.text = crop['description'];
                      _priceController.text = crop['price'].toString();
                      _availabilityController.text = crop['availability'].toString();
                      setState(() {
                        _selectedCropId = crop['crop_id'].toString();
                      });
                      _showForm(context);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteCrop(crop['crop_id'].toString()),
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