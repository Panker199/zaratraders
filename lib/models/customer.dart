class Customer {
  final String id;
  final String name;
  final String phoneNumber;
  final String email;
  final String address;
  final double balance;
  final DateTime createdAt;

  Customer({
    required this.id, required this.name, this.phoneNumber = '', this.email = '',
    this.address = '', this.balance = 0, DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Customer.fromFirestore(String id, Map<String, dynamic> data) => Customer(
    id: id,
    name: data['name'] as String? ?? '',
    phoneNumber: data['phoneNumber'] as String? ?? '',
    email: data['email'] as String? ?? '',
    address: data['address'] as String? ?? '',
    balance: (data['balance'] as num?)?.toDouble() ?? 0,
    createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toFirestore() => {
    'name': name, 'phoneNumber': phoneNumber, 'email': email,
    'address': address, 'balance': balance, 'createdAt': createdAt,
  };
}
