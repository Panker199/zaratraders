import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseSetupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Creates seed documents to establish all collection groups in Firestore.
  /// Collections appear automatically when their first document is written.
  Future<Map<String, int>> seedCollections() async {
    final counts = <String, int>{};

    final batch = _db.batch();

    // customers
    final customersRef = _db.collection('customers');
    for (int i = 1; i <= 3; i++) {
      final doc = customersRef.doc();
      batch.set(doc, {
        'name': i == 1 ? 'Ali Traders' : i == 2 ? 'New Market Store' : 'City General Store',
        'phoneNumber': i == 1 ? '03001234561' : i == 2 ? '03001234562' : '03001234563',
        'email': '',
        'address': i == 1 ? 'Lahore' : i == 2 ? 'Karachi' : 'Islamabad',
        'balance': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    counts['customers'] = 3;

    // suppliers
    final suppliersRef = _db.collection('suppliers');
    for (int i = 1; i <= 3; i++) {
      final doc = suppliersRef.doc();
      batch.set(doc, {
        'name': i == 1 ? 'PepsiCo Pakistan' : i == 2 ? 'Nestle Pakistan' : 'Engro Foods',
        'phoneNumber': i == 1 ? '02111112345' : i == 2 ? '02111123456' : '02111134567',
        'email': '',
        'address': 'Karachi',
        'balance': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    counts['suppliers'] = 3;

    // categories
    final categoriesRef = _db.collection('categories');
    final catNames = ['Beverages', 'Snacks', 'Dairy', 'Ice Cream', 'Bread & Bakery'];
    for (final name in catNames) {
      final doc = categoriesRef.doc();
      batch.set(doc, {'name': name, 'description': '$name category'});
    }
    counts['categories'] = catNames.length;

    // brands
    final brandsRef = _db.collection('brands');
    final brandNames = ['Pepsi', 'Coca-Cola', 'Nestle', 'Engro', 'Shan'];
    for (final name in brandNames) {
      final doc = brandsRef.doc();
      batch.set(doc, {'name': name, 'description': '$name brand'});
    }
    counts['brands'] = brandNames.length;

    // units
    final unitsRef = _db.collection('units');
    final unitsData = [{'name': 'Piece', 'shortName': 'pcs'}, {'name': 'Liter', 'shortName': 'L'}, {'name': 'Kilogram', 'shortName': 'kg'}, {'name': 'Carton', 'shortName': 'ctn'}, {'name': 'Pack', 'shortName': 'pck'}];
    for (final u in unitsData) {
      final doc = unitsRef.doc();
      batch.set(doc, u);
    }
    counts['units'] = unitsData.length;

    // warehouses
    final warehousesRef = _db.collection('warehouses');
    final whData = [{'name': 'Main Warehouse', 'location': 'Lahore', 'description': 'Primary storage'}, {'name': 'Cold Storage', 'location': 'Karachi', 'description': 'Temperature controlled'}];
    for (final w in whData) {
      final doc = warehousesRef.doc();
      batch.set(doc, w);
    }
    counts['warehouses'] = whData.length;

    // support_tickets + support_messages (as subcollections)
    // Use individual writes since subcollections need the parent doc ID
    final ticketDoc = _db.collection('support_tickets').doc();
    await ticketDoc.set({
      'userId': 'seed', 'userName': 'Demo User', 'subject': 'Welcome to Zara Traders support',
      'status': 'open', 'lastMessage': 'How can we help you today?',
      'createdAt': FieldValue.serverTimestamp(), 'lastMessageAt': FieldValue.serverTimestamp(),
    });
    await ticketDoc.collection('messages').add({
      'ticketId': ticketDoc.id, 'senderId': 'system', 'senderRole': 'admin',
      'text': 'How can we help you today?', 'timestamp': FieldValue.serverTimestamp(),
    });
    counts['support_tickets'] = 1;

    // products
    final productsRef = _db.collection('products');
    final prodData = [
      {'sku': 'BEV001', 'barcode': '8901234567890', 'name': 'Pepsi 500ml', 'category': 'Beverages', 'brand': 'Pepsi', 'unit': 'pcs', 'currentStock': 100, 'minimumStock': 10, 'purchasePrice': 25.0, 'sellingPrice': 35.0, 'description': 'Cold drink', 'warehouse': 'Main Warehouse'},
      {'sku': 'BEV002', 'barcode': '8901234567891', 'name': 'Coca-Cola 500ml', 'category': 'Beverages', 'brand': 'Coca-Cola', 'unit': 'pcs', 'currentStock': 80, 'minimumStock': 10, 'purchasePrice': 25.0, 'sellingPrice': 35.0, 'description': 'Cold drink', 'warehouse': 'Main Warehouse'},
      {'sku': 'BEV003', 'barcode': '8901234567892', 'name': 'Mineral Water 1.5L', 'category': 'Beverages', 'brand': 'Nestle', 'unit': 'pcs', 'currentStock': 200, 'minimumStock': 20, 'purchasePrice': 30.0, 'sellingPrice': 45.0, 'description': 'Pure drinking water', 'warehouse': 'Main Warehouse'},
      {'sku': 'DRI001', 'barcode': '8901234567893', 'name': 'Yogurt 500g', 'category': 'Dairy', 'brand': 'Nestle', 'unit': 'pcs', 'currentStock': 50, 'minimumStock': 5, 'purchasePrice': 60.0, 'sellingPrice': 85.0, 'description': 'Fresh yogurt', 'warehouse': 'Cold Storage'},
      {'sku': 'ICE001', 'barcode': '8901234567894', 'name': 'Vanilla Ice Cream 1L', 'category': 'Ice Cream', 'brand': 'Engro', 'unit': 'pcs', 'currentStock': 30, 'minimumStock': 5, 'purchasePrice': 200.0, 'sellingPrice': 299.0, 'description': 'Premium vanilla ice cream', 'warehouse': 'Cold Storage'},
    ];
    for (final p in prodData) {
      final doc = productsRef.doc();
      batch.set(doc, {
        ...p,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    counts['products'] = prodData.length;

    await batch.commit();
    return counts;
  }

  /// Completely erases all seeded collections (for clean reset during development)
  Future<void> clearAllCollections() async {
    final collections = [
      'customers', 'suppliers', 'brands', 'units',
      'warehouses', 'products', 'purchases', 'purchase_items',
      'sales', 'sale_items', 'payments', 'stock_movements', 'audit_logs',
      'support_tickets',
    ];
    for (final name in collections) {
      final snap = await _db.collection(name).limit(500).get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    }
  }

  /// Seeds personal care / hygiene categories with products and images.
  Future<Map<String, int>> seedPersonalCareCollections() async {
    final counts = <String, int>{};
    final batch = _db.batch();
    int catCount = 0;
    int prodCount = 0;
    int brandCount = 0;

    // ---- Categories with subcategories ----
    final categoriesRef = _db.collection('categories');
    final categories = [
      {
        'name': 'Shampoo',
        'description': 'Hair care shampoos',
        'subCategories': ['Hair Care', 'Anti-Dandruff', 'Baby Shampoo', 'Herbal'],
        'icon': 'content_cut',
      },
      {
        'name': 'Soap',
        'description': 'Bath and beauty soaps',
        'subCategories': ['Bath Soap', 'Hand Soap', 'Antibacterial', 'Beauty Bar'],
        'icon': 'bubble_chart',
      },
      {
        'name': 'Hand Wash',
        'description': 'Hand wash and sanitizers',
        'subCategories': ['Liquid Hand Wash', 'Hand Sanitizer', 'Foam Hand Wash'],
        'icon': 'back_hand',
      },
      {
        'name': 'Face Wash',
        'description': 'Face cleansers and washes',
        'subCategories': ['For Men', 'For Women', 'Acne Control', 'Whitening'],
        'icon': 'face',
      },
      {
        'name': 'Beauty Creams',
        'description': 'Skincare and beauty creams',
        'subCategories': ['Fairness', 'Moisturizing', 'Sunscreen', 'Anti-Aging'],
        'icon': 'spa',
      },
      {
        'name': 'Kids Diapers',
        'description': 'Baby and kids diapers',
        'subCategories': ['Newborn', 'Small', 'Medium', 'Large', 'XL'],
        'icon': 'child_care',
      },
      {
        'name': 'Adult Diapers',
        'description': 'Adult incontinence products',
        'subCategories': ['Medium', 'Large', 'XL', 'Overnight'],
        'icon': 'elderly',
      },
      {
        'name': 'Baby Wipes',
        'description': 'Baby cleaning wipes',
        'subCategories': ['Sensitive', 'Aloe Vera', 'Fragrance Free', 'Water Based'],
        'icon': 'wipe',
      },
      {
        'name': 'Feeders',
        'description': 'Baby feeding bottles and accessories',
        'subCategories': ['Baby Bottles', 'Sippy Cups', 'Feeding Sets', 'Pacifiers'],
        'icon': 'local_cafe',
      },
      {
        'name': 'Toothpaste',
        'description': 'Dental care toothpastes',
        'subCategories': ['Fluoride', 'Whitening', 'Sensitivity', 'Herbal'],
        'icon': 'clean_hands',
      },
      {
        'name': 'Toothbrush',
        'description': 'Dental care toothbrushes',
        'subCategories': ['Manual', 'Electric', 'Kids', 'Soft Bristle'],
        'icon': 'brush',
      },
      {
        'name': 'Tissue Papers',
        'description': 'Facial and household tissue papers',
        'subCategories': ['Facial Tissue', 'Toilet Roll', 'Kitchen Rolls', 'Pocket Tissue'],
        'icon': 'receipt_long',
      },
    ];

    for (final cat in categories) {
      final doc = categoriesRef.doc();
      batch.set(doc, {
        'name': cat['name'],
        'description': cat['description'],
        'subCategories': cat['subCategories'],
        'createdAt': FieldValue.serverTimestamp(),
      });
      catCount++;
    }
    counts['categories'] = catCount;

    // ---- Brands ----
    final brandsRef = _db.collection('brands');
    final brands = [
      {'name': 'Pantene', 'description': 'Hair care brand'},
      {'name': 'Head & Shoulders', 'description': 'Anti-dandruff shampoo'},
      {'name': 'Sunsilk', 'description': 'Hair care brand'},
      {'name': 'Dove', 'description': 'Beauty and personal care'},
      {'name': 'Dettol', 'description': 'Antibacterial soap and wash'},
      {'name': 'Lux', 'description': 'Beauty soap brand'},
      {'name': 'Lifebuoy', 'description': 'Antibacterial soap'},
      {'name': 'Pears', 'description': 'Gentle beauty soap'},
      {'name': 'Lifebuoy Hand Wash', 'description': 'Hand hygiene'},
      {'name': 'Dettol Hand Wash', 'description': 'Antibacterial hand wash'},
      {'name': 'Himalaya', 'description': 'Herbal personal care'},
      {'name': 'Neutrogena', 'description': 'Dermatologist recommended skincare'},
      {'name': 'Garnier', 'description': 'Skincare and haircare'},
      {'name': 'Nivea', 'description': 'Skincare brand'},
      {'name': 'Vaseline', 'description': 'Moisturizing brand'},
      {'name': 'Pampers', 'description': 'Diapers and baby care'},
      {'name': 'Huggies', 'description': 'Diapers brand'},
      {'name': 'Baby Joy', 'description': 'Baby care products'},
      {'name': 'Colgate', 'description': 'Dental care brand'},
      {'name': 'Pepsodent', 'description': 'Dental care brand'},
      {'name': 'Sensodyne', 'description': 'Sensitive teeth care'},
      {'name': 'Oral-B', 'description': 'Dental care products'},
      {'name': 'Medora', 'description': 'Toothbrush brand'},
      {'name': 'Kleenex', 'description': 'Tissue papers'},
      {'name': 'Fine', 'description': 'Tissue and hygiene products'},
      {'name': 'Rose Petal', 'description': 'Tissue papers'},
    ];
    for (final b in brands) {
      final doc = brandsRef.doc();
      batch.set(doc, {
        'name': b['name'],
        'description': b['description'],
        'createdAt': FieldValue.serverTimestamp(),
      });
      brandCount++;
    }
    counts['brands'] = brandCount;

    // ---- Units ----
    final unitsRef = _db.collection('units');
    final unitsData = [
      {'name': 'Piece', 'shortName': 'pcs'},
      {'name': 'Pack', 'shortName': 'pck'},
      {'name': 'Carton', 'shortName': 'ctn'},
      {'name': 'Box', 'shortName': 'box'},
      {'name': 'Bottle', 'shortName': 'btl'},
    ];
    for (final u in unitsData) {
      final doc = unitsRef.doc();
      batch.set(doc, u);
    }
    counts['units'] = unitsData.length;

    // ---- Products ----
    final productsRef = _db.collection('products');
    final seed = _seedImageUrl;
    final products = [
      // Shampoo
      {'name': 'Pantene Shampoo 400ml', 'category': 'Shampoo', 'subcategory': 'Hair Care', 'brand': 'Pantene', 'unit': 'pcs', 'stock': 48, 'minStock': 10, 'purchasePrice': 380.0, 'sellingPrice': 480.0, 'desc': 'Pantene daily care shampoo for smooth and shiny hair', 'img': seed('shampoo-pantene')},
      {'name': 'Head & Shoulders 400ml', 'category': 'Shampoo', 'subcategory': 'Anti-Dandruff', 'brand': 'Head & Shoulders', 'unit': 'pcs', 'stock': 36, 'minStock': 8, 'purchasePrice': 350.0, 'sellingPrice': 450.0, 'desc': 'Anti-dandruff shampoo for clean scalp', 'img': seed('shampoo-hs')},
      {'name': 'Sunsilk Black Shine 400ml', 'category': 'Shampoo', 'subcategory': 'Hair Care', 'brand': 'Sunsilk', 'unit': 'pcs', 'stock': 40, 'minStock': 8, 'purchasePrice': 320.0, 'sellingPrice': 420.0, 'desc': 'Shampoo for black shiny hair', 'img': seed('shampoo-sunsilk')},
      {'name': 'Dove Hair Fall Rescue 400ml', 'category': 'Shampoo', 'subcategory': 'Hair Care', 'brand': 'Dove', 'unit': 'pcs', 'stock': 30, 'minStock': 8, 'purchasePrice': 400.0, 'sellingPrice': 520.0, 'desc': 'Shampoo that reduces hair fall', 'img': seed('shampoo-dove')},
      {'name': 'Clinic Plus Shampoo 175ml', 'category': 'Shampoo', 'subcategory': 'Baby Shampoo', 'brand': 'Himalaya', 'unit': 'pcs', 'stock': 60, 'minStock': 12, 'purchasePrice': 120.0, 'sellingPrice': 165.0, 'desc': 'Gentle shampoo for kids', 'img': seed('shampoo-clinic')},

      // Soap
      {'name': 'Dettol Soap 125g', 'category': 'Soap', 'subcategory': 'Antibacterial', 'brand': 'Dettol', 'unit': 'pcs', 'stock': 80, 'minStock': 20, 'purchasePrice': 85.0, 'sellingPrice': 120.0, 'desc': 'Antibacterial soap for germ protection', 'img': seed('soap-dettol')},
      {'name': 'Lux Soap 125g (Rose)', 'category': 'Soap', 'subcategory': 'Beauty Bar', 'brand': 'Lux', 'unit': 'pcs', 'stock': 90, 'minStock': 20, 'purchasePrice': 75.0, 'sellingPrice': 105.0, 'desc': 'Rose beauty soap with fragrant petals', 'img': seed('soap-lux')},
      {'name': 'Lifebuoy Soap 125g', 'category': 'Soap', 'subcategory': 'Antibacterial', 'brand': 'Lifebuoy', 'unit': 'pcs', 'stock': 100, 'minStock': 20, 'purchasePrice': 65.0, 'sellingPrice': 90.0, 'desc': 'Total protection antibacterial soap', 'img': seed('soap-lifebuoy')},
      {'name': 'Pears Soap 75g', 'category': 'Soap', 'subcategory': 'Bath Soap', 'brand': 'Pears', 'unit': 'pcs', 'stock': 50, 'minStock': 10, 'purchasePrice': 90.0, 'sellingPrice': 130.0, 'desc': 'Pure glycerin gentle soap', 'img': seed('soap-pears')},

      // Hand Wash
      {'name': 'Lifebuoy Hand Wash 250ml', 'category': 'Hand Wash', 'subcategory': 'Liquid Hand Wash', 'brand': 'Lifebuoy Hand Wash', 'unit': 'pcs', 'stock': 45, 'minStock': 10, 'purchasePrice': 180.0, 'sellingPrice': 250.0, 'desc': 'Total hand protection liquid hand wash', 'img': seed('handwash-lifebuoy')},
      {'name': 'Dettol Hand Wash 250ml', 'category': 'Hand Wash', 'subcategory': 'Liquid Hand Wash', 'brand': 'Dettol Hand Wash', 'unit': 'pcs', 'stock': 40, 'minStock': 10, 'purchasePrice': 200.0, 'sellingPrice': 275.0, 'desc': 'Antibacterial instant hand wash', 'img': seed('handwash-dettol')},
      {'name': 'Himalaya Hand Wash 200ml', 'category': 'Hand Wash', 'subcategory': 'Liquid Hand Wash', 'brand': 'Himalaya', 'unit': 'pcs', 'stock': 35, 'minStock': 8, 'purchasePrice': 160.0, 'sellingPrice': 220.0, 'desc': 'Neem and turmeric hand wash', 'img': seed('handwash-himalaya')},

      // Face Wash
      {'name': 'Neutrogena Face Wash 150ml', 'category': 'Face Wash', 'subcategory': 'For Men', 'brand': 'Neutrogena', 'unit': 'pcs', 'stock': 25, 'minStock': 5, 'purchasePrice': 550.0, 'sellingPrice': 720.0, 'desc': 'Oil-free acne face wash', 'img': seed('facewash-neutrogena')},
      {'name': 'Garnier Face Wash 100ml', 'category': 'Face Wash', 'subcategory': 'Whitening', 'brand': 'Garnier', 'unit': 'pcs', 'stock': 30, 'minStock': 6, 'purchasePrice': 280.0, 'sellingPrice': 380.0, 'desc': 'Light complete serum face wash', 'img': seed('facewash-garnier')},
      {'name': 'Himalaya Face Wash 100ml', 'category': 'Face Wash', 'subcategory': 'Acne Control', 'brand': 'Himalaya', 'unit': 'pcs', 'stock': 35, 'minStock': 8, 'purchasePrice': 220.0, 'sellingPrice': 310.0, 'desc': 'Purifying neem face wash', 'img': seed('facewash-himalaya')},
      {'name': 'Nivea Face Wash 150ml', 'category': 'Face Wash', 'subcategory': 'For Women', 'brand': 'Nivea', 'unit': 'pcs', 'stock': 28, 'minStock': 5, 'purchasePrice': 300.0, 'sellingPrice': 400.0, 'desc': 'Acne clear face wash', 'img': seed('facewash-nivea')},

      // Beauty Creams
      {'name': 'Nivea Soft Moisturizer 100ml', 'category': 'Beauty Creams', 'subcategory': 'Moisturizing', 'brand': 'Nivea', 'unit': 'pcs', 'stock': 40, 'minStock': 8, 'purchasePrice': 350.0, 'sellingPrice': 480.0, 'desc': 'Light daily moisturizing cream', 'img': seed('cream-nivea')},
      {'name': 'Vaseline SPF 30 Lotion 100ml', 'category': 'Beauty Creams', 'subcategory': 'Sunscreen', 'brand': 'Vaseline', 'unit': 'pcs', 'stock': 25, 'minStock': 5, 'purchasePrice': 400.0, 'sellingPrice': 550.0, 'desc': 'Healthy white sun protect lotion', 'img': seed('cream-vaseline')},
      {'name': 'Garnier Light Cream 45g', 'category': 'Beauty Creams', 'subcategory': 'Fairness', 'brand': 'Garnier', 'unit': 'pcs', 'stock': 30, 'minStock': 6, 'purchasePrice': 250.0, 'sellingPrice': 350.0, 'desc': 'Bright complete vitamin C cream', 'img': seed('cream-garnier')},
      {'name': 'Dove Beauty Cream 100ml', 'category': 'Beauty Creams', 'subcategory': 'Moisturizing', 'brand': 'Dove', 'unit': 'pcs', 'stock': 20, 'minStock': 5, 'purchasePrice': 380.0, 'sellingPrice': 500.0, 'desc': 'Deeply nourishing body cream', 'img': seed('cream-dove')},

      // Kids Diapers
      {'name': 'Pampers Premium Care (S) 72pcs', 'category': 'Kids Diapers', 'subcategory': 'Small', 'brand': 'Pampers', 'unit': 'pcs', 'stock': 20, 'minStock': 5, 'purchasePrice': 2200.0, 'sellingPrice': 2850.0, 'desc': 'Premium soft diapers for babies 4-8kg', 'img': seed('diaper-pampers-s')},
      {'name': 'Pampers Premium Care (M) 60pcs', 'category': 'Kids Diapers', 'subcategory': 'Medium', 'brand': 'Pampers', 'unit': 'pcs', 'stock': 18, 'minStock': 5, 'purchasePrice': 2200.0, 'sellingPrice': 2850.0, 'desc': 'Premium soft diapers for babies 6-11kg', 'img': seed('diaper-pampers-m')},
      {'name': 'Huggies Dry Comfort (L) 54pcs', 'category': 'Kids Diapers', 'subcategory': 'Large', 'brand': 'Huggies', 'unit': 'pcs', 'stock': 15, 'minStock': 4, 'purchasePrice': 2000.0, 'sellingPrice': 2650.0, 'desc': 'Dry comfort diapers for babies 9-14kg', 'img': seed('diaper-huggies-l')},
      {'name': 'Baby Joy Diapers (XL) 40pcs', 'category': 'Kids Diapers', 'subcategory': 'XL', 'brand': 'Baby Joy', 'unit': 'pcs', 'stock': 22, 'minStock': 5, 'purchasePrice': 1200.0, 'sellingPrice': 1650.0, 'desc': 'Economy diapers for babies 12-17kg', 'img': seed('diaper-babyjoy-xl')},

      // Adult Diapers
      {'name': 'Tena Pants Plus (L) 10pcs', 'category': 'Adult Diapers', 'subcategory': 'Large', 'brand': 'Pampers', 'unit': 'pcs', 'stock': 12, 'minStock': 3, 'purchasePrice': 850.0, 'sellingPrice': 1150.0, 'desc': 'Pull-up protective underwear for adults', 'img': seed('adult-tena-l')},
      {'name': 'Friends Adult Diapers (XL) 10pcs', 'category': 'Adult Diapers', 'subcategory': 'XL', 'brand': 'Huggies', 'unit': 'pcs', 'stock': 10, 'minStock': 3, 'purchasePrice': 650.0, 'sellingPrice': 900.0, 'desc': 'Maximum absorbency adult diapers', 'img': seed('adult-friends-xl')},

      // Baby Wipes
      {'name': 'Pampers Baby Wipes Sensitive 80pcs', 'category': 'Baby Wipes', 'subcategory': 'Sensitive', 'brand': 'Pampers', 'unit': 'pcs', 'stock': 30, 'minStock': 8, 'purchasePrice': 350.0, 'sellingPrice': 480.0, 'desc': 'Gentle baby wipes for sensitive skin', 'img': seed('wipes-pampers')},
      {'name': 'Huggies Pure Wipes 64pcs', 'category': 'Baby Wipes', 'subcategory': 'Aloe Vera', 'brand': 'Huggies', 'unit': 'pcs', 'stock': 25, 'minStock': 6, 'purchasePrice': 300.0, 'sellingPrice': 420.0, 'desc': 'Pure water and aloe vera wipes', 'img': seed('wipes-huggies')},
      {'name': 'Baby Joy Wipes 80pcs', 'category': 'Baby Wipes', 'subcategory': 'Fragrance Free', 'brand': 'Baby Joy', 'unit': 'pcs', 'stock': 35, 'minStock': 8, 'purchasePrice': 200.0, 'sellingPrice': 290.0, 'desc': 'Fragrance free baby wipes', 'img': seed('wipes-babyjoy')},

      // Feeders
      {'name': 'Pigeon Baby Bottle 240ml', 'category': 'Feeders', 'subcategory': 'Baby Bottles', 'brand': 'Himalaya', 'unit': 'pcs', 'stock': 20, 'minStock': 4, 'purchasePrice': 450.0, 'sellingPrice': 620.0, 'desc': 'Soft silicone nipple baby bottle', 'img': seed('feeder-pigeon')},
      {'name': 'Munchkin Sippy Cup 250ml', 'category': 'Feeders', 'subcategory': 'Sippy Cups', 'brand': 'Pampers', 'unit': 'pcs', 'stock': 15, 'minStock': 4, 'purchasePrice': 380.0, 'sellingPrice': 520.0, 'desc': 'Spill-proof training cup for toddlers', 'img': seed('feeder-munchkin')},
      {'name': 'Baby Feeding Set (6pc)', 'category': 'Feeders', 'subcategory': 'Feeding Sets', 'brand': 'Baby Joy', 'unit': 'box', 'stock': 12, 'minStock': 3, 'purchasePrice': 600.0, 'sellingPrice': 850.0, 'desc': 'Complete feeding set with bowl, spoon, cup', 'img': seed('feeder-set')},

      // Toothpaste
      {'name': 'Colgate MaxFresh 150ml', 'category': 'Toothpaste', 'subcategory': 'Fluoride', 'brand': 'Colgate', 'unit': 'pcs', 'stock': 60, 'minStock': 15, 'purchasePrice': 140.0, 'sellingPrice': 195.0, 'desc': 'Cool mint fluoride toothpaste', 'img': seed('toothpaste-colgate')},
      {'name': 'Pepsodent Expert Protection 100ml', 'category': 'Toothpaste', 'subcategory': 'Fluoride', 'brand': 'Pepsodent', 'unit': 'pcs', 'stock': 50, 'minStock': 12, 'purchasePrice': 110.0, 'sellingPrice': 155.0, 'desc': '24/7 germ protection toothpaste', 'img': seed('toothpaste-pepsodent')},
      {'name': 'Sensodyne Daily Protection 100ml', 'category': 'Toothpaste', 'subcategory': 'Sensitivity', 'brand': 'Sensodyne', 'unit': 'pcs', 'stock': 20, 'minStock': 5, 'purchasePrice': 280.0, 'sellingPrice': 380.0, 'desc': 'Toothpaste for sensitive teeth', 'img': seed('toothpaste-sensodyne')},
      {'name': 'Colgate Visible White 100ml', 'category': 'Toothpaste', 'subcategory': 'Whitening', 'brand': 'Colgate', 'unit': 'pcs', 'stock': 35, 'minStock': 8, 'purchasePrice': 180.0, 'sellingPrice': 250.0, 'desc': 'Whitening toothpaste with micro-cleansing', 'img': seed('toothpaste-colgate-white')},

      // Toothbrush
      {'name': 'Oral-B Pro-Health Manual', 'category': 'Toothbrush', 'subcategory': 'Manual', 'brand': 'Oral-B', 'unit': 'pcs', 'stock': 50, 'minStock': 12, 'purchasePrice': 120.0, 'sellingPrice': 170.0, 'desc': 'CrossAction bristle manual toothbrush', 'img': seed('brush-oralb')},
      {'name': 'Medora Soft Bristle', 'category': 'Toothbrush', 'subcategory': 'Soft Bristle', 'brand': 'Medora', 'unit': 'pcs', 'stock': 60, 'minStock': 15, 'purchasePrice': 60.0, 'sellingPrice': 90.0, 'desc': 'Soft bristle toothbrush for gentle cleaning', 'img': seed('brush-medora')},
      {'name': 'Colgate Kids Toothbrush', 'category': 'Toothbrush', 'subcategory': 'Kids', 'brand': 'Colgate', 'unit': 'pcs', 'stock': 40, 'minStock': 10, 'purchasePrice': 80.0, 'sellingPrice': 120.0, 'desc': 'Fun shaped toothbrush for kids', 'img': seed('brush-colgate-kids')},

      // Tissue Papers
      {'name': 'Kleenex Facial Tissue 150 pulls', 'category': 'Tissue Papers', 'subcategory': 'Facial Tissue', 'brand': 'Kleenex', 'unit': 'box', 'stock': 40, 'minStock': 10, 'purchasePrice': 250.0, 'sellingPrice': 350.0, 'desc': 'Soft 3-ply facial tissue box', 'img': seed('tissue-kleenex')},
      {'name': 'Fine Toilet Roll 6pcs', 'category': 'Tissue Papers', 'subcategory': 'Toilet Roll', 'brand': 'Fine', 'unit': 'pcs', 'stock': 50, 'minStock': 12, 'purchasePrice': 280.0, 'sellingPrice': 380.0, 'desc': '2-ply toilet tissue rolls pack', 'img': seed('tissue-fine-toilet')},
      {'name': 'Rose Petal Kitchen Roll 2pcs', 'category': 'Tissue Papers', 'subcategory': 'Kitchen Rolls', 'brand': 'Rose Petal', 'unit': 'pcs', 'stock': 30, 'minStock': 8, 'purchasePrice': 200.0, 'sellingPrice': 280.0, 'desc': 'Absorbent kitchen paper rolls', 'img': seed('tissue-rosepetal')},
      {'name': 'Kleenex Pocket Tissue 10pcs', 'category': 'Tissue Papers', 'subcategory': 'Pocket Tissue', 'brand': 'Kleenex', 'unit': 'pcs', 'stock': 45, 'minStock': 10, 'purchasePrice': 150.0, 'sellingPrice': 210.0, 'desc': 'Compact pocket tissue pack', 'img': seed('tissue-pocket')},
    ];

    for (final p in products) {
      final doc = productsRef.doc();
      batch.set(doc, {
        'sku': 'PC${String.fromCharCode(65 + prodCount % 26)}${(prodCount ~/ 26 + 1).toString().padLeft(2, '0')}',
        'barcode': '978123456${prodCount.toString().padLeft(4, '0')}',
        'name': p['name'],
        'category': p['category'],
        'subcategory': p['subcategory'],
        'brand': p['brand'],
        'unit': p['unit'],
        'currentStock': p['stock'],
        'minimumStock': p['minStock'],
        'purchasePrice': p['purchasePrice'],
        'sellingPrice': p['sellingPrice'],
        'description': p['desc'],
        'imagePath': p['img'],
        'rating': 0.0,
        'warehouse': 'Main Warehouse',
        'createdAt': FieldValue.serverTimestamp(),
      });
      prodCount++;
    }
    counts['products'] = prodCount;

    await batch.commit();
    return counts;
  }

  static String _seedImageUrl(String seed) =>
      'https://picsum.photos/seed/$seed/400/400';
}
