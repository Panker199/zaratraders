class Sale {
  final String id;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final String salesmanId;
  final double totalAmount;
  final double discount;
  final double tax;
  final double finalAmount;
  final double paidAmount;
  final double remainingAmount;
  final DateTime createdAt;

  Sale({
    required this.id, required this.invoiceNumber, this.customerId = '', this.customerName = '',
    this.salesmanId = '', required this.totalAmount, this.discount = 0, this.tax = 0,
    required this.finalAmount, this.paidAmount = 0, this.remainingAmount = 0, DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Sale.fromFirestore(String id, Map<String, dynamic> data) => Sale(
    id: id,
    invoiceNumber: data['invoiceNumber'] as String? ?? '',
    customerId: data['customerId'] as String? ?? '',
    customerName: data['customerName'] as String? ?? '',
    salesmanId: data['salesmanId'] as String? ?? '',
    totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
    discount: (data['discount'] as num?)?.toDouble() ?? 0,
    tax: (data['tax'] as num?)?.toDouble() ?? 0,
    finalAmount: (data['finalAmount'] as num?)?.toDouble() ?? 0,
    paidAmount: (data['paidAmount'] as num?)?.toDouble() ?? 0,
    remainingAmount: (data['remainingAmount'] as num?)?.toDouble() ?? 0,
    createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toFirestore() => {
    'invoiceNumber': invoiceNumber, 'customerId': customerId, 'customerName': customerName,
    'salesmanId': salesmanId, 'totalAmount': totalAmount, 'discount': discount,
    'tax': tax, 'finalAmount': finalAmount, 'paidAmount': paidAmount,
    'remainingAmount': remainingAmount, 'createdAt': createdAt,
  };
}

class SaleItem {
  final String id;
  final String saleId;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const SaleItem({
    required this.id, required this.saleId, required this.productId,
    this.productName = '', required this.quantity, required this.unitPrice, required this.totalPrice,
  });

  factory SaleItem.fromFirestore(String id, Map<String, dynamic> data) => SaleItem(
    id: id,
    saleId: data['saleId'] as String? ?? '',
    productId: data['productId'] as String? ?? '',
    productName: data['productName'] as String? ?? '',
    quantity: (data['quantity'] as num?)?.toInt() ?? 0,
    unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0,
    totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toFirestore() => {
    'saleId': saleId, 'productId': productId, 'productName': productName,
    'quantity': quantity, 'unitPrice': unitPrice, 'totalPrice': totalPrice,
  };
}
