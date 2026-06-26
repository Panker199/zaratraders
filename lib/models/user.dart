enum UserRole { admin, shopkeeper }

class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;

  String get name => '$firstName $lastName';

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone = '',
    required this.role,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toFirestore() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'role': role.name,
    'isActive': isActive,
    'createdAt': createdAt,
  };

  factory User.fromFirestore(String id, Map<String, dynamic> data) {
    return User(
      id: id,
      firstName: data['firstName'] as String? ?? data['name'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == data['role'] as String?,
        orElse: () => UserRole.shopkeeper,
      ),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}
