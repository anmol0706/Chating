class User {
  final String id;
  final String username;
  final String email;
  final String profilePicture;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? createdAt;
  final List<String>? joinedRooms;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profilePicture = '',
    this.isOnline = false,
    this.lastSeen,
    this.createdAt,
    this.joinedRooms,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profilePicture: json['profilePicture'] ?? '',
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      joinedRooms: json['joinedRooms'] != null
          ? List<String>.from(json['joinedRooms'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
      'profilePicture': profilePicture,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'joinedRooms': joinedRooms,
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? profilePicture,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
    List<String>? joinedRooms,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      joinedRooms: joinedRooms ?? this.joinedRooms,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, isOnline: $isOnline)';
  }
}
