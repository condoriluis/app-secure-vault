enum VaultType { login, creditCard, secureNote, identity, totp }

class VaultEntry {
  final String id;
  final String title;
  final VaultType type;
  final String? username;
  final String? password;
  final String? notes;
  final String? category;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  VaultEntry({
    required this.id,
    required this.title,
    this.type = VaultType.login,
    this.username,
    this.password,
    this.notes,
    this.category,
    this.data = const {},
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  VaultEntry copyWith({
    String? title,
    VaultType? type,
    String? username,
    String? password,
    String? notes,
    String? category,
    Map<String, dynamic>? data,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool removeDeletedAt = false,
  }) {
    return VaultEntry(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      username: username ?? this.username,
      password: password ?? this.password,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      data: data ?? this.data,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: removeDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'username': username,
      'password': password,
      'notes': notes,
      'category': category,
      'data': data,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'deletedAt': deletedAt?.millisecondsSinceEpoch,
    };
  }

  factory VaultEntry.fromJson(Map<String, dynamic> json) {
    return VaultEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      type: VaultType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => VaultType.login,
      ),
      username: json['username'] as String?,
      password: json['password'] as String?,
      notes: json['notes'] as String?,
      category: json['category'] as String?,
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
      deletedAt: json['deletedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['deletedAt'] as int)
          : null,
    );
  }
}
