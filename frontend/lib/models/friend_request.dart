import 'user.dart';

class FriendRequest {
  final String id;
  final User sender;
  final User receiver;
  final String status;
  final String message;
  final DateTime? respondedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  FriendRequest({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.status,
    this.message = '',
    this.respondedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['_id'] ?? json['id'] ?? '',
      sender: User.fromJson(json['sender']),
      receiver: User.fromJson(json['receiver']),
      status: json['status'] ?? 'pending',
      message: json['message'] ?? '',
      respondedAt: json['respondedAt'] != null 
          ? DateTime.parse(json['respondedAt']) 
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sender': sender.toJson(),
      'receiver': receiver.toJson(),
      'status': status,
      'message': message,
      'respondedAt': respondedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  FriendRequest copyWith({
    String? id,
    User? sender,
    User? receiver,
    String? status,
    String? message,
    DateTime? respondedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      status: status ?? this.status,
      message: message ?? this.message,
      respondedAt: respondedAt ?? this.respondedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
  bool get isCancelled => status == 'cancelled';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FriendRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FriendRequest(id: $id, sender: ${sender.username}, receiver: ${receiver.username}, status: $status)';
  }
}
