import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_room.dart';
import 'chat_room_screen.dart';

class PublicRoomsScreen extends StatefulWidget {
  const PublicRoomsScreen({super.key});

  @override
  State<PublicRoomsScreen> createState() => _PublicRoomsScreenState();
}

class _PublicRoomsScreenState extends State<PublicRoomsScreen> {
  @override
  void initState() {
    super.initState();
    _loadPublicRooms();
  }

  Future<void> _loadPublicRooms() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.loadPublicRooms();
  }

  Future<void> _joinRoom(ChatRoom room) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    final success = await chatProvider.joinChatRoom(room.id);

    if (success && mounted) {
      Navigator.of(context).pop(); // Go back to chat list
      Fluttertoast.showToast(
        msg: 'Joined ${room.name} successfully!',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } else {
      Fluttertoast.showToast(
        msg: chatProvider.error ?? 'Failed to join room',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _openChatRoom(ChatRoom room) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(chatRoom: room),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Public Rooms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPublicRooms,
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading && chatProvider.publicRooms.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (chatProvider.publicRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.public_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No public rooms available',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create the first public room!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadPublicRooms,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadPublicRooms,
            child: ListView.builder(
              itemCount: chatProvider.publicRooms.length,
              itemBuilder: (context, index) {
                final room = chatProvider.publicRooms[index];
                final isAlreadyJoined = chatProvider.chatRooms
                    .any((joinedRoom) => joinedRoom.id == room.id);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        room.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      room.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (room.description.isNotEmpty)
                          Text(
                            room.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${room.participantCount} members',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: isAlreadyJoined
                        ? ElevatedButton(
                            onPressed: () => _openChatRoom(room),
                            child: const Text('Open'),
                          )
                        : OutlinedButton(
                            onPressed: () => _joinRoom(room),
                            child: const Text('Join'),
                          ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
