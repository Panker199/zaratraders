import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AdminService {
  static final AdminService _instance = AdminService._();
  static AdminService get instance => _instance;

  final FirebaseFirestore? _firestore;

  AdminService._() : _firestore = _initFirestore();
  factory AdminService() => _instance;

  static FirebaseFirestore? _initFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference? get _users => _firestore?.collection('users');
  CollectionReference? get _orders => _firestore?.collection('orders');
  CollectionReference? get _warehouses => _firestore?.collection('warehouses');

  bool get _available => _firestore != null;

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    if (!_available) return Stream.value([]);
    return _users!.orderBy('name').snapshots().map((snap) => snap.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['uid'] = doc.id;
          return data;
        }).toList());
  }

  Future<int> getUserCount() async {
    if (!_available) return 0;
    final snap = await _users!.get();
    return snap.docs.length;
  }

  Future<void> updateUserRole(String uid, UserRole newRole) async {
    if (!_available) return;
    await _users!.doc(uid).update({'role': newRole.name});
  }

  Future<void> deleteUser(String uid) async {
    if (!_available) return;
    await _users!.doc(uid).delete();
  }

  Stream<List<Map<String, dynamic>>> getOrdersStream() {
    if (!_available) return Stream.value([]);
    return _orders!.orderBy('createdAt', descending: true).snapshots().map(
        (snap) => snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
            }).toList());
  }

  Future<int> getOrderCount() async {
    if (!_available) return 0;
    final snap = await _orders!.get();
    return snap.docs.length;
  }

  Future<double> getTotalRevenue() async {
    if (!_available) return 0;
    final snap = await _orders!.where('status', whereIn: ['delivered', 'shipped', 'confirmed']).get();
    double total = 0;
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['total'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  Future<void> placeOrder(Map<String, dynamic> orderData) async {
    if (!_available) return;
    orderData['createdAt'] = FieldValue.serverTimestamp();
    orderData['status'] = 'pending';
    await _orders!.add(orderData);
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    if (!_available) return;
    await _orders!.doc(orderId).update({'status': status});
  }

  Future<void> deleteOrder(String orderId) async {
    if (!_available) return;
    await _orders!.doc(orderId).delete();
  }

  Stream<List<Map<String, dynamic>>> getWarehousesStream() {
    if (!_available) return Stream.value([]);
    return _warehouses!.orderBy('name').snapshots().map((snap) => snap.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList());
  }

  Future<void> addWarehouse(Map<String, dynamic> data) async {
    if (!_available) return;
    data['createdAt'] = FieldValue.serverTimestamp();
    await _warehouses!.add(data);
  }

  Future<void> updateWarehouse(String id, Map<String, dynamic> data) async {
    if (!_available) return;
    await _warehouses!.doc(id).update(data);
  }

  Future<void> deleteWarehouse(String id) async {
    if (!_available) return;
    await _warehouses!.doc(id).delete();
  }

  Future<int> updateProductImages() async {
    if (!_available) return 0;
    final snap = await _products!.get();
    int updated = 0;
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['name'] as String? ?? 'product';
      final seed = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final url = 'https://picsum.photos/seed/$seed/400/400';
      await doc.reference.update({'imagePath': url});
      updated++;
    }
    return updated;
  }

  CollectionReference? get _products => _firestore?.collection('products');

  CollectionReference? get _customers => _firestore?.collection('customers');
  CollectionReference? get _suppliers => _firestore?.collection('suppliers');
  CollectionReference? get _brands => _firestore?.collection('brands');
  CollectionReference? get _units => _firestore?.collection('units');

  Stream<List<Map<String, dynamic>>> getCustomersStream() {
    if (!_available) return Stream.value([]);
    return _customers!.orderBy('name').snapshots().map((snap) => snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList());
  }
  Future<void> addCustomer(Map<String, dynamic> data) async {
    if (!_available) return;
    data['createdAt'] = FieldValue.serverTimestamp();
    await _customers!.add(data);
  }
  Future<void> updateCustomer(String id, Map<String, dynamic> data) async {
    if (!_available) return;
    await _customers!.doc(id).update(data);
  }
  Future<void> deleteCustomer(String id) async {
    if (!_available) return;
    await _customers!.doc(id).delete();
  }

  Stream<List<Map<String, dynamic>>> getSuppliersStream() {
    if (!_available) return Stream.value([]);
    return _suppliers!.orderBy('name').snapshots().map((snap) => snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList());
  }
  Future<void> addSupplier(Map<String, dynamic> data) async {
    if (!_available) return;
    data['createdAt'] = FieldValue.serverTimestamp();
    await _suppliers!.add(data);
  }
  Future<void> updateSupplier(String id, Map<String, dynamic> data) async {
    if (!_available) return;
    await _suppliers!.doc(id).update(data);
  }
  Future<void> deleteSupplier(String id) async {
    if (!_available) return;
    await _suppliers!.doc(id).delete();
  }

  Stream<List<Map<String, dynamic>>> getBrandsStream() {
    if (!_available) return Stream.value([]);
    return _brands!.orderBy('name').snapshots().map((snap) => snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList());
  }
  Future<void> addBrand(Map<String, dynamic> data) async {
    if (!_available) return;
    await _brands!.add(data);
  }
  Future<void> updateBrand(String id, Map<String, dynamic> data) async {
    if (!_available) return;
    await _brands!.doc(id).update(data);
  }
  Future<void> deleteBrand(String id) async {
    if (!_available) return;
    await _brands!.doc(id).delete();
  }

  /// Returns a map of collection name -> document count for all known collections.
  Future<Map<String, int>> getCollectionStats() async {
    if (!_available) return {};
    final collections = [
      'users', 'customers', 'suppliers', 'brands', 'units',
      'warehouses', 'products', 'categories', 'orders',
      'support_tickets', 'purchases', 'sales', 'payments',
      'stock_movements', 'audit_logs',
    ];
    final stats = <String, int>{};
    for (final name in collections) {
      try {
        final snap = await _firestore!.collection(name).limit(1000).get();
        stats[name] = snap.docs.length;
      } catch (_) {
        stats[name] = -1;
      }
    }
    return stats;
  }

  static const List<Map<String, dynamic>> collectionMeta = [
    {'name': 'users', 'icon': Icons.people_rounded, 'color': Color(0xFF7C4DFF)},
    {'name': 'customers', 'icon': Icons.people_alt_outlined, 'color': Color(0xFF536DFE)},
    {'name': 'suppliers', 'icon': Icons.local_shipping_outlined, 'color': Color(0xFFFF6D00)},
    {'name': 'brands', 'icon': Icons.branding_watermark_outlined, 'color': Color(0xFFFFAB00)},
    {'name': 'units', 'icon': Icons.straighten_outlined, 'color': Color(0xFF00C853)},
    {'name': 'categories', 'icon': Icons.category_rounded, 'color': Color(0xFF00BCD4)},
    {'name': 'products', 'icon': Icons.inventory_2_rounded, 'color': Color(0xFF2979FF)},
    {'name': 'warehouses', 'icon': Icons.warehouse_rounded, 'color': Color(0xFF00BFA5)},
    {'name': 'orders', 'icon': Icons.receipt_long_rounded, 'color': Color(0xFFFF6D00)},
    {'name': 'support_tickets', 'icon': Icons.support_agent_rounded, 'color': Color(0xFFE040FB)},
    {'name': 'purchases', 'icon': Icons.shopping_cart_rounded, 'color': Color(0xFF6200EA)},
    {'name': 'sales', 'icon': Icons.point_of_sale_rounded, 'color': Color(0xFF00E676)},
    {'name': 'payments', 'icon': Icons.account_balance_wallet_rounded, 'color': Color(0xFF00BCD4)},
    {'name': 'stock_movements', 'icon': Icons.swap_vert_rounded, 'color': Color(0xFFFF9100)},
    {'name': 'audit_logs', 'icon': Icons.history_rounded, 'color': Color(0xFF78909C)},
  ];

  Stream<List<Map<String, dynamic>>> getUnitsStream() {
    if (!_available) return Stream.value([]);
    return _units!.orderBy('name').snapshots().map((snap) => snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList());
  }
  Future<void> addUnit(Map<String, dynamic> data) async {
    if (!_available) return;
    await _units!.add(data);
  }
  Future<void> updateUnit(String id, Map<String, dynamic> data) async {
    if (!_available) return;
    await _units!.doc(id).update(data);
  }
  Future<void> deleteUnit(String id) async {
    if (!_available) return;
    await _units!.doc(id).delete();
  }

  // ---- Generic document CRUD for DB browser ----

  Future<List<Map<String, dynamic>>> getDocuments(String collection, {int limit = 50}) async {
    if (!_available) return [];
    final snap = await _firestore!.collection(collection).limit(limit).get();
    return snap.docs.map((doc) {
      final data = <String, dynamic>{'_id': doc.id};
      data.addAll(doc.data());
      return data;
    }).toList();
  }

  Future<void> addDocument(String collection, Map<String, dynamic> data) async {
    if (!_available) return;
    await _firestore!.collection(collection).add(data);
  }

  Future<void> updateDocument(String collection, String docId, Map<String, dynamic> data) async {
    if (!_available) return;
    await _firestore!.collection(collection).doc(docId).update(data);
  }

  Future<void> deleteDocument(String collection, String docId) async {
    if (!_available) return;
    await _firestore!.collection(collection).doc(docId).delete();
  }

  Future<Map<String, dynamic>?> getDocument(String collection, String docId) async {
    if (!_available) return null;
    final doc = await _firestore!.collection(collection).doc(docId).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    data['_id'] = doc.id;
    return data;
  }
}
