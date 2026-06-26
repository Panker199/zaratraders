import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/admin_service.dart';

class BrandsScreen extends StatefulWidget {
  const BrandsScreen({super.key});

  @override
  State<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends State<BrandsScreen> {
  final _adminService = AdminService();
  int _refreshKey = 0;

  void _showForm({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] as String? ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] as String? ?? '');
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (ctx) {
        var saving = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(isEdit ? 'Edit Brand' : 'Add Brand'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Brand name *', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
              ],
            ),
            actions: [
              TextButton(onPressed: saving ? null : () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              FilledButton(
                onPressed: saving ? null : () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  setDialogState(() => saving = true);
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(ctx);
                  final data = {'name': nameCtrl.text.trim(), 'description': descCtrl.text.trim()};
                  try {
                    if (isEdit) { await _adminService.updateBrand(existing['id'] as String, data); }
                    else { await _adminService.addBrand(data); }
                    if (mounted) navigator.pop();
                    if (mounted) messenger.showSnackBar(SnackBar(content: Text(isEdit ? 'Brand updated' : 'Brand added'), behavior: SnackBarBehavior.floating));
                  } catch (e) {
                    if (mounted) messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), behavior: SnackBarBehavior.floating));
                  }
                },
                child: saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(isEdit ? 'Save' : 'Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) {
        var deleting = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Delete Brand'),
            content: Text('Delete "$name"?'),
            actions: [
              TextButton(onPressed: deleting ? null : () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              FilledButton(
                onPressed: deleting ? null : () async {
                  setDialogState(() => deleting = true);
                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(ctx);
                  try {
                    await _adminService.deleteBrand(id);
                    if (mounted) nav.pop();
                    if (mounted) messenger.showSnackBar(SnackBar(content: Text('"$name" deleted'), behavior: SnackBarBehavior.floating));
                  } catch (e) {
                    if (mounted) messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), behavior: SnackBarBehavior.floating));
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
        title: Text('Brands', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: const Icon(Icons.add_rounded), onPressed: () => _showForm())],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        key: ValueKey('brands_$_refreshKey'),
        stream: _adminService.getBrandsStream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text('Failed to load brands', style: TextStyle(color: Colors.red.shade600)),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: () => setState(() => _refreshKey++), child: const Text('Retry')),
            ]));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data;
          if (items == null || items.isEmpty) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.branding_watermark_outlined, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('No brands yet', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade500)),
              const SizedBox(height: 8),
              FilledButton.icon(icon: const Icon(Icons.add, size: 18), label: const Text('Add Brand'), onPressed: () => _showForm()),
            ]));
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() => _refreshKey++),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final b = items[index];
                final name = b['name'] as String? ?? '';
                final desc = b['description'] as String? ?? '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(6)),
                      child: Icon(Icons.branding_watermark_outlined, color: Colors.amber.shade700, size: 20),
                    ),
                    title: Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: desc.isNotEmpty
                        ? Text(desc, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade500), onPressed: () => _showForm(existing: b)),
                        IconButton(icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade300), onPressed: () => _confirmDelete(b['id'] as String, name)),
                      ],
                    ),
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
