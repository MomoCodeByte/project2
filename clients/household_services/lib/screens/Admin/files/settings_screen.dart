import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<dynamic> settings = [];
  final TextEditingController _settingNameController = TextEditingController();
  final TextEditingController _settingValueController = TextEditingController();
  String? _selectedSettingId;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    final response = await http.get(Uri.parse('http://your-api-url/settings'));
    if (response.statusCode == 200) {
      setState(() {
        settings = json.decode(response.body);
      });
    } else {
      // Handle error
      print('Failed to load settings');
    }
  }

  Future<void> _createSetting() async {
    final response = await http.post(
      Uri.parse('http://your-api-url/settings'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'admin_id': '1', // Replace with actual admin ID
        'setting_name': _settingNameController.text,
        'setting_value': _settingValueController.text,
      }),
    );

    if (response.statusCode == 201) {
      _fetchSettings();
      _clearFields();
    } else {
      // Handle error
      print('Failed to create setting');
    }
  }

  Future<void> _updateSetting(String id) async {
    final response = await http.put(
      Uri.parse('http://your-api-url/settings/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'admin_id': '1', // Replace with actual admin ID
        'setting_name': _settingNameController.text,
        'setting_value': _settingValueController.text,
      }),
    );

    if (response.statusCode == 200) {
      _fetchSettings();
      _clearFields();
    } else {
      // Handle error
      print('Failed to update setting');
    }
  }

  Future<void> _deleteSetting(String id) async {
    final response = await http.delete(Uri.parse('http://your-api-url/settings/$id'));
    if (response.statusCode == 200) {
      _fetchSettings();
    } else {
      // Handle error
      print('Failed to delete setting');
    }
  }

  void _clearFields() {
    _settingNameController.clear();
    _settingValueController.clear();
    setState(() {
      _selectedSettingId = null;
    });
  }

  void _showForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_selectedSettingId == null ? 'Create Setting' : 'Update Setting'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _settingNameController,
                decoration: const InputDecoration(labelText: 'Setting Name'),
              ),
              TextField(
                controller: _settingValueController,
                decoration: const InputDecoration(labelText: 'Setting Value'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_selectedSettingId == null) {
                  _createSetting();
                } else {
                  _updateSetting(_selectedSettingId!);
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
        title: const Text('Settings Management'),
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
        itemCount: settings.length,
        itemBuilder: (context, index) {
          final setting = settings[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(setting['setting_name']),
              subtitle: Text(setting['setting_value']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      _settingNameController.text = setting['setting_name'];
                      _settingValueController.text = setting['setting_value'];
                      setState(() {
                        _selectedSettingId = setting['setting_id'].toString();
                      });
                      _showForm(context);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteSetting(setting['setting_id'].toString()),
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