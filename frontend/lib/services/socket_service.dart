import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/user.dart';
import '../models/message.dart';
import 'api_service.dart';

class SocketService {
  static const String serverUrl = 'https://chating-657p.onrender.com';

  // Singleton pattern
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;

  // Stream controllers for real-time events
  final _messageController = StreamController<Message>.broadcast();
  final _userOnlineController = StreamController<User>.broadcast();
  final _userOfflineController = StreamController<User>.broadcast();
  final _typingController = StreamController<TypingEvent>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  // Getters for streams
  Stream<Message> get messageStream => _messageController.stream;
  Stream<User> get userOnlineStream => _userOnlineController.stream;
  Stream<User> get userOfflineStream => _userOfflineController.stream;
  Stream<TypingEvent> get typingStream => _typingController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;

  // Connect to socket server
  Future<void> connect() async {
    final apiService = ApiService();
    final token = apiService.token;

    if (token == null) {
      throw Exception('No authentication token available');
    }

    _socket = io.io(serverUrl,
      io.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .setAuth({'token': token})
        .build()
    );

    _setupEventListeners();
    _socket!.connect();
  }

  // Disconnect from socket server
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _connectionController.add(false);
  }

  // Setup event listeners
  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      // Connected to socket server
      _isConnected = true;
      _connectionController.add(true);
    });

    _socket!.onDisconnect((_) {
      // Disconnected from socket server
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.onConnectError((error) {
      // Socket connection error: $error
      _isConnected = false;
      _connectionController.add(false);
    });

    // Message events
    _socket!.on('new_message', (data) {
      try {
        final message = Message.fromJson(data['message']);
        _messageController.add(message);
      } catch (e) {
        // Error parsing new message: $e
      }
    });

    // User status events
    _socket!.on('user_online', (data) {
      try {
        final user = User(
          id: data['userId'],
          username: data['username'],
          email: '', // Not provided in this event
          isOnline: true,
        );
        _userOnlineController.add(user);
      } catch (e) {
        // Error parsing user online event: $e
      }
    });

    _socket!.on('user_offline', (data) {
      try {
        final user = User(
          id: data['userId'],
          username: data['username'],
          email: '', // Not provided in this event
          isOnline: false,
          lastSeen: DateTime.parse(data['lastSeen']),
        );
        _userOfflineController.add(user);
      } catch (e) {
        // Error parsing user offline event: $e
      }
    });

    // Typing events
    _socket!.on('user_typing', (data) {
      _typingController.add(TypingEvent(
        userId: data['userId'],
        username: data['username'],
        roomId: data['roomId'],
        isTyping: true,
      ));
    });

    _socket!.on('user_stop_typing', (data) {
      _typingController.add(TypingEvent(
        userId: data['userId'],
        username: data['username'],
        roomId: data['roomId'],
        isTyping: false,
      ));
    });

    // Room events
    _socket!.on('user_joined_room', (data) {
      // User ${data['username']} joined room ${data['roomId']}
    });

    _socket!.on('user_left_room', (data) {
      // User ${data['username']} left room ${data['roomId']}
    });

    // Error events
    _socket!.on('error', (data) {
      // Socket error: ${data['message']}
    });
  }

  // Join a chat room
  void joinRoom(String roomId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('join_room', {'roomId': roomId});
    }
  }

  // Leave a chat room
  void leaveRoom(String roomId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('leave_room', {'roomId': roomId});
    }
  }

  // Send a message
  void sendMessage({
    required String roomId,
    required String content,
    String messageType = 'text',
    String? replyTo,
  }) {
    if (_socket != null && _isConnected) {
      _socket!.emit('send_message', {
        'roomId': roomId,
        'content': content,
        'messageType': messageType,
        if (replyTo != null) 'replyTo': replyTo,
      });
    }
  }

  // Mark message as read
  void markMessageAsRead(String messageId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('mark_message_read', {'messageId': messageId});
    }
  }

  // Send typing indicator
  void startTyping(String roomId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('typing_start', {'roomId': roomId});
    }
  }

  // Stop typing indicator
  void stopTyping(String roomId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('typing_stop', {'roomId': roomId});
    }
  }

  // Generic emit method
  void emit(String event, Map<String, dynamic> data) {
    if (_socket != null && _isConnected) {
      _socket!.emit(event, data);
    }
  }

  // Generic on method for listening to events
  void on(String event, Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on(event, callback);
    }
  }

  // Generic off method for removing event listeners
  void off(String event) {
    if (_socket != null) {
      _socket!.off(event);
    }
  }

  // Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
    _userOnlineController.close();
    _userOfflineController.close();
    _typingController.close();
    _connectionController.close();
  }
}

class TypingEvent {
  final String userId;
  final String username;
  final String roomId;
  final bool isTyping;

  TypingEvent({
    required this.userId,
    required this.username,
    required this.roomId,
    required this.isTyping,
  });

  @override
  String toString() {
    return 'TypingEvent(userId: $userId, username: $username, roomId: $roomId, isTyping: $isTyping)';
  }
}
