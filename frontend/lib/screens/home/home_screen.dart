import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/friend_provider.dart';
import '../chat/chat_list_screen.dart';
import '../chat/private_chat_list_screen.dart';
import '../profile/profile_screen.dart';
import '../users/users_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ChatListScreen(),
    const PrivateChatListScreen(),
    const UsersScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);

    await Future.wait([
      chatProvider.initialize(),
      friendProvider.loadFriends(),
      friendProvider.loadFriendRequests(),
      friendProvider.loadPrivateChats(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.forum_outlined),
            activeIcon: Icon(Icons.forum),
            label: 'Rooms',
          ),
          BottomNavigationBarItem(
            icon: Consumer<FriendProvider>(
              builder: (context, friendProvider, child) {
                final unreadCount = friendProvider.totalUnreadMessagesCount;
                return Stack(
                  children: [
                    const Icon(Icons.chat_bubble_outline),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            activeIcon: Consumer<FriendProvider>(
              builder: (context, friendProvider, child) {
                final unreadCount = friendProvider.totalUnreadMessagesCount;
                return Stack(
                  children: [
                    const Icon(Icons.chat_bubble),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Consumer<FriendProvider>(
              builder: (context, friendProvider, child) {
                final requestCount = friendProvider.pendingReceivedRequestsCount;
                return Stack(
                  children: [
                    const Icon(Icons.people_outline),
                    if (requestCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            requestCount > 99 ? '99+' : requestCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            activeIcon: Consumer<FriendProvider>(
              builder: (context, friendProvider, child) {
                final requestCount = friendProvider.pendingReceivedRequestsCount;
                return Stack(
                  children: [
                    const Icon(Icons.people),
                    if (requestCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            requestCount > 99 ? '99+' : requestCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'Friends',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
