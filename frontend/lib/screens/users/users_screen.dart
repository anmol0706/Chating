import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<User> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);
    await Future.wait([
      friendProvider.loadFriends(),
      friendProvider.loadFriendRequests(),
    ]);
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _searchQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    try {
      final users = await _apiService.getUsers(search: query);
      final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;

      // Filter out current user
      final filteredUsers = users.where((user) => user.id != currentUser?.id).toList();

      if (mounted) {
        setState(() {
          _searchResults = filteredUsers;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Friends'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Search', icon: Icon(Icons.search)),
            Tab(text: 'Friends', icon: Icon(Icons.people)),
            Tab(text: 'Requests', icon: Icon(Icons.person_add)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildFriendsTab(),
          _buildRequestsTab(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users by username or email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchUsers('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _searchUsers,
          ),
        ),
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty && _searchQuery.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No users found',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try searching with different keywords',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : _searchQuery.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Search for users',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enter a username or email to find friends',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            return SearchUserTile(user: user);
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildFriendsTab() {
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, child) {
        if (friendProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (friendProvider.friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No friends yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Search for users and send friend requests',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(0),
                  child: const Text('Search Users'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => friendProvider.loadFriends(),
          child: ListView.builder(
            itemCount: friendProvider.friends.length,
            itemBuilder: (context, index) {
              final friend = friendProvider.friends[index];
              return FriendTile(user: friend);
            },
          ),
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, child) {
        if (friendProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(
                    text: 'Received (${friendProvider.pendingReceivedRequestsCount})',
                  ),
                  Tab(
                    text: 'Sent (${friendProvider.pendingSentRequestsCount})',
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildReceivedRequestsList(friendProvider),
                    _buildSentRequestsList(friendProvider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceivedRequestsList(FriendProvider friendProvider) {
    final pendingRequests = friendProvider.receivedRequests
        .where((req) => req.isPending)
        .toList();

    if (pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No friend requests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Friend requests will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: pendingRequests.length,
      itemBuilder: (context, index) {
        final request = pendingRequests[index];
        return ReceivedRequestTile(request: request);
      },
    );
  }

  Widget _buildSentRequestsList(FriendProvider friendProvider) {
    final pendingRequests = friendProvider.sentRequests
        .where((req) => req.isPending)
        .toList();

    if (pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.send_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No sent requests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Sent friend requests will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: pendingRequests.length,
      itemBuilder: (context, index) {
        final request = pendingRequests[index];
        return SentRequestTile(request: request);
      },
    );
  }
}

class SearchUserTile extends StatelessWidget {
  final User user;

  const SearchUserTile({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, child) {
        final isFriend = friendProvider.isFriend(user.id);
        final requestStatus = friendProvider.getFriendRequestStatus(user.id);

        return ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: user.profilePicture.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          user.profilePicture,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Text(
                              user.username[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      )
                    : Text(
                        user.username[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              if (user.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
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
          title: Text(
            user.username,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            user.isOnline ? 'Online' : 'Last seen ${_formatLastSeen(user.lastSeen)}',
            style: TextStyle(
              color: user.isOnline ? Colors.green : Colors.grey[600],
            ),
          ),
          trailing: _buildActionButton(context, friendProvider, isFriend, requestStatus),
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context, FriendProvider friendProvider,
      bool isFriend, String? requestStatus) {
    if (isFriend) {
      return ElevatedButton.icon(
        onPressed: () async {
          // Navigate to private chat
          final privateChat = await friendProvider.getOrCreatePrivateChat(user.id);
          if (privateChat != null && context.mounted) {
            Navigator.pushNamed(context, '/private-chat', arguments: privateChat);
          }
        },
        icon: const Icon(Icons.message, size: 16),
        label: const Text('Message'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      );
    }

    if (requestStatus == 'sent') {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          foregroundColor: Colors.white,
        ),
        child: const Text('Sent'),
      );
    }

    if (requestStatus == 'received') {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        child: const Text('Pending'),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _sendFriendRequest(context, friendProvider),
      icon: const Icon(Icons.person_add, size: 16),
      label: const Text('Add'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _sendFriendRequest(BuildContext context, FriendProvider friendProvider) async {
    final success = await friendProvider.sendFriendRequest(user.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Friend request sent to ${user.username}'
              : 'Failed to send friend request'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
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

// Placeholder classes - these will be implemented in separate files
class FriendTile extends StatelessWidget {
  final User user;
  const FriendTile({super.key, required this.user});
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class ReceivedRequestTile extends StatelessWidget {
  final dynamic request;
  const ReceivedRequestTile({super.key, required this.request});
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class SentRequestTile extends StatelessWidget {
  final dynamic request;
  const SentRequestTile({super.key, required this.request});
  @override
  Widget build(BuildContext context) => const SizedBox();
}
