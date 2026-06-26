import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/product.dart';
import '../../models/category.dart';
import '../../services/product_service.dart';
import '../../services/image_search_service.dart';
import '../barcode_scanner_screen.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;
  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _ratingCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _imageCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _skuCtrl;
  final _productService = ProductService();
  final _imageSearchService = ImageSearchService();
  bool _saving = false;
  List<Category> _categories = [];
  List<String> _subCategories = [];
  String _selectedSubcategory = '';
  List<String> _subItems = [];

  List<ImageSearchResult> _searchResults = [];
  bool _searchingImages = false;
  Timer? _debounce;
  String _lastSearchQuery = '';

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl =
        TextEditingController(text: p != null ? p.price.toString() : '');
    _stockCtrl =
        TextEditingController(text: p != null ? p.stock.toString() : '');
    _ratingCtrl =
        TextEditingController(text: p != null ? p.rating.toString() : '');
    _categoryCtrl = TextEditingController(text: p?.category ?? '');
    _imageCtrl = TextEditingController(text: p?.imagePath ?? '');
    _barcodeCtrl = TextEditingController(text: p?.barcode ?? '');
    _skuCtrl = TextEditingController(text: p?.sku ?? '');
    _subItems = p?.subItems.toList() ?? [];
    _selectedSubcategory = p?.subcategory ?? '';
    _loadCategories();

    _nameCtrl.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    final query = _nameCtrl.text.trim();
    if (query.length < 2 || query == _lastSearchQuery) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _searchImages(query);
    });
  }

  Future<void> _searchImages(String query) async {
    if (!mounted) return;
    setState(() { _searchingImages = true; _lastSearchQuery = query; });
    final results = await _imageSearchService.search(query);
    if (!mounted) return;
    setState(() { _searchResults = results; _searchingImages = false; });
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _productService.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _updateSubCategories();
        });
      }
    } catch (_) {}
  }

  void _updateSubCategories() {
    final selectedCat = _categories.where((c) => c.name == _categoryCtrl.text).firstOrNull;
    _subCategories = selectedCat?.subCategories ?? [];
    if (!_subCategories.contains(_selectedSubcategory)) {
      _selectedSubcategory = '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onNameChanged);
    _debounce?.cancel();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _ratingCtrl.dispose();
    _categoryCtrl.dispose();
    _imageCtrl.dispose();
    _barcodeCtrl.dispose();
    _skuCtrl.dispose();
    super.dispose();
  }

  Future<void> _addSubItem() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Sub-Item'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Lavender, 200ml, Single Pack',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isNotEmpty) {
                setState(() => _subItems.add(v));
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) return;
    if (_saving) return;
    setState(() => _saving = true);

    final priceText = _priceCtrl.text.trim();
    final stockText = _stockCtrl.text.trim();
    final price = double.tryParse(priceText);
    final stock = int.tryParse(stockText);
    if (price == null || stock == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid price or stock value')),
        );
      }
      if (mounted) setState(() => _saving = false);
      return;
    }

    final product = Product(
      id: widget.product?.id ?? '',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: price,
      stock: stock,
      rating: double.tryParse(_ratingCtrl.text.trim()) ?? 0.0,
      category: _categoryCtrl.text.trim(),
      subcategory: _selectedSubcategory,
      imagePath: _imageCtrl.text.trim(),
      barcode: _barcodeCtrl.text.trim(),
      sku: _skuCtrl.text.trim(),
      subItems: _subItems,
    );

    try {
      if (_isEditing) {
        await _productService.updateProduct(product);
      } else {
        await _productService.addProduct(product);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add Product',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildField('Product Name', _nameCtrl, theme,
                validator: (v) =>
                    v?.trim().isEmpty ?? true ? 'Required' : null),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildField('Barcode (optional)', _barcodeCtrl, theme),
                ),
                const SizedBox(width: 8),
                _scanButton('Scan', _barcodeCtrl, 'Scan Barcode'),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildField('SKU (optional)', _skuCtrl, theme),
                ),
                const SizedBox(width: 8),
                _scanButton('Scan', _skuCtrl, 'Scan SKU'),
              ],
            ),
            const SizedBox(height: 14),
            _buildField('Description', _descCtrl, theme, maxLines: 3,
                validator: (v) =>
                    v?.trim().isEmpty ?? true ? 'Required' : null),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildField('Price (Rs.)', _priceCtrl, theme,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) =>
                          v?.trim().isEmpty ?? true ? 'Required' : null),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField('Stock', _stockCtrl, theme,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v?.trim().isEmpty ?? true ? 'Required' : null),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField('Rating', _ratingCtrl, theme,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildField('Category', _categoryCtrl, theme,
                validator: (v) =>
                    v?.trim().isEmpty ?? true ? 'Required' : null),
            if (_categories.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _categories
                    .map((c) => ChoiceChip(
                          label: Text(c.name, style: const TextStyle(fontSize: 12)),
                          selected: _categoryCtrl.text == c.name,
                          onSelected: (sel) {
                            if (sel) {
                              setState(() {
                                _categoryCtrl.text = c.name;
                                _selectedSubcategory = '';
                                _updateSubCategories();
                              });
                            }
                          },
                        ))
                    .toList(),
              ),
            ],
            if (_subCategories.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Sub-Category',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _subCategories
                    .map((s) => ChoiceChip(
                          label: Text(s, style: const TextStyle(fontSize: 12)),
                          selected: _selectedSubcategory == s,
                          onSelected: (sel) {
                            if (sel) {
                              setState(() => _selectedSubcategory = s);
                            }
                          },
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 14),
            _buildField('Image URL (optional)', _imageCtrl, theme,
                onChanged: (v) {
              if (v.trim().length >= 2) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 600), () {
                  _searchImages(v.trim());
                });
              }
            }),

            // ── Auto Image Search Results ──
            if (_searchingImages) ...[
              const SizedBox(height: 12),
              const Row(
                children: [
                  SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Searching images...', style: TextStyle(fontSize: 13)),
                ],
              ),
            ],
            if (!_searchingImages && _searchResults.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text('Suggested images',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() { _searchResults = []; _lastSearchQuery = ''; }),
                    child: const Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final img = _searchResults[i];
                    final isSelected = _imageCtrl.text.trim() == img.fullUrl;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _imageCtrl.text = img.fullUrl);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Image selected!'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.green.shade600,
                          ),
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.grey.shade300,
                            width: isSelected ? 2.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )]
                              : null,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              img.thumbnail,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, __, progress) => Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                    child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2))),
                              ),
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_not_supported, size: 20),
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sub-Items / Variants',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  onPressed: _addSubItem,
                ),
              ],
            ),
            if (_subItems.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('No sub-items. Add variants like sizes, scents, etc.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              )
            else
              ...List.generate(_subItems.length, (i) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    dense: true,
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.vignette_outlined,
                          size: 16, color: Colors.teal.shade700),
                    ),
                    title: Text(_subItems[i],
                        style: const TextStyle(fontSize: 13)),
                    trailing: IconButton(
                      icon: Icon(Icons.close,
                          size: 16, color: Colors.red.shade300),
                      onPressed: () =>
                          setState(() => _subItems.removeAt(i)),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(_isEditing ? Icons.save : Icons.add),
              label: Text(_isEditing ? 'Save Changes' : 'Add Product'),
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _scanButton(String label, TextEditingController ctrl, String title) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.qr_code_scanner, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: () async {
          final result = await Navigator.of(context).push<String>(
            MaterialPageRoute(
              builder: (_) => BarcodeScannerScreen(title: title),
            ),
          );
          if (result != null && mounted) {
            setState(() => ctrl.text = result);
          }
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, ThemeData theme,
      {int maxLines = 1,
      TextInputType? keyboardType,
      String? Function(String?)? validator,
      ValueChanged<String>? onChanged}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      ),
    );
  }
}
