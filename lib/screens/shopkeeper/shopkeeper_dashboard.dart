import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';
import '../../services/product_service.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/product_image.dart';
import '../order_tracking_screen.dart';
import 'inventory_screen.dart';
import 'store_screen.dart';
import 'messages_screen.dart';
import 'help_support_screen.dart';

class ShopkeeperDashboard extends StatefulWidget {
  const ShopkeeperDashboard({super.key});

  @override
  State<ShopkeeperDashboard> createState() => _ShopkeeperDashboardState();
}

class _ShopkeeperDashboardState extends State<ShopkeeperDashboard> {
  final _productService = ProductService();
  final _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, tp, _) => IconButton(
              icon: Icon(tp.icon, size: 20),
              tooltip: '${tp.label} mode',
              onPressed: tp.toggle,
            ),
          ),
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(user.name,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8D6E00))),
                ),
              ),
            ),
          if (user != null)
            IconButton(
              icon: const Icon(Icons.logout_rounded, size: 20),
              onPressed: () async {
                try {
                  await auth.logout();
                } catch (_) {}
              },
            ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: _productService.getProductsStream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 12),
                  Text('Failed to load data',
                      style: TextStyle(color: Colors.red.shade600)),
                ],
              ),
            );
          }
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snap.data ?? <Product>[];
          final lowStock = products.where((p) => p.stock < 10).map((p) => p.id).toSet();
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const _QuickActions(),
                    const SizedBox(height: 20),
                    const _SectionLabel('Overview'),
                    const SizedBox(height: 10),
                    _StatsSection(products: products),
                    const SizedBox(height: 20),
                    const _SectionLabel('Recent Orders'),
                    const SizedBox(height: 10),
                    _OrderHistorySection(service: _adminService),
                    const SizedBox(height: 20),
                    _ProductListHeader(productCount: products.length),
                    const SizedBox(height: 8),
                  ]),
                ),
              ),
              _ProductListSliver(products: products, lowStock: lowStock),
              const SliverPadding(
                padding: EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(child: SizedBox(height: 24)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions',
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF888888),
                letterSpacing: 0.5)),
        const SizedBox(height: 10),
        Column(
          children: [
            Row(
              children: [
                Expanded(child: _ActionCard(theme, 'Store', Icons.store_rounded, Colors.blue, () {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StoreScreen()));
                })),
                const SizedBox(width: 10),
                Expanded(child: _ActionCard(theme, 'Inventory', Icons.inventory_2_rounded, Colors.orange, () {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const InventoryScreen()));
                })),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _ActionCard(theme, 'My Orders', Icons.receipt_long_rounded, Colors.deepOrange, () {
                  _showMyOrders(context);
                })),
                const SizedBox(width: 10),
                Expanded(child: _ActionCard(theme, 'Messages', Icons.chat_rounded, Colors.teal, () {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MessagesScreen()));
                })),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _ActionCard(theme, 'Help & Support', Icons.support_agent_rounded, Colors.indigo, () {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
                })),
                const Spacer(),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

void _showMyOrders(BuildContext context) {
  final adminService = AdminService();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('My Orders',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: adminService.getOrdersStream(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(child: Text('Failed to load orders',
                          style: TextStyle(color: Colors.red.shade500)));
                    }
                    if (!snap.hasData || snap.data!.isEmpty) {
                      return Center(child: Text('No orders yet',
                          style: TextStyle(color: Colors.grey.shade500)));
                    }
                    return ListView.separated(
                      controller: scrollController,
                      itemCount: snap.data!.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final o = snap.data![i];
                        final status = o['status'] as String? ?? 'pending';
                        final total = o['total'] as num? ?? 0;
                        final id = o['id'] as String? ?? '';
                        return ListTile(
                          leading: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: _statusColor(status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.receipt_outlined,
                                color: _statusColor(status), size: 20),
                          ),
                          title: Text('Order #${id.length > 6 ? id.substring(0, 6) : id}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(status.toUpperCase(),
                              style: TextStyle(fontSize: 11, color: _statusColor(status))),
                          trailing: Text('Rs. ${total.toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: o)),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _ActionCard extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard(this.theme, this.label, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.06),
                color.withValues(alpha: 0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 5),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final List<Product> products;
  const _StatsSection({required this.products});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalStock = products.fold<int>(0, (s, p) => s + p.stock);
    final totalValue = products.fold<double>(0, (s, p) => s + p.price * p.stock);
    final lowStock = products.where((p) => p.stock < 10).length;
    final outOfStock = products.where((p) => p.stock == 0).toList();

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(theme: theme, icon: Icons.inventory_outlined, value: '$totalStock units',
                label: 'Total Stock', color: const Color(0xFF60cdff))),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(theme: theme, icon: Icons.currency_rupee, value: 'Rs. ${totalValue.toStringAsFixed(0)}',
                label: 'Inventory Value', color: const Color(0xFF2E7D32))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _StatCard(theme: theme, icon: Icons.warning_amber_outlined, value: '$lowStock items',
                label: 'Low Stock', color: lowStock > 0 ? const Color(0xFFC62828) : const Color(0xFF2E7D32))),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(theme: theme, icon: Icons.shopping_bag_outlined, value: '${products.length}',
                label: 'Total Products', color: Colors.blue.shade700)),
          ],
        ),
        if (outOfStock.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 10),
                Text('${outOfStock.length} product(s) out of stock',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red.shade700, fontSize: 13)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({required this.theme, required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.08),
              color.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 8),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 4, height: 16,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(text.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.0, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _OrderHistorySection extends StatelessWidget {
  final AdminService service;
  const _OrderHistorySection({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.getOrdersStream(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text('Failed to load orders', style: TextStyle(color: Colors.red.shade500)),
              ),
            ),
          );
        }
        if (!snap.hasData || snap.data!.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text('No orders yet', style: TextStyle(color: Colors.grey.shade500)),
              ),
            ),
          );
        }
        final orders = snap.data!.take(5).toList();
        return Column(
          children: orders.map((o) {
            final status = o['status'] as String? ?? 'pending';
            final total = o['total'] as num? ?? 0;
            final name = o['customerName'] as String? ?? 'Unknown';
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              key: ValueKey(o['id']),
              child: ListTile(
                dense: true,
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.receipt_outlined, size: 18, color: _statusColor(status)),
                ),
                title: Text(name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('Rs. ${total.toStringAsFixed(2)}${o['paymentMethod'] != null ? '  •  ${o['paymentMethod']}' : ''}', style: theme.textTheme.bodySmall),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(status.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(status))),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: o)),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ProductListHeader extends StatelessWidget {
  final int productCount;
  const _ProductListHeader({required this.productCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Inventory',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        if (productCount > 5)
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InventoryScreen())),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('View All', style: TextStyle(fontSize: 13)),
                const Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
      ],
    );
  }
}

class _ProductListSliver extends StatelessWidget {
  final List<Product> products;
  final Set<String> lowStock;
  const _ProductListSliver({required this.products, required this.lowStock});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final displayCount = products.length > 4 ? 4 : products.length;
    final theme = Theme.of(context);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.82,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final p = products[index];
            final isLow = lowStock.contains(p.id);
            return Card(
              clipBehavior: Clip.antiAlias,
              elevation: 1,
              margin: EdgeInsets.zero,
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
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('${p.stock}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                    child: Text(p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                    child: Text('Rs. ${p.price.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF60cdff))),
                  ),
                ],
              ),
            );
          },
          childCount: displayCount,
        ),
      ),
    );
  }
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
