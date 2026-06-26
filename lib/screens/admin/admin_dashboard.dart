import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/product.dart';
import '../../services/auth_service.dart';
import '../../theme/theme_provider.dart';
import '../../services/product_service.dart';
import '../../services/admin_service.dart';
import '../../services/support_service.dart';
import 'products_screen.dart';
import 'users_screen.dart';
import 'categories_screen.dart';
import 'orders_screen.dart';
import 'messages_screen.dart';
import 'warehouses_screen.dart';
import 'customers_screen.dart';
import 'suppliers_screen.dart';
import 'brands_screen.dart';
import 'units_screen.dart';
import 'database_control_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _productService = ProductService();
  final _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel',
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
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(user.name,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary)),
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
      body: RefreshIndicator(
        onRefresh: () async {
          _loadStats();
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionLabel('Quick Actions'),
            const SizedBox(height: 10),
            SizedBox(
              height: 90,
              child: Row(
                children: [
                  Expanded(
                      child: _actionCard(theme, 'Products',
                          Icons.inventory_2_rounded, Colors.blue, () {
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProductsScreen()));
                  })),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _actionCard(theme, 'Categories',
                          Icons.category_rounded, Colors.green, () {
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CategoriesScreen()));
                  })),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _actionCard(
                          theme, 'Users', Icons.people_rounded, Colors.purple, () {
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const UsersScreen()));
                  })),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 90,
              child: Row(
                children: [
                  Expanded(
                      child: _actionCard(
                          theme, 'Orders', Icons.receipt_long_rounded, Colors.deepOrange, () {
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const OrdersScreen()));
                  })),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _actionCard(theme, 'Warehouses',
                          Icons.warehouse_rounded, Colors.teal, () {
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const WarehousesScreen()));
                  })),
                  Expanded(
                      child: _actionCard(theme, 'Set Images',
                          Icons.image_rounded, Colors.indigo, () {
                    _updateProductImages();
                  })),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 90,
              child: Row(
                children: [
                  Expanded(
                      child: _actionCard(theme, 'Tickets',
                          Icons.support_agent_rounded, Colors.teal, () {
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdminMessagesScreen()));
                  })),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _actionCard(theme, 'Units',
                          Icons.straighten_outlined, Colors.green, () {
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const UnitsScreen()));
                  })),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _actionCard(theme, 'Database',
                          Icons.storage_rounded, const Color(0xFF2E7D32), () {
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DatabaseControlScreen()));
                  })),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 90,
              child: Row(
                children: [
                  Expanded(
                      child: _actionCard(theme, 'Customers',
                          Icons.people_alt_outlined, Colors.indigo, () {
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CustomersScreen()));
                  })),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _actionCard(theme, 'Suppliers',
                          Icons.local_shipping_outlined, Colors.orange, () {
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SuppliersScreen()));
                  })),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _actionCard(theme, 'Brands',
                          Icons.branding_watermark_outlined, Colors.amber, () {
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BrandsScreen()));
                  })),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionLabel('Overview'),
            const SizedBox(height: 10),
            _DashboardStats(service: _productService, adminService: _adminService),
            const SizedBox(height: 24),
            _sectionLabel('Analytics'),
            const SizedBox(height: 10),
            _AnalyticsSection(service: _productService, adminService: _adminService),
            const SizedBox(height: 24),
            _sectionLabel('Low Stock Alerts'),
            const SizedBox(height: 10),
            _LowStockSection(service: _productService),
            const SizedBox(height: 24),
            _sectionLabel('Recent Orders'),
            const SizedBox(height: 10),
            _RecentOrdersSection(service: _adminService),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _loadStats() async {
    setState(() => _refreshKey++);
  }

  int _refreshKey = 0;

  Future<void> _updateProductImages() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update All Product Images?'),
        content: const Text('This will replace all product image URLs with real images from picsum.photos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Update')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updating images...')));
    final count = await _adminService.updateProductImages();
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count product images updated')));
    }
  }

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4, height: 16,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(text.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.0, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _actionCard(
      ThemeData theme, String label, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 6),
                Text(label,
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

class _DashboardStats extends StatelessWidget {
  final ProductService service;
  final AdminService adminService;
  const _DashboardStats({required this.service, required this.adminService});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<Product>>(
      stream: service.getProductsStream(),
      builder: (context, snap) {
        final productCount = snap.data?.length ?? 0;
        return FutureBuilder<int>(
          future: adminService.getUserCount(),
          builder: (context, userSnap) {
            final userCount = userSnap.data ?? 0;
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _StatCard(theme, Icons.inventory_2_rounded,
                            '$productCount', 'Total Products', Colors.blue)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _StatCard(theme, Icons.people_rounded,
                            '$userCount', 'Users', Colors.purple)),
                  ],
                ),
                const SizedBox(height: 10),
                StreamBuilder<int>(
                  stream: SupportService().getOpenTicketCountStream(),
                  builder: (context, ticketSnap) {
                    final open = ticketSnap.data ?? 0;
                    return Row(
                      children: [
                        Expanded(
                            child: _StatCard(theme, Icons.support_agent_rounded,
                                '$open', 'Open Tickets', open > 0 ? Colors.orange : Colors.teal)),
                        const SizedBox(width: 10),
                        const Expanded(child: SizedBox()),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _AnalyticsSection extends StatelessWidget {
  final ProductService service;
  final AdminService adminService;
  const _AnalyticsSection({required this.service, required this.adminService});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<Product>>(
      stream: service.getProductsStream(),
      builder: (context, prodSnap) {
        final products = prodSnap.data ?? <Product>[];
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: adminService.getOrdersStream(),
          builder: (context, orderSnap) {
            final orders = orderSnap.data ?? <Map<String, dynamic>>[];
            final orderCount = orders.length;
            final revenue = _calcRevenue(orders);
            final statusCounts = _calcStatusCounts(orders);
            final categoryCounts = _calcCategoryCounts(products);
            final hasOrders = statusCounts.values.any((c) => c > 0);
            final hasCategories = categoryCounts.entries.any((e) => e.value > 0);

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _StatCard(theme, Icons.receipt_long_rounded,
                            '$orderCount', 'Total Orders', Colors.deepOrange)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _StatCard(theme, Icons.currency_rupee,
                            'Rs. ${revenue.toStringAsFixed(0)}', 'Revenue', Colors.green)),
                  ],
                ),
                if (hasOrders || hasCategories) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        if (hasOrders)
                          Expanded(child: _StatusBarChart(theme: theme, statusCounts: statusCounts)),
                        if (hasOrders && hasCategories) const SizedBox(width: 12),
                        if (hasCategories)
                          Expanded(child: _CategoryPieChart(theme: theme, categoryCounts: categoryCounts)),
                      ],
                    ),
                  ),
                ],
                if (!hasOrders && !hasCategories)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text('No analytics data yet',
                            style: TextStyle(color: Colors.grey.shade500)),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  double _calcRevenue(List<Map<String, dynamic>> orders) {
    double total = 0;
    for (final o in orders) {
      final s = o['status'] as String? ?? '';
      if (['delivered', 'shipped', 'confirmed'].contains(s)) {
        total += (o['total'] as num?)?.toDouble() ?? 0;
      }
    }
    return total;
  }

  Map<String, int> _calcStatusCounts(List<Map<String, dynamic>> orders) {
    final counts = <String, int>{};
    for (final o in orders) {
      final s = o['status'] as String? ?? 'pending';
      counts[s] = (counts[s] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> _calcCategoryCounts(List<Product> products) {
    final counts = <String, int>{};
    for (final p in products) {
      counts[p.category] = (counts[p.category] ?? 0) + 1;
    }
    return counts;
  }
}

class _LowStockSection extends StatelessWidget {
  final ProductService service;
  const _LowStockSection({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<Product>>(
      stream: service.getProductsStream(),
      builder: (context, snap) {
        final products = snap.data ?? <Product>[];
        final lowStock = products.where((p) => p.stock < 10).toList();
        final outOfStock = products.where((p) => p.stock == 0).toList();
        final displayLow = lowStock.take(3).toList();

        return Column(
          children: [
            if (displayLow.isNotEmpty) ...[
              ...displayLow.map((p) => _alertTile(theme, p)),
              if (lowStock.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProductsScreen())),
                    child: Text('View all ${lowStock.length} low stock items'),
                  ),
                ),
            ],
            if (outOfStock.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('${outOfStock.length} product(s) out of stock',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade700,
                              fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _RecentOrdersSection extends StatelessWidget {
  final AdminService service;
  const _RecentOrdersSection({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.getOrdersStream(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('No orders yet',
                    style: TextStyle(color: Colors.grey.shade500)),
              ),
            ),
          );
        }
        final recentOrders = snap.data!.take(5).toList();
        return Column(
          children: recentOrders.map((o) => _recentOrderTile(theme, o)).toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard(this.theme, this.icon, this.value, this.label, this.color);

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
                  style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBarChart extends StatelessWidget {
  final ThemeData theme;
  final Map<String, int> statusCounts;
  const _StatusBarChart({required this.theme, required this.statusCounts});

  @override
  Widget build(BuildContext context) {
    final statuses = ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'];
    final colors = [Colors.orange, Colors.blue, Colors.purple, Colors.green, Colors.red];
    final maxVal = statusCounts.values.fold<int>(1, (a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Orders by Status',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (maxVal * 1.3).ceilToDouble(),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= statuses.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(statuses[idx].substring(0, 3),
                                style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 22, getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString(),
                            style: TextStyle(fontSize: 9, color: Colors.grey.shade500));
                      }),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxVal > 5 ? (maxVal / 3).ceilToDouble() : 1,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(statuses.length, (i) {
                    final count = statusCounts[statuses[i]] ?? 0;
                    return BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: count.toDouble(),
                        color: colors[i],
                        width: 14,
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                      ),
                    ]);
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final ThemeData theme;
  final Map<String, int> categoryCounts;
  const _CategoryPieChart({required this.theme, required this.categoryCounts});

  @override
  Widget build(BuildContext context) {
    final entries = categoryCounts.entries.toList();
    final pieColors = [
      Colors.blue, Colors.green, Colors.orange, Colors.purple,
      Colors.teal, Colors.pink, Colors.indigo, Colors.amber,
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Categories',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: List.generate(entries.length, (i) {
                    final isSmall = entries[i].value < 2;
                    return PieChartSectionData(
                      color: pieColors[i % pieColors.length],
                      value: entries[i].value.toDouble(),
                      title: isSmall ? '' : entries[i].key,
                      radius: isSmall ? 16 : 24,
                      titleStyle: TextStyle(
                          fontSize: isSmall ? 0 : 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    );
                  }),
                  centerSpaceRadius: 20,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _alertTile(ThemeData theme, Product p) {
  final isOut = p.stock == 0;
  return Card(
    margin: const EdgeInsets.only(bottom: 6),
    child: ListTile(
      dense: true,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isOut ? Colors.red.shade50 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(Icons.inventory_2_outlined,
            size: 18,
            color: isOut ? Colors.red.shade600 : Colors.orange.shade600),
      ),
      title: Text(p.name,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isOut ? Colors.red.shade50 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text('${p.stock} left',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isOut ? Colors.red.shade700 : Colors.orange.shade700)),
      ),
    ),
  );
}

Widget _recentOrderTile(ThemeData theme, Map<String, dynamic> o) {
  final total = o['total'] as num? ?? 0;
  final status = o['status'] as String? ?? 'pending';
  final name = o['customerName'] as String? ?? 'Unknown';
  return Card(
    margin: const EdgeInsets.only(bottom: 6),
    child: ListTile(
      dense: true,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.deepOrange.shade50,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(Icons.receipt_outlined,
            size: 18, color: Colors.deepOrange.shade600),
      ),
      title: Text(name,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text('Rs. ${total.toStringAsFixed(2)}',
          style: theme.textTheme.bodySmall),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: _statusColor(status).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(status.toUpperCase(),
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _statusColor(status))),
      ),
    ),
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
