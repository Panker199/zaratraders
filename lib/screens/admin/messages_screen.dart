import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/support_service.dart';
import '../../utils/messenger_helper.dart';
import '../shopkeeper/support_chat_screen.dart';

class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen> {
  final _supportService = SupportService();
  String _filter = 'all';

  void _deleteTicket(String ticketId, String userName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text('Delete conversation with $userName? All messages will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              try {
                await _supportService.deleteTicket(ticketId);
                if (mounted) nav.pop();
              } catch (e) {
                nav.pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18)),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list_rounded, size: 22, color: theme.colorScheme.onSurface),
            onSelected: (v) => setState(() => _filter = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'open', child: Text('Open')),
              const PopupMenuItem(value: 'resolved', child: Text('Resolved')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supportService.getTicketsStream(),
        builder: (context, snap) {
          if (snap.hasError) {
            final url = SupportService.extractIndexUrl(snap.error!);
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 12),
                    Text('Could not load messages',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.error)),
                    if (url != null) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: url));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Index URL copied to clipboard')),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copy Index URL'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }
          var tickets = snap.data ?? [];
          if (_filter != 'all') {
            tickets = tickets.where((t) => t['status'] == _filter).toList();
          }
          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('No ${_filter == 'all' ? '' : _filter} conversations',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: tickets.length,
              separatorBuilder: (_, _) => const Divider(height: 0, indent: 72, endIndent: 16),
              itemBuilder: (context, i) {
                final t = tickets[i];
                final status = t['status'] as String? ?? 'open';
                final userName = t['userName'] as String? ?? 'Unknown';
                final subject = t['subject'] as String? ?? '';
                final lastMsg = t['lastMessage'] as String?;
                final isOpen = status == 'open';
                final rawTs = t['lastMessageAt'] as dynamic;
                return InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SupportChatScreen(ticket: t)),
                  ),
                  onLongPress: () => _deleteTicket(t['id'] as String, userName),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: colorFromString(userName).withValues(alpha: 0.15),
                          child: Text(initials(userName),
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold,
                                  color: colorFromString(userName))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(userName,
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.onSurface)),
                                  ),
                                  const SizedBox(width: 8),
                                  if (rawTs != null)
                                    Text(timeAgo(rawTs),
                                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        subject,
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isOpen ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(status.toUpperCase(),
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                                            color: isOpen ? Colors.orange : Colors.green)),
                                  ),
                                ],
                              ),
                              if (lastMsg != null) ...[
                                const SizedBox(height: 2),
                                Text(lastMsg,
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                              ],
                            ],
                          ),
                        ),
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
