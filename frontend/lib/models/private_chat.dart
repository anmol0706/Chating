import 'user.dart';
import 'message.dart';

class ReadStatus {
  final User user;
  final Message? lastReadMessage;
  final DateTime lastReadAt;

  ReadStatus({
    required this.user,
    this.lastReadMessage,
    required this.lastReadAt,
  });

  factory ReadStatus.fromJson(Map<String, dynamic> json) {
    return ReadStatus(
      user: User.fromJson(json['user']),
      lastReadMessage: json['lastReadMessage'] != null
          ? Message.fromJson(json['lastReadMessage'])
          : null,
      lastReadAt: DateTime.parse(json['lastReadAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'lastReadMessage': lastReadMessage?.toJson(),
      'lastReadAt': lastReadAt.toIso8601String(),
    };
  }
}

class PrivateChat {
  final String id;
  final List<User> participants;
  final Message? lastMessage;
  final DateTime lastActivity;
  final bool isActive;
  final List<ReadStatus> readStatus;
  final User createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? unreadCount;
  final User? otherParticipant;

  PrivateChat({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.lastActivity,
    this.isActive = true,
    required this.readStatus,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.unreadCount,
    this.otherParticipant,
  });

  factory PrivateChat.fromJson(Map<String, dynamic> json) {
    return PrivateChat(
      id: json['_id'] ?? json['id'] ?? '',
      participants: (json['participants'] as List)
          .map((participant) => User.fromJson(participant))
          .toList(),
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'])
          : null,
      lastActivity: DateTime.parse(json['lastActivity']),
      isActive: json['isActive'] ?? true,
      readStatus: (json['readStatus'] as List? ?? [])
          .map((status) => ReadStatus.fromJson(status))
          .toList(),
      createdBy: User.fromJson(json['metadata']['createdBy']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      unreadCount: json['unreadCount'],
      otherParticipant: json['otherParticipant'] != null
          ? User.fromJson(json['otherParticipant'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'participants': participants.map((p) => p.toJson()).toList(),
      'lastMessage': lastMessage?.toJson(),
      'lastActivity': lastActivity.toIso8601String(),
      'isActive': isActive,
      'readStatus': readStatus.map((rs) => rs.toJson()).toList(),
      'metadata': {
        'createdBy': createdBy.toJson(),
      },
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'unreadCount': unreadCount,
      'otherParticipant': otherParticipant?.toJson(),
    };
  }

  PrivateChat copyWith({
    String? id,
    List<User>? participants,
    Message? lastMessage,
    DateTime? lastActivity,
    bool? isActive,
    List<ReadStatus>? readStatus,
    User? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? unreadCount,
    User? otherParticipant,
  }) {
    return PrivateChat(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastActivity: lastActivity ?? this.lastActivity,
      isActive: isActive ?? this.isActive,
      readStatus: readStatus ?? this.readStatus,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      otherParticipant: otherParticipant ?? this.otherParticipant,
    );
  }

  // Get the other participant in the chat (not the current user)
  User? getOtherParticipant(String currentUserId) {
    if (otherParticipant != null) return otherParticipant;

    try {
      return participants.firstWhere(
        (participant) => participant.id != currentUserId,
      );
    } catch (e) {
      // If no other participant found, return the first one or null
      return participants.isNotEmpty ? participants.first : null;
    }
  }

  // Get display name for the chat (other participant's name)
  String getDisplayName(String currentUserId) {
    final other = getOtherParticipant(currentUserId);
    return other?.username ?? 'Unknown User';
  }

  // Get display picture for the chat (other participant's picture)
  String getDisplayPicture(String currentUserId) {
    final other = getOtherParticipant(currentUserId);
    return other?.profilePicture ?? '';
  }

  // Check if the other participant is online
  bool isOtherParticipantOnline(String currentUserId) {
    final other = getOtherParticipant(currentUserId);
    return other?.isOnline ?? false;
  }

  // Get last seen of the other participant
  DateTime? getOtherParticipantLastSeen(String currentUserId) {
    final other = getOtherParticipant(currentUserId);
    return other?.lastSeen;
  }

  // Get formatted last activity time
  String getFormattedLastActivity() {
    final now = DateTime.now();
    final difference = now.difference(lastActivity);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastActivity.day}/${lastActivity.month}/${lastActivity.year}';
    }
  }

  // Get last message preview
  String getLastMessagePreview() {
    if (lastMessage == null) return 'No messages yet';

    String preview = lastMessage!.content;
    if (preview.length > 50) {
      preview = '${preview.substring(0, 50)}...';
    }

    return preview;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrivateChat && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PrivateChat(id: $id, participants: ${participants.length}, isActive: $isActive)';
  }
}
