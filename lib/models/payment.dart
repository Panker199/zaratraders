class Payment {
  final String id;
  final double amount;
  final String customerId;
  final String supplierId;
  final String method;
  final String referenceNo;
  final String createdBy;
  final DateTime createdAt;

  Payment({
    required this.id, required this.amount, this.customerId = '', this.supplierId = '',
    required this.method, this.referenceNo = '', this.createdBy = '', DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Payment.fromFirestore(String id, Map<String, dynamic> data) => Payment(
    id: id,
    amount: (data['amount'] as num?)?.toDouble() ?? 0,
    customerId: data['customerId'] as String? ?? '',
    supplierId: data['supplierId'] as String? ?? '',
    method: data['method'] as String? ?? '',
    referenceNo: data['referenceNo'] as String? ?? '',
    createdBy: data['createdBy'] as String? ?? '',
    createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toFirestore() => {
    'amount': amount, 'customerId': customerId, 'supplierId': supplierId,
    'method': method, 'referenceNo': referenceNo, 'createdBy': createdBy, 'createdAt': createdAt,
  };
}
