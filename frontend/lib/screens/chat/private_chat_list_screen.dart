import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';
import '../../models/private_chat.dart';
import 'private_chat_screen.dart';

class PrivateChatListScreen extends StatefulWidget {
  const PrivateChatListScreen({super.key});

  @override
  State<PrivateChatListScreen> createState() => _PrivateChatListScreenState();
}

class _PrivateChatListScreenState extends State<PrivateChatListScreen> {
  @override
  void initState() {
    super.initState();
    _loadPrivateChats();
  }

  Future<void> _loadPrivateChats() async {
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);
    await friendProvider.loadPrivateChats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPrivateChats,
          ),
        ],
      ),
      body: Consumer<FriendProvider>(
        builder: (context, friendProvider, child) {
          if (friendProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (friendProvider.privateChats.isEmpty) {
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
                    'No conversations yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start chatting with your friends',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/users');
                    },
                    child: const Text('Find Friends'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadPrivateChats,
            child: ListView.builder(
              itemCount: friendProvider.privateChats.length,
              itemBuilder: (context, index) {
                final chat = friendProvider.privateChats[index];
                return PrivateChatTile(
                  privateChat: chat,
                  onTap: () => _openPrivateChat(chat),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/users');
        },
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  void _openPrivateChat(PrivateChat chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivateChatScreen(privateChat: chat),
      ),
    );
  }
}

class PrivateChatTile extends StatelessWidget {
  final PrivateChat privateChat;
  final VoidCallback onTap;

  const PrivateChatTile({
    super.key,
    required this.privateChat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final otherUser = privateChat.getOtherParticipant(currentUser?.id ?? '');
    final unreadCount = privateChat.unreadCount ?? 0;

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).primaryColor,
            child: otherUser?.profilePicture.isNotEmpty == true
                ? ClipOval(
                    child: Image.network(
                      otherUser!.profilePicture,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          otherUser.username[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  )
                : Text(
                    otherUser?.username[0].toUpperCase() ?? '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          if (otherUser?.isOnline == true)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherUser?.username ?? 'Unknown User',
              style: TextStyle(
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            privateChat.getLastMessagePreview(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
              color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            privateChat.getFormattedLastActivity(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
      trailing: otherUser?.isOnline == true
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Online',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            )
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
