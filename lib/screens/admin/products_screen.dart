import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../widgets/product_image.dart';
import 'add_edit_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _productService = ProductService();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _refreshKey = 0;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _deleteProduct(Product p) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) {
        final nav = Navigator.of(ctx);
        var deleting = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Delete Product'),
            content: Text('Delete "${p.name}"? This cannot be undone.'),
            actions: [
              TextButton(
                  onPressed: deleting ? null : () => nav.pop(),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: deleting
                    ? null
                    : () async {
                        setDialogState(() => deleting = true);
                        try {
                          await _productService.deleteProduct(p.id);
                          if (mounted) nav.pop();
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('"${p.name}" deleted'),
                                  behavior: SnackBarBehavior.floating),
                            );
                          }
                        } catch (e) {
                          if (mounted) nav.pop();
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Failed to delete: $e'),
                                  behavior: SnackBarBehavior.floating),
                            );
                          }
                        }
                      },
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: deleting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Delete'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Products',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
              );
              if (!mounted) return;
              if (result == true) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Product added'),
                      behavior: SnackBarBehavior.floating),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        key: ValueKey('products_$_refreshKey'),
        stream: _productService.getProductsStream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 12),
                  Text('Failed to load products',
                      style: TextStyle(color: Colors.red.shade600)),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => setState(() => _refreshKey++),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var products = snap.data!;
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            products = products.where((p) =>
                p.name.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q) ||
                p.subcategory.toLowerCase().contains(q)).toList();
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() => _refreshKey++),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) {
                        _debounce?.cancel();
                        _debounce = Timer(const Duration(milliseconds: 300), () {
                          if (!mounted) return;
                          setState(() => _searchQuery = v);
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                })
                            : null,
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                ),
                if (products.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(_searchQuery.isNotEmpty ? 'No matching products' : 'No products yet',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(color: Colors.grey.shade500)),
                          if (_searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const Text('Clear search'),
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            FilledButton.icon(
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Product'),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final p = products[index];
                        final isLowStock = p.stock < 10;
                        return Card(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: ListTile(
                            leading: ProductImage(
                              imageUrl: p.imagePath,
                              productName: p.name,
                              height: 44,
                              width: 44,
                              borderRadius: 6,
                            ),
                            title: Text(p.name,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                'Rs. ${p.price.toStringAsFixed(2)}  •  ${p.stock} in stock  •  ${p.category}${p.subcategory.isNotEmpty ? ' > ${p.subcategory}' : ''}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: isLowStock
                                        ? Colors.red.shade600
                                        : theme.colorScheme.onSurfaceVariant)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isLowStock)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text('${p.stock}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.red.shade600)),
                                  ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: Icon(Icons.edit_outlined,
                                      size: 18, color: Colors.grey.shade500),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) => AddEditProductScreen(product: p)),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      size: 18, color: Colors.red.shade300),
                                  onPressed: () => _deleteProduct(p),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: products.length,
                    ),
                  ),
                  const SliverPadding(
                      padding: EdgeInsets.only(bottom: 24)),
              ],
            ),
          );
        },
      ),
    );
  }
}
