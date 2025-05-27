import 'user.dart';
import 'message.dart';

class ChatRoomParticipant {
  final User user;
  final DateTime joinedAt;
  final String role;

  ChatRoomParticipant({
    required this.user,
    required this.joinedAt,
    this.role = 'member',
  });

  factory ChatRoomParticipant.fromJson(Map<String, dynamic> json) {
    return ChatRoomParticipant(
      user: User.fromJson(json['user']),
      joinedAt: DateTime.parse(json['joinedAt']),
      role: json['role'] ?? 'member',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'joinedAt': joinedAt.toIso8601String(),
      'role': role,
    };
  }
}

class ChatRoom {
  final String id;
  final String name;
  final String description;
  final String type;
  final List<ChatRoomParticipant> participants;
  final User createdBy;
  final Message? lastMessage;
  final DateTime lastActivity;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatRoom({
    required this.id,
    required this.name,
    this.description = '',
    this.type = 'public',
    required this.participants,
    required this.createdBy,
    this.lastMessage,
    required this.lastActivity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'public',
      participants: (json['participants'] as List<dynamic>?)
          ?.map((p) => ChatRoomParticipant.fromJson(p))
          .toList() ?? [],
      createdBy: User.fromJson(json['createdBy']),
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'])
          : null,
      lastActivity: DateTime.parse(json['lastActivity']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'type': type,
      'participants': participants.map((p) => p.toJson()).toList(),
      'createdBy': createdBy.toJson(),
      'lastMessage': lastMessage?.toJson(),
      'lastActivity': lastActivity.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  int get participantCount => participants.length;

  bool isParticipant(String userId) {
    return participants.any((p) => p.user.id == userId);
  }

  List<User> get onlineParticipants {
    return participants
        .where((p) => p.user.isOnline)
        .map((p) => p.user)
        .toList();
  }

  ChatRoom copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    List<ChatRoomParticipant>? participants,
    User? createdBy,
    Message? lastMessage,
    DateTime? lastActivity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      createdBy: createdBy ?? this.createdBy,
      lastMessage: lastMessage ?? this.lastMessage,
      lastActivity: lastActivity ?? this.lastActivity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatRoom && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatRoom(id: $id, name: $name, participantCount: $participantCount)';
  }
}
