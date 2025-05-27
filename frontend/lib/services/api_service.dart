import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../models/friend_request.dart';
import '../models/private_chat.dart';

class ApiService {
  static const String baseUrl = 'https://chating-657p.onrender.com/api';

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;
  User? _currentUser;

  String? get token => _token;
  User? get currentUser => _currentUser;

  // Initialize service and load stored token
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');

    if (_token != null) {
      try {
        await _loadCurrentUser();
      } catch (e) {
        // Token might be invalid, clear it
        await logout();
      }
    }
  }

  // Common headers for authenticated requests
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  // Handle API response
  Map<String, dynamic> _handleResponse(http.Response response) {
    final data = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw ApiException(
        message: data['message'] ?? data['error'] ?? 'Unknown error',
        statusCode: response.statusCode,
      );
    }
  }

  // Authentication methods
  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: json.encode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    final data = _handleResponse(response);

    _token = data['token'];
    _currentUser = User.fromJson(data['user']);

    // Store token
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);

    return AuthResult(user: _currentUser!, token: _token!);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    final data = _handleResponse(response);

    _token = data['token'];
    _currentUser = User.fromJson(data['user']);

    // Store token
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);

    return AuthResult(user: _currentUser!, token: _token!);
  }

  Future<void> logout() async {
    if (_token != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: _headers,
        );
      } catch (e) {
        // Ignore logout errors
      }
    }

    _token = null;
    _currentUser = null;

    // Clear stored token
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<void> _loadCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: _headers,
    );

    final data = _handleResponse(response);
    _currentUser = User.fromJson(data['user']);
  }

  // Chat room methods
  Future<List<ChatRoom>> getUserChatRooms() async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat/rooms'),
      headers: _headers,
    );

    final data = _handleResponse(response);
    return (data['chatRooms'] as List)
        .map((room) => ChatRoom.fromJson(room))
        .toList();
  }

  Future<List<ChatRoom>> getPublicChatRooms({int page = 1, int limit = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat/rooms/public?page=$page&limit=$limit'),
      headers: _headers,
    );

    final data = _handleResponse(response);
    return (data['chatRooms'] as List)
        .map((room) => ChatRoom.fromJson(room))
        .toList();
  }

  Future<ChatRoom> createChatRoom({
    required String name,
    String description = '',
    String type = 'public',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/rooms'),
      headers: _headers,
      body: json.encode({
        'name': name,
        'description': description,
        'type': type,
      }),
    );

    final data = _handleResponse(response);
    return ChatRoom.fromJson(data['chatRoom']);
  }

  Future<void> joinChatRoom(String roomId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/rooms/$roomId/join'),
      headers: _headers,
    );

    _handleResponse(response);
  }

  Future<void> leaveChatRoom(String roomId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/rooms/$roomId/leave'),
      headers: _headers,
    );

    _handleResponse(response);
  }

  Future<List<Message>> getChatRoomMessages({
    required String roomId,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat/rooms/$roomId/messages?page=$page&limit=$limit'),
      headers: _headers,
    );

    final data = _handleResponse(response);
    return (data['messages'] as List)
        .map((message) => Message.fromJson(message))
        .toList();
  }

  // User methods
  Future<List<User>> getUsers({String? search, bool? online}) async {
    String url = '$baseUrl/user';
    List<String> queryParams = [];

    if (search != null && search.isNotEmpty) {
      queryParams.add('search=${Uri.encodeComponent(search)}');
    }

    if (online != null) {
      queryParams.add('online=$online');
    }

    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );

    final data = _handleResponse(response);
    return (data['users'] as List)
        .map((user) => User.fromJson(user))
        .toList();
  }

  Future<User> updateProfile({
    String? username,
    String? profilePicture,
  }) async {
    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (profilePicture != null) body['profilePicture'] = profilePicture;

    final response = await http.put(
      Uri.parse('$baseUrl/user/profile'),
      headers: _headers,
      body: json.encode(body),
    );

    final data = _handleResponse(response);
    _currentUser = User.fromJson(data['user']);
    return _currentUser!;
  }

  // Friend request methods
  Future<FriendRequest> sendFriendRequest({
    required String receiverId,
    String message = '',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/friends/request'),
      headers: _headers,
      body: json.encode({
        'receiverId': receiverId,
        'message': message,
      }),
    );

    final data = _handleResponse(response);
    return FriendRequest.fromJson(data['friendRequest']);
  }

  Future<List<FriendRequest>> getReceivedFriendRequests({
    String status = 'pending',
    int page = 1,
    int limit = 20,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/friends/requests/received?status=$status&page=$page&limit=$limit'),
      headers: _headers,
    );

    final data = _handleResponse(response);
    return (data['friendRequests'] as List)
        .map((request) => FriendRequest.fromJson(request))
        .toList();
  }

  Future<List<FriendRequest>> getSentFriendRequests({
    String status = 'pending',
    int page = 1,
    int limit = 20,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/friends/requests/sent?status=$status&page=$page&limit=$limit'),
      headers: _headers,
    );

    final data = _handleResponse(response);
    return (data['friendRequests'] as List)
        .map((request) => FriendRequest.fromJson(request))
        .toList();
  }

  Future<FriendRequest> acceptFriendRequest(String requestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/friends/requests/$requestId/accept'),
      headers: _headers,
    );

    final data = _handleResponse(response);
    return FriendRequest.fromJson(data['friendRequest']);
  }

  Future<FriendRequest> declineFriendRequest(String requestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/friends/requests/$requestId/decline'),
      headers: _headers,
    );

    final data = _handleResponse(response);
    return FriendRequest.fromJson(data['friendRequest']);
  }

  Future<FriendRequest> cancelFriendRequest(String requestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/friends/requests/$requestId/cancel'),
      headers: _headers,
    );

    final data = _handleResponse(response);
    return FriendRequest.fromJson(data['friendRequest']);
  }

  Future<List<User>> getFriendsList({
    int page = 1,
    int limit = 50,
    String? search,
  }) async {
    String url = '$baseUrl/friends/list?page=$page&limit=$limit';
    if (search != null && search.isNotEmpty) {
      url += '&search=${Uri.encodeComponent(search)}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );

    final data = _handleResponse(response);
    return (data['friends'] as List)
        .map((friend) => User.fromJson(friend))
        .toList();
  }

  Future<void> removeFriend(String friendId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/friends/$friendId'),
      headers: _headers,
    );

    _handleResponse(response);
  }

  // Private chat methods
  Future<PrivateChat> getOrCreatePrivateChat(String friendId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/private-chat/with/$friendId'),
      headers: _headers,
    );

    final data = _handleResponse(response);
    return PrivateChat.fromJson(data['privateChat']);
  }

  Future<List<PrivateChat>> getUserPrivateChats({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/private-chat?page=$page&limit=$limit'),
      headers: _headers,
    );

    final data = _handleResponse(response);
    return (data['privateChats'] as List)
        .map((chat) => PrivateChat.fromJson(chat))
        .toList();
  }

  Future<List<Message>> getPrivateChatMessages({
    required String chatId,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/private-chat/$chatId/messages?page=$page&limit=$limit'),
      headers: _headers,
    );

    final data = _handleResponse(response);
    return (data['messages'] as List)
        .map((message) => Message.fromJson(message))
        .toList();
  }

  Future<Message> sendPrivateMessage({
    required String chatId,
    required String content,
    String messageType = 'text',
    String? replyTo,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/private-chat/$chatId/messages'),
      headers: _headers,
      body: json.encode({
        'content': content,
        'messageType': messageType,
        'replyTo': replyTo,
      }),
    );

    final data = _handleResponse(response);
    return Message.fromJson(data['messageData']);
  }

  Future<void> markPrivateChatAsRead({
    required String chatId,
    String? messageId,
  }) async {
    final body = <String, dynamic>{};
    if (messageId != null) body['messageId'] = messageId;

    final response = await http.post(
      Uri.parse('$baseUrl/private-chat/$chatId/read'),
      headers: _headers,
      body: json.encode(body),
    );

    _handleResponse(response);
  }

  Future<PrivateChat> getPrivateChatDetails(String chatId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/private-chat/$chatId'),
      headers: _headers,
    );

    final data = _handleResponse(response);
    return PrivateChat.fromJson(data['privateChat']);
  }

  Future<void> deletePrivateChat(String chatId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/private-chat/$chatId'),
      headers: _headers,
    );

    _handleResponse(response);
  }
}

class AuthResult {
  final User user;
  final String token;

  AuthResult({required this.user, required this.token});
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
