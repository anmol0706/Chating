import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class ChatProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  List<ChatRoom> _chatRooms = [];
  List<ChatRoom> _publicRooms = [];
  final Map<String, List<Message>> _roomMessages = {};
  List<User> _onlineUsers = [];
  final Map<String, List<String>> _typingUsers = {};

  bool _isLoading = false;
  String? _error;
  String? _currentRoomId;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _userOnlineSubscription;
  StreamSubscription? _userOfflineSubscription;
  StreamSubscription? _typingSubscription;

  // Getters
  List<ChatRoom> get chatRooms => _chatRooms;
  List<ChatRoom> get publicRooms => _publicRooms;
  List<User> get onlineUsers => _onlineUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentRoomId => _currentRoomId;

  List<Message> getRoomMessages(String roomId) {
    return _roomMessages[roomId] ?? [];
  }

  List<String> getTypingUsers(String roomId) {
    return _typingUsers[roomId] ?? [];
  }

  // Initialize chat provider
  Future<void> initialize() async {
    _setupSocketListeners();
    await loadChatRooms();
    await loadOnlineUsers();
  }

  // Setup socket event listeners
  void _setupSocketListeners() {
    _messageSubscription = _socketService.messageStream.listen((message) {
      _addMessageToRoom(message);
    });

    _userOnlineSubscription = _socketService.userOnlineStream.listen((user) {
      _updateUserOnlineStatus(user, true);
    });

    _userOfflineSubscription = _socketService.userOfflineStream.listen((user) {
      _updateUserOnlineStatus(user, false);
    });

    _typingSubscription = _socketService.typingStream.listen((typingEvent) {
      _updateTypingStatus(typingEvent);
    });
  }

  // Load user's chat rooms
  Future<void> loadChatRooms() async {
    _setLoading(true);
    try {
      _chatRooms = await _apiService.getUserChatRooms();
      _clearError();
    } catch (e) {
      _setError('Failed to load chat rooms: ${_getErrorMessage(e)}');
    } finally {
      _setLoading(false);
    }
  }

  // Load public chat rooms
  Future<void> loadPublicRooms() async {
    try {
      _publicRooms = await _apiService.getPublicChatRooms();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load public rooms: ${_getErrorMessage(e)}');
    }
  }

  // Load online users
  Future<void> loadOnlineUsers() async {
    try {
      _onlineUsers = await _apiService.getUsers(online: true);
      notifyListeners();
    } catch (e) {
      // Failed to load online users: $e
    }
  }

  // Create new chat room
  Future<bool> createChatRoom({
    required String name,
    String description = '',
    String type = 'public',
  }) async {
    _setLoading(true);
    try {
      final newRoom = await _apiService.createChatRoom(
        name: name,
        description: description,
        type: type,
      );

      _chatRooms.insert(0, newRoom);
      _clearError();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to create chat room: ${_getErrorMessage(e)}');
      _setLoading(false);
      return false;
    }
  }

  // Join chat room
  Future<bool> joinChatRoom(String roomId) async {
    try {
      await _apiService.joinChatRoom(roomId);
      _socketService.joinRoom(roomId);
      await loadChatRooms(); // Refresh rooms list
      return true;
    } catch (e) {
      _setError('Failed to join chat room: ${_getErrorMessage(e)}');
      return false;
    }
  }

  // Leave chat room
  Future<bool> leaveChatRoom(String roomId) async {
    try {
      await _apiService.leaveChatRoom(roomId);
      _socketService.leaveRoom(roomId);

      // Remove from local list
      _chatRooms.removeWhere((room) => room.id == roomId);
      _roomMessages.remove(roomId);

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to leave chat room: ${_getErrorMessage(e)}');
      return false;
    }
  }

  // Enter a chat room
  Future<void> enterRoom(String roomId) async {
    if (_currentRoomId == roomId) return;

    // Leave previous room
    if (_currentRoomId != null) {
      _socketService.leaveRoom(_currentRoomId!);
    }

    _currentRoomId = roomId;
    _socketService.joinRoom(roomId);

    // Load messages if not already loaded
    if (!_roomMessages.containsKey(roomId)) {
      await loadRoomMessages(roomId);
    }

    notifyListeners();
  }

  // Leave current room
  void leaveCurrentRoom() {
    if (_currentRoomId != null) {
      _socketService.leaveRoom(_currentRoomId!);
      _currentRoomId = null;
      notifyListeners();
    }
  }

  // Load messages for a room
  Future<void> loadRoomMessages(String roomId) async {
    try {
      final messages = await _apiService.getChatRoomMessages(roomId: roomId);
      _roomMessages[roomId] = messages;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load messages: ${_getErrorMessage(e)}');
    }
  }

  // Send message
  void sendMessage({
    required String roomId,
    required String content,
    String? replyTo,
  }) {
    if (content.trim().isEmpty) return;

    _socketService.sendMessage(
      roomId: roomId,
      content: content.trim(),
      replyTo: replyTo,
    );
  }

  // Start typing
  void startTyping(String roomId) {
    _socketService.startTyping(roomId);
  }

  // Stop typing
  void stopTyping(String roomId) {
    _socketService.stopTyping(roomId);
  }

  // Add message to room
  void _addMessageToRoom(Message message) {
    final roomId = message.chatRoom;

    if (!_roomMessages.containsKey(roomId)) {
      _roomMessages[roomId] = [];
    }

    _roomMessages[roomId]!.add(message);

    // Update room's last message
    final roomIndex = _chatRooms.indexWhere((room) => room.id == roomId);
    if (roomIndex != -1) {
      _chatRooms[roomIndex] = _chatRooms[roomIndex].copyWith(
        lastMessage: message,
        lastActivity: message.createdAt,
      );

      // Move room to top
      final room = _chatRooms.removeAt(roomIndex);
      _chatRooms.insert(0, room);
    }

    notifyListeners();
  }

  // Update user online status
  void _updateUserOnlineStatus(User user, bool isOnline) {
    final index = _onlineUsers.indexWhere((u) => u.id == user.id);

    if (isOnline) {
      if (index == -1) {
        _onlineUsers.add(user);
      } else {
        _onlineUsers[index] = user;
      }
    } else {
      if (index != -1) {
        _onlineUsers.removeAt(index);
      }
    }

    notifyListeners();
  }

  // Update typing status
  void _updateTypingStatus(TypingEvent event) {
    final roomId = event.roomId;

    if (!_typingUsers.containsKey(roomId)) {
      _typingUsers[roomId] = [];
    }

    final typingList = _typingUsers[roomId]!;

    if (event.isTyping) {
      if (!typingList.contains(event.username)) {
        typingList.add(event.username);
      }
    } else {
      typingList.remove(event.username);
    }

    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }
    return error.toString();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _userOnlineSubscription?.cancel();
    _userOfflineSubscription?.cancel();
    _typingSubscription?.cancel();
    super.dispose();
  }
}
