enum StorageType { webdav, smb, ftp, nfs, usb }

enum NodeCategory { normal, private }

class StorageNode {
  final String id;
  final String name;
  final StorageType type;
  final String baseUrl;
  final String? username;
  final String? password;
  final bool isAnonymous;
  final NodeCategory category;
  final int sortOrder;
  final DateTime? lastConnected;

  StorageNode({
    required this.id,
    required this.name,
    required this.type,
    required this.baseUrl,
    this.username,
    this.password,
    this.isAnonymous = false,
    this.category = NodeCategory.normal,
    this.sortOrder = 0,
    this.lastConnected,
  });

  bool get isPrivate => category == NodeCategory.private;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'baseUrl': baseUrl,
      'username': username,
      'isAnonymous': isAnonymous,
      'category': category.name,
      'sortOrder': sortOrder,
      'lastConnected': lastConnected?.toIso8601String(),
    };
  }

  factory StorageNode.fromJson(Map<String, dynamic> json) {
    return StorageNode(
      id: json['id'] as String,
      name: json['name'] as String,
      type: StorageType.values.byName(json['type'] as String),
      baseUrl: json['baseUrl'] as String,
      username: json['username'] as String?,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      category: NodeCategory.values.byName(json['category'] as String? ?? 'normal'),
      sortOrder: json['sortOrder'] as int? ?? 0,
      lastConnected: json['lastConnected'] != null
          ? DateTime.parse(json['lastConnected'] as String)
          : null,
    );
  }

  StorageNode copyWith({
    String? id,
    String? name,
    StorageType? type,
    String? baseUrl,
    String? username,
    String? password,
    bool? isAnonymous,
    NodeCategory? category,
    int? sortOrder,
    DateTime? lastConnected,
  }) {
    return StorageNode(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      baseUrl: baseUrl ?? this.baseUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      category: category ?? this.category,
      sortOrder: sortOrder ?? this.sortOrder,
      lastConnected: lastConnected ?? this.lastConnected,
    );
  }
}

class FavoriteNode {
  final String id;
  final String name;
  final String sourceNodeId;
  final String path;
  final String? posterUrl;
  final int sortOrder;

  FavoriteNode({
    required this.id,
    required this.name,
    required this.sourceNodeId,
    required this.path,
    this.posterUrl,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sourceNodeId': sourceNodeId,
      'path': path,
      'posterUrl': posterUrl,
      'sortOrder': sortOrder,
    };
  }

  factory FavoriteNode.fromJson(Map<String, dynamic> json) {
    return FavoriteNode(
      id: json['id'] as String,
      name: json['name'] as String,
      sourceNodeId: json['sourceNodeId'] as String,
      path: json['path'] as String,
      posterUrl: json['posterUrl'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}
