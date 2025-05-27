import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_room.dart';
import '../../widgets/chat_room_tile.dart';
import 'chat_room_screen.dart';
import 'create_room_screen.dart';
import 'public_rooms_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  Future<void> _loadChatRooms() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.loadChatRooms();
  }

  Future<void> _refreshChatRooms() async {
    await _loadChatRooms();
  }

  void _openChatRoom(ChatRoom room) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(chatRoom: room),
      ),
    );
  }

  void _showCreateRoomDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateRoomScreen(),
      ),
    );
  }

  void _showPublicRooms() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PublicRoomsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.public),
            onPressed: _showPublicRooms,
            tooltip: 'Browse Public Rooms',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'create_room':
                  _showCreateRoomDialog();
                  break;
                case 'refresh':
                  _refreshChatRooms();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'create_room',
                child: Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('Create Room'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading && chatProvider.chatRooms.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (chatProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading chats',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    chatProvider.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshChatRooms,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (chatProvider.chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a room or join a public room to start chatting',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showCreateRoomDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Room'),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: _showPublicRooms,
                        icon: const Icon(Icons.public),
                        label: const Text('Browse Rooms'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshChatRooms,
            child: ListView.builder(
              itemCount: chatProvider.chatRooms.length,
              itemBuilder: (context, index) {
                final room = chatProvider.chatRooms[index];
                return ChatRoomTile(
                  chatRoom: room,
                  onTap: () => _openChatRoom(room),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRoomDialog,
        tooltip: 'Create Room',
        child: const Icon(Icons.add),
      ),
    );
  }
}
