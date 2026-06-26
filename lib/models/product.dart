class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final String brand;
  final String unit;
  final int currentStock;
  final int minimumStock;
  final double purchasePrice;
  final double sellingPrice;

  double get price => sellingPrice;
  int get stock => currentStock;
  final String warehouse;
  final String sku;
  final String barcode;
  final DateTime createdAt;

  // legacy fields kept for deserialization compatibility
  final String subcategory;
  final String imagePath;
  final double rating;
  final List<String> subItems;

  Product({
    required this.id,
    required this.name,
    this.description = '',
    this.category = '',
    this.brand = '',
    this.unit = '',
    this.minimumStock = 0,
    this.purchasePrice = 0,
    this.warehouse = '',
    this.sku = '',
    this.barcode = '',
    this.subcategory = '',
    this.imagePath = '',
    this.rating = 0.0,
    this.subItems = const [],
    DateTime? createdAt,
    int stock = 0,
    double price = 0,
  }) : currentStock = stock,
       sellingPrice = price,
       createdAt = createdAt ?? DateTime.now();

  factory Product.fromJson(String id, Map<String, dynamic> json) {
    final raw = json['subItems'];
    final List<String> subItems;
    if (raw is List) {
      subItems = raw.map((e) => e.toString()).toList();
    } else {
      subItems = const [];
    }

    final sellingPriceVal = (json['sellingPrice'] as num?)?.toDouble();
    final priceVal = (json['price'] as num?)?.toDouble();
    final currentStockVal = (json['currentStock'] as num?)?.toInt();
    final stockVal = (json['stock'] as num?)?.toInt();

    return Product(
      id: id,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      stock: currentStockVal ?? stockVal ?? 0,
      minimumStock: (json['minimumStock'] as num?)?.toInt() ?? 0,
      price: sellingPriceVal ?? priceVal ?? 0.0,
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0,
      warehouse: json['warehouse'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      createdAt: (json['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      subcategory: json['subcategory'] as String? ?? '',
      imagePath: json['imagePath'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      subItems: subItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'brand': brand,
      'unit': unit,
      'currentStock': currentStock,
      'minimumStock': minimumStock,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'warehouse': warehouse,
      'sku': sku,
      'barcode': barcode,
      'createdAt': createdAt,
      'subcategory': subcategory,
      'imagePath': imagePath,
      'rating': rating,
      if (subItems.isNotEmpty) 'subItems': subItems,
      'stock': currentStock,
      'price': sellingPrice,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? brand,
    String? unit,
    int? stock,
    int? minimumStock,
    double? price,
    double? purchasePrice,
    String? warehouse,
    String? sku,
    String? barcode,
    DateTime? createdAt,
    String? subcategory,
    String? imagePath,
    double? rating,
    List<String>? subItems,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      unit: unit ?? this.unit,
      stock: stock ?? currentStock,
      minimumStock: minimumStock ?? this.minimumStock,
      price: price ?? sellingPrice,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      warehouse: warehouse ?? this.warehouse,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      createdAt: createdAt ?? this.createdAt,
      subcategory: subcategory ?? this.subcategory,
      imagePath: imagePath ?? this.imagePath,
      rating: rating ?? this.rating,
      subItems: subItems ?? this.subItems,
    );
  }
}

class CartItem {
  final Product product;
  final String subItem;
  int quantity;

  CartItem({required this.product, this.subItem = '', this.quantity = 1});

  double get totalPrice => product.price * quantity;
}
