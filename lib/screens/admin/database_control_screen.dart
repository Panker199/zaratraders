import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/admin_service.dart';
import '../../services/database_setup_service.dart';
import '../../services/migration_service.dart';
import 'collection_detail_screen.dart';

class DatabaseControlScreen extends StatefulWidget {
  const DatabaseControlScreen({super.key});

  @override
  State<DatabaseControlScreen> createState() => _DatabaseControlScreenState();
}

class _DatabaseControlScreenState extends State<DatabaseControlScreen> {
  final _adminService = AdminService();
  final _dbSetup = DatabaseSetupService();
  final _migration = MigrationService();

  Map<String, int>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() { _loading = true; _error = null; });
    try {
      final stats = await _adminService.getCollectionStats();
      if (mounted) setState(() { _stats = stats; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _seedDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seed Database?'),
        content: const Text('Create sample data for customers, suppliers, brands, units, categories, warehouses, products, and a demo support ticket.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Seed')),
        ],
      ),
    );
    if (confirm != true) return;
    _showProgress('Seeding database...');
    try {
      final counts = await _dbSetup.seedCollections();
      _hideProgress();
      _showResult('Database seeded', counts.entries.map((e) => '${e.key}: ${e.value}').join('\n'));
      _loadStats();
    } catch (e) {
      _hideProgress();
      _showError('Seed failed: $e');
    }
  }

  Future<void> _seedPersonalCare() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seed Personal Care?'),
        content: const Text('Add 12 hygiene/personal care categories with subcategories, 26+ brands, and 40+ products with images (Shampoo, Soap, Hand Wash, Face Wash, Creams, Diapers, Wipes, Feeders, Toothpaste, Toothbrush, Tissue).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Seed')),
        ],
      ),
    );
    if (confirm != true) return;
    _showProgress('Seeding personal care data...');
    try {
      final counts = await _dbSetup.seedPersonalCareCollections();
      _hideProgress();
      _showResult('Personal Care Seeded', counts.entries.map((e) => '${e.key}: ${e.value}').join('\n'));
      _loadStats();
    } catch (e) {
      _hideProgress();
      _showError('Seed failed: $e');
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Collections?'),
        content: const Text('This will permanently delete ALL documents in all collections. Users and orders will also be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    _showProgress('Clearing all data...');
    try {
      await _dbSetup.clearAllCollections();
      _hideProgress();
      _showResult('Cleared', 'All collections have been emptied.');
      _loadStats();
    } catch (e) {
      _hideProgress();
      _showError('Clear failed: $e');
    }
  }

  Future<void> _migrateUsers() async {
    _showProgress('Migrating user fields...');
    try {
      final count = await _migration.migrateUserFields();
      _hideProgress();
      _showResult('Migration complete', '$count users updated with firstName/lastName.');
      _loadStats();
    } catch (e) {
      _hideProgress();
      _showError('Migration failed: $e');
    }
  }

  Future<void> _migrateMessages() async {
    _showProgress('Migrating messages...');
    try {
      final count = await _migration.migrateMessages();
      _hideProgress();
      _showResult('Migration complete', '$count messages migrated to subcollections.');
      _loadStats();
    } catch (e) {
      _hideProgress();
      _showError('Migration failed: $e');
    }
  }

  Future<void> _updateImages() async {
    _showProgress('Updating product images...');
    try {
      final count = await _adminService.updateProductImages();
      _hideProgress();
      _showResult('Images updated', '$count products now have picsum image URLs.');
    } catch (e) {
      _hideProgress();
      _showError('Update failed: $e');
    }
  }

  OverlayEntry? _overlay;
  void _showProgress(String msg) {
    _overlay?.remove();
    _overlay = OverlayEntry(
      builder: (_) => Material(
        color: Colors.black54,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(msg, style: GoogleFonts.inter(fontSize: 16)),
              ]),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _hideProgress() => _overlay?.remove();
  void _showResult(String title, String body) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }
  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Database Control', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadStats),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 12), Text('$_error'),
                  const SizedBox(height: 8),
                  OutlinedButton(onPressed: _loadStats, child: const Text('Retry')),
                ]))
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Section: Collections Overview
                      _sectionLabel(theme, 'Collections Overview'),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, childAspectRatio: 1.1, crossAxisSpacing: 8, mainAxisSpacing: 8,
                        ),
                        itemCount: AdminService.collectionMeta.length,
                        itemBuilder: (context, index) {
                          final meta = AdminService.collectionMeta[index];
                          final name = meta['name'] as String;
                          final icon = meta['icon'] as IconData;
                          final color = meta['color'] as Color;
                          final count = _stats?[name] ?? 0;
                          final isError = count == -1;
                          return Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => CollectionDetailScreen(
                                  collectionName: name, icon: icon, color: color,
                                )),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(icon, color: color, size: 24),
                                    const SizedBox(height: 6),
                                    Text(
                                      isError ? '?' : count.toString(),
                                      style: GoogleFonts.inter(
                                        fontSize: 20, fontWeight: FontWeight.bold, color: isError ? Colors.red : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      name.replaceAll('_', ' '),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                                      maxLines: 2, overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Section: Actions
                      _sectionLabel(theme, 'Database Actions'),
                      const SizedBox(height: 12),
                      _actionButton(theme, Icons.storage_rounded, const Color(0xFF2E7D32), 'Seed Database', 'Create sample data for all collections', _seedDatabase),
                      const SizedBox(height: 8),
                      _actionButton(theme, Icons.spa_rounded, const Color(0xFF00897B), 'Seed Personal Care', 'Add 12 hygiene categories, 26+ brands, 40+ products with images', _seedPersonalCare),
                      const SizedBox(height: 8),
                      _actionButton(theme, Icons.delete_sweep_rounded, Colors.red, 'Clear All Collections', 'Permanently delete all documents', _clearAll),
                      const SizedBox(height: 24),

                      _sectionLabel(theme, 'Migrations & Maintenance'),
                      const SizedBox(height: 12),
                      _actionButton(theme, Icons.upgrade_rounded, Colors.brown, 'Migrate User Fields', 'Add firstName/lastName to existing users', _migrateUsers),
                      const SizedBox(height: 8),
                      _actionButton(theme, Icons.forum_rounded, Colors.deepPurple, 'Migrate Messages', 'Move old messages to ticket subcollections', _migrateMessages),
                      const SizedBox(height: 8),
                      _actionButton(theme, Icons.image_rounded, Colors.indigo, 'Set Product Images', 'Assign picsum image URLs to all products', _updateImages),
                      const SizedBox(height: 32),

                      // Footer
                      Center(
                        child: Text('Zara Traders — Database v1.0',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400)),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) => Text(text,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant));

  Widget _actionButton(ThemeData theme, IconData icon, Color color, String title, String subtitle, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 18),
        onTap: onTap,
      ),
    );
  }
}
