import 'package:flutter/widgets.dart';
import '../models/user.dart';
import '../models/friend_request.dart';
import '../models/private_chat.dart';
import '../services/api_service.dart';

class FriendProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<User> _friends = [];
  List<FriendRequest> _receivedRequests = [];
  List<FriendRequest> _sentRequests = [];
  List<PrivateChat> _privateChats = [];

  bool _isLoading = false;
  String? _error;

  // Getters
  List<User> get friends => _friends;
  List<FriendRequest> get receivedRequests => _receivedRequests;
  List<FriendRequest> get sentRequests => _sentRequests;
  List<PrivateChat> get privateChats => _privateChats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get pending received requests count
  int get pendingReceivedRequestsCount =>
      _receivedRequests.where((req) => req.isPending).length;

  // Get pending sent requests count
  int get pendingSentRequestsCount =>
      _sentRequests.where((req) => req.isPending).length;

  // Get total unread private messages count
  int get totalUnreadMessagesCount =>
      _privateChats.fold(0, (sum, chat) => sum + (chat.unreadCount ?? 0));

  void _setLoading(bool loading) {
    _isLoading = loading;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void _setError(String? error) {
    _error = error;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Load friends list
  Future<void> loadFriends({String? search}) async {
    try {
      _setLoading(true);
      _setError(null);

      _friends = await _apiService.getFriendsList(search: search);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _setError('Failed to load friends: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load friend requests
  Future<void> loadFriendRequests() async {
    try {
      _setLoading(true);
      _setError(null);

      final receivedFuture = _apiService.getReceivedFriendRequests();
      final sentFuture = _apiService.getSentFriendRequests();

      final results = await Future.wait([receivedFuture, sentFuture]);
      _receivedRequests = results[0];
      _sentRequests = results[1];

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _setError('Failed to load friend requests: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load private chats
  Future<void> loadPrivateChats() async {
    try {
      _setLoading(true);
      _setError(null);

      _privateChats = await _apiService.getUserPrivateChats();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _setError('Failed to load private chats: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Send friend request
  Future<bool> sendFriendRequest(String receiverId, {String message = ''}) async {
    try {
      _setError(null);

      final friendRequest = await _apiService.sendFriendRequest(
        receiverId: receiverId,
        message: message,
      );

      _sentRequests.insert(0, friendRequest);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      return true;
    } catch (e) {
      _setError('Failed to send friend request: $e');
      return false;
    }
  }

  // Accept friend request
  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      _setError(null);

      final updatedRequest = await _apiService.acceptFriendRequest(requestId);

      // Update the request in the list
      final index = _receivedRequests.indexWhere((req) => req.id == requestId);
      if (index != -1) {
        _receivedRequests[index] = updatedRequest;
      }

      // Refresh friends list and private chats
      await loadFriends();
      await loadPrivateChats();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return true;
    } catch (e) {
      _setError('Failed to accept friend request: $e');
      return false;
    }
  }

  // Decline friend request
  Future<bool> declineFriendRequest(String requestId) async {
    try {
      _setError(null);

      final updatedRequest = await _apiService.declineFriendRequest(requestId);

      // Update the request in the list
      final index = _receivedRequests.indexWhere((req) => req.id == requestId);
      if (index != -1) {
        _receivedRequests[index] = updatedRequest;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return true;
    } catch (e) {
      _setError('Failed to decline friend request: $e');
      return false;
    }
  }

  // Cancel friend request
  Future<bool> cancelFriendRequest(String requestId) async {
    try {
      _setError(null);

      final updatedRequest = await _apiService.cancelFriendRequest(requestId);

      // Update the request in the list
      final index = _sentRequests.indexWhere((req) => req.id == requestId);
      if (index != -1) {
        _sentRequests[index] = updatedRequest;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return true;
    } catch (e) {
      _setError('Failed to cancel friend request: $e');
      return false;
    }
  }

  // Remove friend
  Future<bool> removeFriend(String friendId) async {
    try {
      _setError(null);

      await _apiService.removeFriend(friendId);

      // Remove from friends list
      _friends.removeWhere((friend) => friend.id == friendId);

      // Remove associated private chat
      _privateChats.removeWhere((chat) =>
          chat.participants.any((p) => p.id == friendId));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return true;
    } catch (e) {
      _setError('Failed to remove friend: $e');
      return false;
    }
  }

  // Get or create private chat
  Future<PrivateChat?> getOrCreatePrivateChat(String friendId) async {
    try {
      _setError(null);

      final privateChat = await _apiService.getOrCreatePrivateChat(friendId);

      // Update private chats list if not already present
      final existingIndex = _privateChats.indexWhere((chat) => chat.id == privateChat.id);
      if (existingIndex == -1) {
        _privateChats.insert(0, privateChat);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }

      return privateChat;
    } catch (e) {
      _setError('Failed to create private chat: $e');
      return null;
    }
  }

  // Update private chat (for real-time updates)
  void updatePrivateChat(PrivateChat updatedChat) {
    final index = _privateChats.indexWhere((chat) => chat.id == updatedChat.id);
    if (index != -1) {
      _privateChats[index] = updatedChat;
      // Move to top of list
      _privateChats.removeAt(index);
      _privateChats.insert(0, updatedChat);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Add new friend request (for real-time updates)
  void addReceivedFriendRequest(FriendRequest request) {
    _receivedRequests.insert(0, request);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Update friend request status (for real-time updates)
  void updateFriendRequestStatus(String requestId, String status) {
    // Update in received requests
    final receivedIndex = _receivedRequests.indexWhere((req) => req.id == requestId);
    if (receivedIndex != -1) {
      _receivedRequests[receivedIndex] = _receivedRequests[receivedIndex].copyWith(
        status: status,
        respondedAt: DateTime.now(),
      );
    }

    // Update in sent requests
    final sentIndex = _sentRequests.indexWhere((req) => req.id == requestId);
    if (sentIndex != -1) {
      _sentRequests[sentIndex] = _sentRequests[sentIndex].copyWith(
        status: status,
        respondedAt: DateTime.now(),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Check if user is a friend
  bool isFriend(String userId) {
    return _friends.any((friend) => friend.id == userId);
  }

  // Check if friend request exists
  bool hasPendingFriendRequest(String userId) {
    return _sentRequests.any((req) =>
        req.receiver.id == userId && req.isPending) ||
           _receivedRequests.any((req) =>
        req.sender.id == userId && req.isPending);
  }

  // Get friend request status with user
  String? getFriendRequestStatus(String userId) {
    // Check sent requests
    try {
      _sentRequests.firstWhere(
        (req) => req.receiver.id == userId && req.isPending,
      );
      return 'sent';
    } catch (e) {
      // No matching sent request found
    }

    // Check received requests
    try {
      _receivedRequests.firstWhere(
        (req) => req.sender.id == userId && req.isPending,
      );
      return 'received';
    } catch (e) {
      // No matching received request found
    }

    return null;
  }

  // Clear all data (for logout)
  void clear() {
    _friends.clear();
    _receivedRequests.clear();
    _sentRequests.clear();
    _privateChats.clear();
    _error = null;
    _isLoading = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
