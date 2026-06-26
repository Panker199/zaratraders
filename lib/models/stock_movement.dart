class StockMovement {
  final String id;
  final String productId;
  final String productName;
  final String transactionType;
  final int quantity;
  final int stockBefore;
  final int stockAfter;
  final String referenceId;
  final String performedBy;
  final DateTime createdAt;

  StockMovement({
    required this.id, required this.productId, this.productName = '',
    required this.transactionType, required this.quantity,
    required this.stockBefore, required this.stockAfter,
    this.referenceId = '', this.performedBy = '', DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory StockMovement.fromFirestore(String id, Map<String, dynamic> data) => StockMovement(
    id: id,
    productId: data['productId'] as String? ?? '',
    productName: data['productName'] as String? ?? '',
    transactionType: data['transactionType'] as String? ?? '',
    quantity: (data['quantity'] as num?)?.toInt() ?? 0,
    stockBefore: (data['stockBefore'] as num?)?.toInt() ?? 0,
    stockAfter: (data['stockAfter'] as num?)?.toInt() ?? 0,
    referenceId: data['referenceId'] as String? ?? '',
    performedBy: data['performedBy'] as String? ?? '',
    createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toFirestore() => {
    'productId': productId, 'productName': productName, 'transactionType': transactionType,
    'quantity': quantity, 'stockBefore': stockBefore, 'stockAfter': stockAfter,
    'referenceId': referenceId, 'performedBy': performedBy, 'createdAt': createdAt,
  };
}
