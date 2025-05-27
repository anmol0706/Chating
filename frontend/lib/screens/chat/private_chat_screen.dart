import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/private_chat.dart';
import '../../models/message.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/typing_indicator.dart';

class PrivateChatScreen extends StatefulWidget {
  final PrivateChat privateChat;

  const PrivateChatScreen({
    super.key,
    required this.privateChat,
  });

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _isTyping = false;
  User? _currentUser;
  User? _otherUser;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _setupSocketListeners();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _removeSocketListeners();
    super.dispose();
  }

  void _initializeChat() {
    _currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _otherUser = widget.privateChat.getOtherParticipant(_currentUser?.id ?? '');
    _loadMessages();
    _joinPrivateChat();
  }

  void _setupSocketListeners() {
    _socketService.on('new_private_message', _handleNewMessage);
    _socketService.on('private_user_typing', _handleUserTyping);
    _socketService.on('private_user_stop_typing', _handleUserStopTyping);
    _socketService.on('private_message_notification', _handleMessageNotification);
  }

  void _removeSocketListeners() {
    _socketService.off('new_private_message');
    _socketService.off('private_user_typing');
    _socketService.off('private_user_stop_typing');
    _socketService.off('private_message_notification');
  }

  void _joinPrivateChat() {
    _socketService.emit('join_private_chat', {
      'chatId': widget.privateChat.id,
    });
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final messages = await _apiService.getPrivateChatMessages(
        chatId: widget.privateChat.id,
      );

      setState(() {
        _messages = messages;
      });

      // Mark chat as read
      await _apiService.markPrivateChatAsRead(chatId: widget.privateChat.id);

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load messages: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleNewMessage(dynamic data) {
    final messageData = data['message'];
    final message = Message.fromJson(messageData);

    setState(() {
      _messages.add(message);
    });

    _scrollToBottom();

    // Mark as read if message is from other user
    if (message.sender.id != _currentUser?.id) {
      _apiService.markPrivateChatAsRead(
        chatId: widget.privateChat.id,
        messageId: message.id,
      );
    }
  }

  void _handleUserTyping(dynamic data) {
    final userId = data['userId'];
    if (userId != _currentUser?.id) {
      setState(() => _isTyping = true);
    }
  }

  void _handleUserStopTyping(dynamic data) {
    final userId = data['userId'];
    if (userId != _currentUser?.id) {
      setState(() => _isTyping = false);
    }
  }

  void _handleMessageNotification(dynamic data) {
    // Handle notification for this specific chat
    if (data['chatId'] == widget.privateChat.id) {
      // Chat is already open, mark as read
      _apiService.markPrivateChatAsRead(chatId: widget.privateChat.id);
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      // Send via socket for real-time delivery
      _socketService.emit('send_private_message', {
        'chatId': widget.privateChat.id,
        'content': content,
        'messageType': 'text',
      });

      // Also send via API for persistence
      await _apiService.sendPrivateMessage(
        chatId: widget.privateChat.id,
        content: content,
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _onTypingChanged(String text) {
    if (text.isNotEmpty) {
      _socketService.emit('private_typing_start', {
        'chatId': widget.privateChat.id,
      });
    } else {
      _socketService.emit('private_typing_stop', {
        'chatId': widget.privateChat.id,
      });
    }
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: _otherUser?.profilePicture.isNotEmpty == true
                  ? ClipOval(
                      child: Image.network(
                        _otherUser!.profilePicture,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            _otherUser!.username[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    )
                  : Text(
                      _otherUser?.username[0].toUpperCase() ?? '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _otherUser?.username ?? 'Unknown User',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _otherUser?.isOnline == true
                        ? 'Online'
                        : 'Last seen ${_formatLastSeen(_otherUser?.lastSeen)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _otherUser?.isOnline == true
                          ? Colors.green
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show chat info
              _showChatInfo();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
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
                              'Start your conversation',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Send a message to ${_otherUser?.username ?? 'your friend'}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length && _isTyping) {
                            return TypingIndicator(
                              usernames: [_otherUser?.username ?? 'User'],
                            );
                          }

                          final message = _messages[index];
                          final isMe = message.sender.id == _currentUser?.id;

                          return MessageBubble(
                            message: message,
                            isMe: isMe,
                            showSenderName: false, // Private chat, no need to show sender
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
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
                    onChanged: _onTypingChanged,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChatInfo() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: _otherUser?.profilePicture.isNotEmpty == true
                    ? ClipOval(
                        child: Image.network(
                          _otherUser!.profilePicture,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Text(
                              _otherUser!.username[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      )
                    : Text(
                        _otherUser?.username[0].toUpperCase() ?? '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              title: Text(_otherUser?.username ?? 'Unknown User'),
              subtitle: Text(_otherUser?.email ?? ''),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Chat', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this chat? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _apiService.deletePrivateChat(widget.privateChat.id);
                if (mounted) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete chat: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'unknown';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
