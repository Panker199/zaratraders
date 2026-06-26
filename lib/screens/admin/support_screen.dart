import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/support_service.dart';
import '../shopkeeper/support_chat_screen.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _supportService = SupportService();
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Support Tickets',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded, size: 20),
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
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 12),
                  Text('Failed to load tickets', style: TextStyle(color: Colors.red.shade600)),
                ],
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
                  Icon(Icons.support_agent_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No ${_filter == 'all' ? '' : _filter} tickets',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, i) {
              final t = tickets[i];
              final status = t['status'] as String? ?? 'open';
              final subject = t['subject'] as String? ?? '';
              final userName = t['userName'] as String? ?? 'Unknown';
              final lastMsg = t['lastMessage'] as String?;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: status == 'open' ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      status == 'open' ? Icons.chat_bubble_outline : Icons.check_circle_outline,
                      color: status == 'open' ? Colors.orange : Colors.green,
                      size: 22,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(userName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: status == 'open' ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(status.toUpperCase(),
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                                color: status == 'open' ? Colors.orange : Colors.green)),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subject, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                      if (lastMsg != null)
                        Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SupportChatScreen(ticket: t)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
