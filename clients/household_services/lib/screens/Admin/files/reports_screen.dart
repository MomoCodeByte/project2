import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<dynamic> reports = [];
  final TextEditingController _reportTypeController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    final response = await http.get(Uri.parse('http://your-api-url/reports'));
    if (response.statusCode == 200) {
      setState(() {
        reports = json.decode(response.body);
      });
    } else {
      // Handle error
      print('Failed to load reports');
    }
  }

  Future<void> _createReport() async {
    final response = await http.post(
      Uri.parse('http://your-api-url/reports'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'admin_id': '1', // Replace with actual admin ID
        'report_type': _reportTypeController.text,
        'content': _contentController.text,
      }),
    );

    if (response.statusCode == 201) {
      _fetchReports();
      _reportTypeController.clear();
      _contentController.clear();
    } else {
      // Handle error
      print('Failed to create report');
    }
  }

  Future<void> _deleteReport(int id) async {
    final response = await http.delete(Uri.parse('http://your-api-url/reports/$id'));
    if (response.statusCode == 200) {
      _fetchReports();
    } else {
      // Handle error
      print('Failed to delete report');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports Management'),
      ),
      body: Column(
        children: [
          // Report creation form
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _reportTypeController,
                  decoration: const InputDecoration(labelText: 'Report Type'),
                ),
                TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(labelText: 'Content'),
                  maxLines: 3,
                ),
                ElevatedButton(
                  onPressed: _createReport,
                  child: const Text('Create Report'),
                ),
              ],
            ),
          ),
          // Reports list
          Expanded(
            child: ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(report['report_type']),
                    subtitle: Text(report['content']),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteReport(report['report_id']),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}