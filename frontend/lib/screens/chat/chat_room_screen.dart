import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/chat_room.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/typing_indicator.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatRoomScreen({
    super.key,
    required this.chatRoom,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _enterRoom();
  }

  @override
  void dispose() {
    _leaveRoom();
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> _enterRoom() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.enterRoom(widget.chatRoom.id);
  }

  void _leaveRoom() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.leaveCurrentRoom();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.sendMessage(
      roomId: widget.chatRoom.id,
      content: content,
    );

    _messageController.clear();
    _stopTyping();
    _scrollToBottom();
  }

  void _onMessageChanged(String text) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      chatProvider.startTyping(widget.chatRoom.id);
    }

    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _stopTyping();
    });
  }

  void _stopTyping() {
    if (_isTyping) {
      _isTyping = false;
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.stopTyping(widget.chatRoom.id);
    }
    _typingTimer?.cancel();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.chatRoom.name),
            Text(
              '${widget.chatRoom.participantCount} members',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[300],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showRoomInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final messages = chatProvider.getRoomMessages(widget.chatRoom.id);

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet.\nSend the first message!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.sender.id == currentUser?.id;
                    final showSenderName = !isMe &&
                        (index == 0 || messages[index - 1].sender.id != message.sender.id);

                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                      showSenderName: showSenderName,
                    );
                  },
                );
              },
            ),
          ),

          // Typing Indicator
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              final typingUsers = chatProvider.getTypingUsers(widget.chatRoom.id);
              final currentUsername = currentUser?.username ?? '';
              final otherTypingUsers = typingUsers
                  .where((username) => username != currentUsername)
                  .toList();

              if (otherTypingUsers.isEmpty) {
                return const SizedBox.shrink();
              }

              return TypingIndicator(usernames: otherTypingUsers);
            },
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Colors.grey[300]!,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: _onMessageChanged,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRoomInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                widget.chatRoom.type == 'public' ? Icons.public : Icons.lock,
                color: widget.chatRoom.type == 'public' ? Colors.blue : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.chatRoom.name,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.chatRoom.description.isNotEmpty) ...[
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(widget.chatRoom.description),
                const SizedBox(height: 16),
              ],
              const Text(
                'Room Type:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.chatRoom.type == 'public'
                      ? Colors.blue.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.chatRoom.type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.chatRoom.type == 'public' ? Colors.blue : Colors.orange,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Created:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(_formatDate(widget.chatRoom.createdAt)),
              const SizedBox(height: 16),
              const Text(
                'Last Activity:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(_formatDate(widget.chatRoom.lastActivity)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday at ${_formatTime(dateTime)}';
      } else if (difference.inDays < 7) {
        return '${_getDayName(dateTime.weekday)} at ${_formatTime(dateTime)}';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${_formatTime(dateTime)}';
      }
    } else if (difference.inHours > 0) {
      return 'Today at ${_formatTime(dateTime)}';
    } else {
      return 'Today at ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
}
