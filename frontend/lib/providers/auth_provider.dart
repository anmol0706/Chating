import 'package:flutter/widgets.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Initialize the provider
  Future<void> initialize() async {
    try {
      await _apiService.initialize();
      _currentUser = _apiService.currentUser;

      if (_currentUser != null) {
        await _connectSocket();
      }
    } catch (e) {
      _setError('Failed to initialize: ${e.toString()}');
    }

    // Set loading to false after initialization using post frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setLoading(false);
    });
  }

  // Register new user
  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _apiService.register(
        username: username,
        email: email,
        password: password,
      );

      _currentUser = result.user;
      await _connectSocket();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  // Login user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _apiService.login(
        email: email,
        password: password,
      );

      _currentUser = result.user;
      await _connectSocket();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    _setLoading(true);

    try {
      _socketService.disconnect();
      await _apiService.logout();
      _currentUser = null;
    } catch (e) {
      // Continue with logout even if API call fails
      _currentUser = null;
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? username,
    String? profilePicture,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedUser = await _apiService.updateProfile(
        username: username,
        profilePicture: profilePicture,
      );

      _currentUser = updatedUser;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  // Connect to socket server
  Future<void> _connectSocket() async {
    try {
      await _socketService.connect();
    } catch (e) {
      // Failed to connect to socket: $e
      // Don't throw error as this shouldn't prevent login
    }
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
    _socketService.dispose();
    super.dispose();
  }
}
