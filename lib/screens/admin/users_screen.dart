import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user.dart';
import '../../services/admin_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _adminService = AdminService();
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

  Future<void> _toggleRole(String uid, String currentRole) async {
    final newRole = currentRole == 'admin' ? UserRole.shopkeeper : UserRole.admin;
    try {
      await _adminService.updateUserRole(uid, newRole);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${newRole == UserRole.admin ? 'promoted to' : 'demoted to'} ${newRole.name}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update role: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _confirmDelete(Map<String, dynamic> u) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) {
        final nav = Navigator.of(ctx);
        var deleting = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Delete User'),
            content: Text(
                'Remove "${u['name'] as String? ?? ''}" from Firestore? Their Firebase Auth account will remain.'),
            actions: [
              TextButton(
                  onPressed: deleting ? null : () => nav.pop(),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: deleting
                    ? null
                    : () async {
                        final uid = u['id'] as String? ?? '';
                        if (uid.isEmpty) return;
                        setDialogState(() => deleting = true);
                        try {
                          await _adminService.deleteUser(uid);
                          if (mounted) nav.pop();
                          if (mounted) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('User deleted'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Users',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        key: ValueKey('users_$_refreshKey'),
        stream: _adminService.getUsersStream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 12),
                  Text('Failed to load users',
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
          var users = snap.data!;
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            users = users.where((u) =>
                (u['name'] as String? ?? '').toLowerCase().contains(q) ||
                (u['email'] as String? ?? '').toLowerCase().contains(q) ||
                (u['phone'] as String? ?? '').contains(q)).toList();
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() => _refreshKey++),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                        hintText: 'Search by name, email, or phone...',
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
                      ),
                    ),
                  ),
                ),
                if (users.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(_searchQuery.isNotEmpty ? 'No matching users' : 'No users registered',
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
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final u = users[index];
                        final roleStr = u['role'] as String? ?? 'shopkeeper';
                        final isAdmin = roleStr == 'admin';
                        final phone = u['phone'] as String? ?? '';
                        final email = u['email'] as String? ?? '';

                        return Card(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isAdmin
                                  ? Colors.blue.shade100
                                  : Colors.amber.shade100,
                              child: Icon(
                                isAdmin ? Icons.shield_outlined : Icons.person_outline,
                                color: isAdmin ? Colors.blue.shade700 : Colors.amber.shade700,
                                size: 20,
                              ),
                            ),
                            title: Text(u['name'] as String? ?? 'Unknown',
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                email.isNotEmpty ? email : phone,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                            trailing: PopupMenuButton<String>(
                              icon: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isAdmin ? Colors.blue.shade50 : Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(roleStr.toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isAdmin
                                            ? Colors.blue.shade700
                                            : Colors.amber.shade700)),
                              ),
                              onSelected: (value) async {
                                if (value == 'toggle') {
                                  await _toggleRole(u['uid'] as String, roleStr);
                                } else if (value == 'delete') {
                                  _confirmDelete(u);
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Row(
                                    children: [
                                      Icon(
                                        isAdmin ? Icons.arrow_downward : Icons.arrow_upward,
                                        size: 18,
                                        color: isAdmin ? Colors.red : Colors.green,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(isAdmin
                                          ? 'Demote to Shopkeeper'
                                          : 'Promote to Admin'),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline,
                                          size: 18, color: Colors.red.shade400),
                                      const SizedBox(width: 8),
                                      Text('Delete User',
                                          style: TextStyle(color: Colors.red.shade400)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: users.length,
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
}
