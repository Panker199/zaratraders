import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/category.dart';

class ProductService {
  static final ProductService _instance = ProductService._();
  static ProductService get instance => _instance;

  final FirebaseFirestore? _firestore;

  ProductService._() : _firestore = _initFirestore();
  factory ProductService() => _instance;

  static FirebaseFirestore? _initFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference? get _products =>
      _firestore?.collection('products');
  CollectionReference? get _categories =>
      _firestore?.collection('categories');

  bool get _available => _firestore != null;

  Stream<List<Product>> getProductsStream() {
    if (!_available) return Stream.value([]);
    return _products!.orderBy('name').snapshots().map((snap) =>
        snap.docs.map((doc) => Product.fromJson(doc.id, doc.data() as Map<String, dynamic>)).toList());
  }

  Future<List<Product>> getProducts() async {
    if (!_available) return [];
    final snap = await _products!.orderBy('name').get();
    return snap.docs
        .map((doc) => Product.fromJson(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> addProduct(Product product) async {
    if (!_available) return;
    await _products!.add(product.toJson());
  }

  Future<void> updateProduct(Product product) async {
    if (!_available) return;
    await _products!.doc(product.id).update(product.toJson());
  }

  Future<void> deleteProduct(String productId) async {
    if (!_available) return;
    await _products!.doc(productId).delete();
  }

  Stream<List<Category>> getCategoriesStream() {
    if (!_available) return Stream.value([]);
    return _categories!.orderBy('name').snapshots().map((snap) =>
        snap.docs.map((doc) => Category.fromJson(doc.id, doc.data() as Map<String, dynamic>)).toList());
  }

  Future<List<Category>> getCategories() async {
    if (!_available) return [];
    final snap = await _categories!.orderBy('name').get();
    return snap.docs
        .map((doc) => Category.fromJson(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> addCategory(String name) async {
    if (!_available) return;
    await _categories!.add({'name': name});
  }

  Future<void> deleteCategory(String id) async {
    if (!_available) return;
    await _categories!.doc(id).delete();
  }

  Future<void> addSubCategory(String categoryId, String subCategoryName) async {
    if (!_available) return;
    await _categories!.doc(categoryId).update({
      'subCategories': FieldValue.arrayUnion([subCategoryName]),
    });
  }

  Future<void> deleteSubCategory(String categoryId, String subCategoryName) async {
    if (!_available) return;
    await _categories!.doc(categoryId).update({
      'subCategories': FieldValue.arrayRemove([subCategoryName]),
    });
  }
}
