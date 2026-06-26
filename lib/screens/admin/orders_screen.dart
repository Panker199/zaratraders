import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/admin_service.dart';
import '../order_tracking_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _adminService = AdminService();
  String _statusFilter = 'all';
  int _refreshKey = 0;
  final Set<String> _processing = {};

  Future<void> _updateStatus(String id, String status) async {
    if (_processing.contains(id)) return;
    setState(() => _processing.add(id));
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _adminService.updateOrderStatus(id, status);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Order $status'),
            behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update: $e'),
            behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _processing.remove(id));
    }
  }

  void _confirmDelete(String id) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) {
        final nav = Navigator.of(ctx);
        var deleting = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Delete Order'),
            content: const Text('Delete this order permanently?'),
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
                          await _adminService.deleteOrder(id);
                          if (mounted) nav.pop();
                          if (mounted) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Order deleted'),
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'shipped': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Orders',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        key: ValueKey('orders_$_refreshKey'),
        stream: _adminService.getOrdersStream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 12),
                  Text('Failed to load orders',
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
          var orders = snap.data!;
          if (_statusFilter != 'all') {
            orders = orders.where((o) =>
                (o['status'] as String? ?? '').toLowerCase() == _statusFilter).toList();
          }

          final statuses = ['all', 'pending', 'confirmed', 'shipped', 'delivered', 'cancelled'];

          return RefreshIndicator(
            onRefresh: () async => setState(() => _refreshKey++),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: statuses.map((s) {
                          final active = _statusFilter == s;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(s == 'all' ? 'All' : s[0].toUpperCase() + s.substring(1),
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                                      color: active ? Colors.white : null)),
                              selected: active,
                              onSelected: (_) => setState(() => _statusFilter = s),
                              selectedColor: _statusColor(s == 'all' ? 'pending' : s),
                              checkmarkColor: Colors.white,
                              backgroundColor: Colors.white,
                              side: BorderSide.none,
                              visualDensity: VisualDensity.compact,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                if (orders.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('No orders ${_statusFilter == 'all' ? 'yet' : 'with this status'}',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final o = orders[index];
                        final status = o['status'] as String? ?? 'pending';
                        final items = o['items'] as List<dynamic>? ?? [];
                        final total = o['total'] as num? ?? 0.0;
                        final createdAt = o['createdAt'];
                        String dateStr = 'Unknown';
                        if (createdAt != null) {
                          if (createdAt is Timestamp) {
                            dateStr = createdAt.toDate().toString().substring(0, 16);
                          } else {
                            dateStr = createdAt.toString().substring(0, 16);
                          }
                        }

                        return Card(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: ExpansionTile(
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _statusColor(status).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(Icons.receipt_outlined,
                                  color: _statusColor(status), size: 20),
                            ),
                            title: Text(() {
                              final id = o['id'] as String? ?? '';
                              return 'Order #${id.length > 18 ? id.substring(0, 18) : id}';
                            }(),
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            subtitle: Text('Rs. ${total.toStringAsFixed(2)}  •  $dateStr',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(status.toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _statusColor(status))),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(),
                                    if (o['customerName'] != null)
                                      _detailRow('Customer', '${o['customerName']}'),
                                    if (o['customerEmail'] != null)
                                      _detailRow('Email', '${o['customerEmail']}'),
                                    if (o['address'] != null)
                                      _detailRow('Address', '${o['address']}'),
                                    if (o['paymentMethod'] != null)
                                      _detailRow('Payment', '${o['paymentMethod']}${o['paymentStatus'] == 'paid' ? ' (Paid)' : ' (Pending)'}'),
                                    const SizedBox(height: 8),
                                    Text('Items (${items.length}):',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(fontWeight: FontWeight.w600)),
                                    ...items.map((item) => Padding(
                                          padding: const EdgeInsets.only(left: 8, top: 2),
                                          child: Text(
                                              '• ${item['name'] ?? 'Item'} x${item['quantity'] ?? 1} — Rs. ${((item['price'] as num? ?? 0) * (item['quantity'] as int? ?? 1)).toStringAsFixed(2)}',
                                              style: theme.textTheme.bodySmall),
                                        )),
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text('Total: Rs. ${total.toStringAsFixed(2)}',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _actionChip('Track', Colors.teal, () {
                                          Navigator.of(context).push(MaterialPageRoute(
                                            builder: (_) => OrderTrackingScreen(order: o),
                                          ));
                                        }, outlined: true),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (status == 'pending')
                                              _actionChip('Confirm', Colors.blue, () => _updateStatus(o['id'] as String, 'confirmed'), disabled: _processing.contains(o['id'])),
                                            if (status == 'confirmed')
                                              _actionChip('Ship', Colors.purple, () => _updateStatus(o['id'] as String, 'shipped'), disabled: _processing.contains(o['id'])),
                                            if (status == 'shipped')
                                              _actionChip('Deliver', Colors.green, () => _updateStatus(o['id'] as String, 'delivered'), disabled: _processing.contains(o['id'])),
                                            const SizedBox(width: 6),
                                            if (status != 'delivered' && status != 'cancelled')
                                              _actionChip('Cancel', Colors.red, () => _updateStatus(o['id'] as String, 'cancelled'), outlined: true, disabled: _processing.contains(o['id'])),
                                            const SizedBox(width: 6),
                                            if (status == 'cancelled' || status == 'delivered')
                                              IconButton(
                                                icon: _processing.contains(o['id'])
                                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                                    : Icon(Icons.delete_outline, size: 18, color: Colors.red.shade300),
                                                onPressed: _processing.contains(o['id']) ? null : () => _confirmDelete(o['id'] as String),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: orders.length,
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text('$label: ',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _actionChip(String label, Color color, VoidCallback onTap, {bool outlined = false, bool disabled = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: disabled ? Colors.grey.shade200 : (outlined ? Colors.transparent : color),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: disabled ? Colors.grey.shade300 : color),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: disabled ? Colors.grey.shade400 : (outlined ? color : Colors.white))),
        ),
      ),
    );
  }
}
