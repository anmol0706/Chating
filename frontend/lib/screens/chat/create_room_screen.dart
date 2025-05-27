import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/chat_provider.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _roomType = 'public';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    final success = await chatProvider.createChatRoom(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _roomType,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
      Fluttertoast.showToast(
        msg: 'Room created successfully!',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } else {
      Fluttertoast.showToast(
        msg: chatProvider.error ?? 'Failed to create room',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Room'),
        actions: [
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return TextButton(
                onPressed: chatProvider.isLoading ? null : _createRoom,
                child: chatProvider.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create'),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Room Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.chat_bubble_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a room name';
                  }
                  if (value.trim().length > 50) {
                    return 'Room name cannot exceed 50 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value != null && value.length > 200) {
                    return 'Description cannot exceed 200 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Room Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              RadioListTile<String>(
                title: const Text('Public'),
                subtitle: const Text('Anyone can join this room'),
                value: 'public',
                groupValue: _roomType,
                onChanged: (value) {
                  setState(() {
                    _roomType = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Private'),
                subtitle: const Text('Only invited users can join'),
                value: 'private',
                groupValue: _roomType,
                onChanged: (value) {
                  setState(() {
                    _roomType = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
