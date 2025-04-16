import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<dynamic> chats = [];
  final TextEditingController _senderIdController = TextEditingController();
  final TextEditingController _receiverIdController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    final response = await http.get(Uri.parse('http://your-api-url/chats'));
    if (response.statusCode == 200) {
      setState(() {
        chats = json.decode(response.body);
      });
    } else {
      // Handle error
      print('Failed to load chats');
    }
  }

  Future<void> _createChat() async {
    final response = await http.post(
      Uri.parse('http://your-api-url/chats'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'sender_id': _senderIdController.text,
        'receiver_id': _receiverIdController.text,
        'message': _messageController.text,
      }),
    );

    if (response.statusCode == 201) {
      _fetchChats();
      _clearFields();
    } else {
      // Handle error
      print('Failed to create chat');
    }
  }

  Future<void> _deleteChat(String id) async {
    final response = await http.delete(Uri.parse('http://your-api-url/chats/$id'));
    if (response.statusCode == 200) {
      _fetchChats();
    } else {
      // Handle error
      print('Failed to delete chat');
    }
  }

  void _clearFields() {
    _senderIdController.clear();
    _receiverIdController.clear();
    _messageController.clear();
  }

  void _showForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Chat Message'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _senderIdController,
                decoration: const InputDecoration(labelText: 'Sender ID'),
              ),
              TextField(
                controller: _receiverIdController,
                decoration: const InputDecoration(labelText: 'Receiver ID'),
              ),
              TextField(
                controller: _messageController,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _createChat();
                Navigator.of(context).pop();
              },
              child: const Text('Send'),
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
        title: const Text('Chat Management'),
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
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text('Message from ${chat['sender_id']} to ${chat['receiver_id']}'),
              subtitle: Text(chat['message']),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteChat(chat['chat_id'].toString()),
              ),
            ),
          );
        },
      ),
    );
  }
}