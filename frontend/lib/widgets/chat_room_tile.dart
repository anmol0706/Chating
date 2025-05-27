import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_room.dart';

class ChatRoomTile extends StatelessWidget {
  final ChatRoom chatRoom;
  final VoidCallback onTap;

  const ChatRoomTile({
    super.key,
    required this.chatRoom,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        child: Text(
          chatRoom.name[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chatRoom.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chatRoom.type == 'private')
            Icon(
              Icons.lock,
              size: 16,
              color: Colors.grey[600],
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chatRoom.lastMessage != null)
            Text(
              '${chatRoom.lastMessage!.sender.username}: ${chatRoom.lastMessage!.content}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            )
          else
            Text(
              'No messages yet',
              style: TextStyle(
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.people,
                size: 12,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                '${chatRoom.participantCount} members',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              if (chatRoom.onlineParticipants.isNotEmpty) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.circle,
                  size: 8,
                  color: Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  '${chatRoom.onlineParticipants.length} online',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(chatRoom.lastActivity),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: chatRoom.type == 'public'
                  ? Colors.blue.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              chatRoom.type.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: chatRoom.type == 'public' ? Colors.blue : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return DateFormat('EEEE').format(dateTime);
      } else {
        return DateFormat('MMM dd').format(dateTime);
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
