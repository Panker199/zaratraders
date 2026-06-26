import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../widgets/product_image.dart';
import 'product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final ProductService productService;
  final String? initialCategory;
  const SearchScreen({super.key, required this.productService, this.initialCategory});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  String? _categoryFilter;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _query = widget.initialCategory!;
      _controller.text = _query;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          height: 36,
          child: TextField(
            controller: _controller,
            autofocus: widget.initialCategory == null,
            onChanged: (v) {
              _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  if (!mounted) return;
                  setState(() {
                    _query = v;
                    _categoryFilter = null;
                  });
                });
            },
            style: GoogleFonts.inter(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search products...',
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _query = '';
                          _categoryFilter = null;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Product>>(
        stream: widget.productService.getProductsStream(),
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
                ],
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var products = snap.data!;
          final q = _query.toLowerCase();
          if (q.isNotEmpty) {
            products = products.where((p) {
              return p.name.toLowerCase().contains(q) ||
                  p.category.toLowerCase().contains(q) ||
                  p.subcategory.toLowerCase().contains(q);
            }).toList();
          }
          if (widget.initialCategory != null && _categoryFilter == null) {
            products = products.where((p) =>
                p.category.toLowerCase() == widget.initialCategory!.toLowerCase()).toList();
          }

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 48, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  Text('No results found',
                      style: theme.textTheme.titleMedium),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final p = products[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(
                        product: p,
                        onAddToCart: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Added to cart'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ProductImage(
                          imageUrl: p.imagePath,
                          productName: p.name,
                          height: 56,
                          width: 56,
                          borderRadius: 6,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                '${p.category}${p.subcategory.isNotEmpty ? ' > ${p.subcategory}' : ''}',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Text('Rs. ${p.price.toStringAsFixed(2)}',
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF60cdff))),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
