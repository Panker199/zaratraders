import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/category.dart';
import '../../services/product_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _productService = ProductService();
  final _nameCtrl = TextEditingController();
  final _subCtrl = TextEditingController();
  final Set<String> _expanded = {};
  int _refreshKey = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subCtrl.dispose();
    super.dispose();
  }

  void _addCategory() {
    _nameCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: _nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Category name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _doAdd(ctx),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => _doAdd(ctx),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _doAdd(BuildContext ctx) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(ctx);
    try {
      await _productService.addCategory(name);
      if (mounted) {
        nav.pop();
        messenger.showSnackBar(
          SnackBar(content: Text('Category "$name" added'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _addSubCategory(Category cat) {
    _subCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Sub-Category to "${cat.name}"'),
        content: TextField(
          controller: _subCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Sub-category name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _doAddSub(ctx, cat),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => _doAddSub(ctx, cat),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _doAddSub(BuildContext ctx, Category cat) async {
    final name = _subCtrl.text.trim();
    if (name.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(ctx);
    try {
      await _productService.addSubCategory(cat.id, name);
      if (mounted) {
        nav.pop();
        messenger.showSnackBar(
          SnackBar(content: Text('Sub-category "$name" added'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _confirmDeleteCategory(Category cat) {
    showDialog(
      context: context,
      builder: (ctx) {
        var deleting = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Delete Category'),
            content: Text('Delete "${cat.name}"? Products in this category won\'t be deleted.'),
            actions: [
              TextButton(
                  onPressed: deleting ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: deleting
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(ctx);
                        setDialogState(() => deleting = true);
                        try {
                          await _productService.deleteCategory(cat.id);
                          if (mounted) nav.pop();
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Category "${cat.name}" deleted'),
                                  behavior: SnackBarBehavior.floating),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Failed: $e'),
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

  void _confirmDeleteSubCategory(Category cat, String sub) {
    showDialog(
      context: context,
      builder: (ctx) {
        var deleting = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Delete Sub-Category'),
            content: Text('Delete "$sub" from "${cat.name}"?'),
            actions: [
              TextButton(
                  onPressed: deleting ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: deleting
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(ctx);
                        setDialogState(() => deleting = true);
                        try {
                          await _productService.deleteSubCategory(cat.id, sub);
                          if (mounted) nav.pop();
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Sub-category "$sub" deleted'),
                                  behavior: SnackBarBehavior.floating),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Failed: $e'),
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
        title: Text('Categories',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _addCategory,
          ),
        ],
      ),
      body: StreamBuilder<List<Category>>(
        key: ValueKey('categories_$_refreshKey'),
        stream: _productService.getCategoriesStream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 12),
                  Text('Failed to load categories',
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
          final cats = snap.data!;
          if (cats.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No categories yet',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Category'),
                    onPressed: _addCategory,
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() => _refreshKey++),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cats.length,
              itemBuilder: (context, index) {
                final cat = cats[index];
                final isExpanded = _expanded.contains(cat.id);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(Icons.folder_outlined,
                              color: Colors.green.shade700, size: 20),
                        ),
                        title: Text(cat.name,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        subtitle: cat.subCategories.isNotEmpty
                            ? Text('${cat.subCategories.length} sub-categories',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.add_circle_outline,
                                  size: 18, color: Colors.blue.shade400),
                              onPressed: () => _addSubCategory(cat),
                              tooltip: 'Add sub-category',
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red.shade300),
                              onPressed: () => _confirmDeleteCategory(cat),
                              tooltip: 'Delete category',
                            ),
                            IconButton(
                              icon: Icon(isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                                  size: 18, color: Colors.grey.shade500),
                              onPressed: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expanded.remove(cat.id);
                                  } else {
                                    _expanded.add(cat.id);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      if (isExpanded && cat.subCategories.isNotEmpty)
                        ...cat.subCategories.map((sub) => Container(
                              padding: const EdgeInsets.only(left: 64, right: 16, bottom: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.subdirectory_arrow_right,
                                      size: 14, color: Colors.grey.shade400),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(sub,
                                        style: TextStyle(
                                            fontSize: 13, color: Colors.grey.shade700)),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline,
                                        size: 16, color: Colors.red.shade300),
                                    onPressed: () => _confirmDeleteSubCategory(cat, sub),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            )),
                      if (isExpanded && cat.subCategories.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 64, bottom: 8),
                          child: Text('No sub-categories',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
