class User {
  final String id;
  final String email;
  final String username;
  final String? fullName;
  final bool notificationsEnabled;
  final String themeMode;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    required this.notificationsEnabled,
    required this.themeMode,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        username: json['username'] as String,
        fullName: json['full_name'] as String?,
        notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
        themeMode: json['theme_mode'] as String? ?? 'light',
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'full_name': fullName,
        'notifications_enabled': notificationsEnabled,
        'theme_mode': themeMode,
        'created_at': createdAt.toIso8601String(),
      };

  String get displayName => fullName?.isNotEmpty == true ? fullName! : username;

  String get initials {
    final name = displayName;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  User copyWith({
    String? fullName,
    bool? notificationsEnabled,
    String? themeMode,
  }) =>
      User(
        id: id,
        email: email,
        username: username,
        fullName: fullName ?? this.fullName,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        themeMode: themeMode ?? this.themeMode,
        createdAt: createdAt,
      );
}
