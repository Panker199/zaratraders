class AuditLog {
  final String id;
  final String userId;
  final String userName;
  final String action;
  final String entityName;
  final String entityId;
  final String description;
  final DateTime createdAt;

  AuditLog({
    required this.id, required this.userId, this.userName = '',
    required this.action, required this.entityName, required this.entityId,
    this.description = '', DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AuditLog.fromFirestore(String id, Map<String, dynamic> data) => AuditLog(
    id: id,
    userId: data['userId'] as String? ?? '',
    userName: data['userName'] as String? ?? '',
    action: data['action'] as String? ?? '',
    entityName: data['entityName'] as String? ?? '',
    entityId: data['entityId'] as String? ?? '',
    description: data['description'] as String? ?? '',
    createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toFirestore() => {
    'userId': userId, 'userName': userName, 'action': action,
    'entityName': entityName, 'entityId': entityId, 'description': description, 'createdAt': createdAt,
  };
}
