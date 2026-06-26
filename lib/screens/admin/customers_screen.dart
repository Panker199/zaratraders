import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/admin_service.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _adminService = AdminService();
  int _refreshKey = 0;

  void _showForm({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] as String? ?? '');
    final phoneCtrl = TextEditingController(text: existing?['phoneNumber'] as String? ?? '');
    final emailCtrl = TextEditingController(text: existing?['email'] as String? ?? '');
    final addressCtrl = TextEditingController(text: existing?['address'] as String? ?? '');
    final balanceCtrl = TextEditingController(text: existing?['balance']?.toString() ?? '');
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (ctx) {
        var saving = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(isEdit ? 'Edit Customer' : 'Add Customer'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
                  const SizedBox(height: 10),
                  TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 10),
                  TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: balanceCtrl, decoration: const InputDecoration(labelText: 'Balance', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: saving ? null : () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              FilledButton(
                onPressed: saving ? null : () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  setDialogState(() => saving = true);
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(ctx);
                  final data = {
                    'name': nameCtrl.text.trim(),
                    'phoneNumber': phoneCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'address': addressCtrl.text.trim(),
                    'balance': double.tryParse(balanceCtrl.text.trim()) ?? 0,
                  };
                  try {
                    if (isEdit) {
                      await _adminService.updateCustomer(existing['id'] as String, data);
                    } else {
                      await _adminService.addCustomer(data);
                    }
                    if (mounted) navigator.pop();
                    if (mounted) messenger.showSnackBar(SnackBar(content: Text(isEdit ? 'Customer updated' : 'Customer added'), behavior: SnackBarBehavior.floating));
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
            title: const Text('Delete Customer'),
            content: Text('Delete "$name"?'),
            actions: [
              TextButton(onPressed: deleting ? null : () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              FilledButton(
                onPressed: deleting ? null : () async {
                  setDialogState(() => deleting = true);
                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(ctx);
                  try {
                    await _adminService.deleteCustomer(id);
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
        title: Text('Customers', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: const Icon(Icons.add_rounded), onPressed: () => _showForm())],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        key: ValueKey('customers_$_refreshKey'),
        stream: _adminService.getCustomersStream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text('Failed to load customers', style: TextStyle(color: Colors.red.shade600)),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: () => setState(() => _refreshKey++), child: const Text('Retry')),
            ]));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data;
          if (items == null || items.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('No customers yet', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade500)),
              const SizedBox(height: 8),
              FilledButton.icon(icon: const Icon(Icons.add, size: 18), label: const Text('Add Customer'), onPressed: () => _showForm()),
            ]));
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() => _refreshKey++),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final c = items[index];
                final name = c['name'] as String? ?? '';
                final phone = c['phoneNumber'] as String? ?? '';
                final address = c['address'] as String? ?? '';
                final balance = (c['balance'] as num?)?.toDouble() ?? 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(6)),
                      child: Icon(Icons.person_outline, color: Colors.indigo.shade700, size: 20),
                    ),
                    title: Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text([if (phone.isNotEmpty) phone, if (address.isNotEmpty) address, 'Balance: Rs${balance.toStringAsFixed(0)}'].join('  •  '),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade500), onPressed: () => _showForm(existing: c)),
                        IconButton(icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade300), onPressed: () => _confirmDelete(c['id'] as String, name)),
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
