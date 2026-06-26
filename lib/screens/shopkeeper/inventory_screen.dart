import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../widgets/product_image.dart';
import '../admin/add_edit_product_screen.dart';
import '../barcode_scanner_screen.dart';
import '../order_form_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
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

  void _showOrderForm(Product p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _InventoryOrderSheet(product: p, parentContext: context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<Product>>(
        key: ValueKey('inventory_$_refreshKey'),
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
                p.subcategory.toLowerCase().contains(q) ||
                p.barcode.toLowerCase().contains(q) ||
                p.sku.toLowerCase().contains(q)).toList();
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() => _refreshKey++),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
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
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: () async {
                            final result = await Navigator.of(context).push<String>(
                              MaterialPageRoute(
                                builder: (_) => const BarcodeScannerScreen(title: 'Scan to Search'),
                              ),
                            );
                            if (result != null && mounted) {
                              _searchCtrl.text = result;
                              setState(() => _searchQuery = result);
                            }
                          },
                          icon: const Icon(Icons.qr_code_scanner, size: 20),
                          tooltip: 'Scan barcode to search',
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            foregroundColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
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
                          Text(_searchQuery.isNotEmpty ? 'No matching products' : 'No products available',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(color: Colors.grey.shade500)),
                          if (_searchQuery.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const Text('Clear search'),
                            ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final p = products[index];
                          final isLow = p.stock < 10;
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ProductImage(
                                        imageUrl: p.imagePath,
                                        productName: p.name,
                                        height: double.infinity,
                                        width: double.infinity,
                                        borderRadius: 0,
                                      ),
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isLow
                                                ? Colors.red.shade600
                                                : Colors.green.shade600,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text('${p.stock}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                      ),
                                      Positioned(
                                        top: 6,
                                        left: 6,
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      AddEditProductScreen(
                                                          product: p)),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(4),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.black26,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Icon(
                                                Icons.edit_outlined,
                                                size: 16,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      10, 6, 10, 0),
                                  child: Text(p.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                ),
                                if (p.subcategory.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                    child: Text(p.subcategory,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.teal.shade600)),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      10, 0, 10, 0),
                                  child: Text(
                                      'Rs. ${p.price.toStringAsFixed(2)}',
                                      style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF60cdff))),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      10, 4, 10, 8),
                                  child: SizedBox(
                                    height: 44,
                                    child: FilledButton.tonalIcon(
                                      onPressed: () =>
                                          _showOrderForm(p),
                                      icon: const Icon(
                                          Icons.shopping_cart_outlined,
                                          size: 14),
                                      label: const Text('Order',
                                          style: TextStyle(fontSize: 11)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: products.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InventoryOrderSheet extends StatefulWidget {
  final Product product;
  final BuildContext parentContext;
  const _InventoryOrderSheet({required this.product, required this.parentContext});

  @override
  State<_InventoryOrderSheet> createState() => _InventoryOrderSheetState();
}

class _InventoryOrderSheetState extends State<_InventoryOrderSheet> {
  late String? _selectedSubItem;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _selectedSubItem = widget.product.subItems.isNotEmpty ? widget.product.subItems.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final screenContext = widget.parentContext;

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.shopping_bag_outlined,
                    color: Colors.teal.shade700, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    Text('Rs. ${p.price.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          if (p.subItems.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Select Variant',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 6,
              children: p.subItems.map((item) {
                final active = _selectedSubItem == item;
                return ChoiceChip(
                  label: Text(item, style: const TextStyle(fontSize: 13)),
                  selected: active,
                  onSelected: (_) => setState(() => _selectedSubItem = item),
                  selectedColor: Colors.teal.shade100,
                  backgroundColor: Colors.grey.shade100,
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Text('Quantity:',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),
              SizedBox(
                width: 40,
                child: Text('$_quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _quantity < 999
                    ? () => setState(() => _quantity++)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total:',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              Text('Rs. ${(p.price * _quantity).toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700)),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.arrow_forward, size: 20),
            label: Text('Continue to Details',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(screenContext).push(
                MaterialPageRoute(
                  builder: (_) => OrderFormScreen(
                    items: [
                      {
                        'name': p.name,
                        'subItem': _selectedSubItem ?? '',
                        'price': p.price,
                        'quantity': _quantity,
                      }
                    ],
                    total: p.price * _quantity,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
