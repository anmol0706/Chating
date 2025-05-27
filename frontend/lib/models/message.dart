import 'user.dart';

class MessageReadBy {
  final User user;
  final DateTime readAt;

  MessageReadBy({
    required this.user,
    required this.readAt,
  });

  factory MessageReadBy.fromJson(Map<String, dynamic> json) {
    return MessageReadBy(
      user: User.fromJson(json['user']),
      readAt: DateTime.parse(json['readAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'readAt': readAt.toIso8601String(),
    };
  }
}

class Message {
  final String id;
  final String content;
  final User sender;
  final String chatRoom;
  final String messageType;
  final String deliveryStatus;
  final List<MessageReadBy>? readBy;
  final DateTime? editedAt;
  final bool isEdited;
  final Message? replyTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Message({
    required this.id,
    required this.content,
    required this.sender,
    required this.chatRoom,
    this.messageType = 'text',
    this.deliveryStatus = 'sent',
    this.readBy,
    this.editedAt,
    this.isEdited = false,
    this.replyTo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? json['id'] ?? '',
      content: json['content'] ?? '',
      sender: User.fromJson(json['sender']),
      chatRoom: json['chatRoom'] ?? '',
      messageType: json['messageType'] ?? 'text',
      deliveryStatus: json['deliveryStatus'] ?? 'sent',
      readBy: (json['readBy'] as List<dynamic>?)
          ?.map((r) => MessageReadBy.fromJson(r))
          .toList(),
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'])
          : null,
      isEdited: json['isEdited'] ?? false,
      replyTo: json['replyTo'] != null
          ? Message.fromJson(json['replyTo'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'content': content,
      'sender': sender.toJson(),
      'chatRoom': chatRoom,
      'messageType': messageType,
      'deliveryStatus': deliveryStatus,
      'readBy': readBy?.map((r) => r.toJson()).toList(),
      'editedAt': editedAt?.toIso8601String(),
      'isEdited': isEdited,
      'replyTo': replyTo?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isRead => deliveryStatus == 'read';
  bool get isDelivered => deliveryStatus == 'delivered' || isRead;
  bool get isSent => deliveryStatus == 'sent' || isDelivered;

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get timeOnly {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool isReadBy(String userId) {
    return readBy?.any((r) => r.user.id == userId) ?? false;
  }

  Message copyWith({
    String? id,
    String? content,
    User? sender,
    String? chatRoom,
    String? messageType,
    String? deliveryStatus,
    List<MessageReadBy>? readBy,
    DateTime? editedAt,
    bool? isEdited,
    Message? replyTo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      sender: sender ?? this.sender,
      chatRoom: chatRoom ?? this.chatRoom,
      messageType: messageType ?? this.messageType,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      readBy: readBy ?? this.readBy,
      editedAt: editedAt ?? this.editedAt,
      isEdited: isEdited ?? this.isEdited,
      replyTo: replyTo ?? this.replyTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Message(id: $id, content: $content, sender: ${sender.username})';
  }
}
