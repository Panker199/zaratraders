class Purchase {
  final String id;
  final String supplierId;
  final String supplierName;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String createdBy;
  final DateTime createdAt;

  Purchase({
    required this.id, required this.supplierId, this.supplierName = '',
    required this.totalAmount, this.paidAmount = 0, this.remainingAmount = 0,
    this.createdBy = '', DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Purchase.fromFirestore(String id, Map<String, dynamic> data) => Purchase(
    id: id,
    supplierId: data['supplierId'] as String? ?? '',
    supplierName: data['supplierName'] as String? ?? '',
    totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
    paidAmount: (data['paidAmount'] as num?)?.toDouble() ?? 0,
    remainingAmount: (data['remainingAmount'] as num?)?.toDouble() ?? 0,
    createdBy: data['createdBy'] as String? ?? '',
    createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toFirestore() => {
    'supplierId': supplierId, 'supplierName': supplierName,
    'totalAmount': totalAmount, 'paidAmount': paidAmount,
    'remainingAmount': remainingAmount, 'createdBy': createdBy, 'createdAt': createdAt,
  };
}

class PurchaseItem {
  final String id;
  final String purchaseId;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const PurchaseItem({
    required this.id, required this.purchaseId, required this.productId,
    this.productName = '', required this.quantity, required this.unitPrice, required this.totalPrice,
  });

  factory PurchaseItem.fromFirestore(String id, Map<String, dynamic> data) => PurchaseItem(
    id: id,
    purchaseId: data['purchaseId'] as String? ?? '',
    productId: data['productId'] as String? ?? '',
    productName: data['productName'] as String? ?? '',
    quantity: (data['quantity'] as num?)?.toInt() ?? 0,
    unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0,
    totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toFirestore() => {
    'purchaseId': purchaseId, 'productId': productId, 'productName': productName,
    'quantity': quantity, 'unitPrice': unitPrice, 'totalPrice': totalPrice,
  };
}
