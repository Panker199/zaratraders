import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/support_service.dart';
import '../../utils/messenger_helper.dart';
import 'support_chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _supportService = SupportService();
  final _subjectCtrl = TextEditingController();

  @override
  void dispose() {
    _subjectCtrl.dispose();
    super.dispose();
  }

  void _newConversation() {
    _subjectCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) {
        var creating = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('New Message'),
            content: TextField(
              controller: _subjectCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'What do you need help with?',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: creating ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: creating
                    ? null
                    : () async {
                        final subject = _subjectCtrl.text.trim();
                        if (subject.isEmpty) return;
                        setDialogState(() => creating = true);
                        final auth = context.read<AuthService>();
                        final user = auth.currentUser;
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(ctx);
                        try {
                          await _supportService.createTicket(
                            user?.id ?? '',
                            user?.name ?? 'Unknown',
                            subject,
                          );
                          if (mounted) nav.pop();
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Failed: $e'), behavior: SnackBarBehavior.floating),
                            );
                          }
                        }
                      },
                child: creating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Send'),
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
    final auth = context.watch<AuthService>();
    final userId = auth.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Messages', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_rounded, size: 22, color: theme.colorScheme.onSurface),
            onPressed: _newConversation,
            tooltip: 'New message',
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supportService.getTicketsStream(userId: userId),
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
                    const SizedBox(height: 8),
                    Text('Pull down to retry',
                        style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
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
          final tickets = snap.data ?? [];
          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('No conversations yet',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Text('Tap the pencil icon to start a new conversation',
                      style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
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
                final subject = t['subject'] as String? ?? 'Support';
                final lastMsg = t['lastMessage'] as String?;
                final isOpen = status == 'open';
                final rawTs = t['lastMessageAt'] as dynamic;
                return InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SupportChatScreen(ticket: t)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: isOpen ? colorFromString(subject).withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.1),
                          child: Icon(
                            isOpen ? Icons.support_agent_rounded : Icons.check_circle_rounded,
                            color: isOpen ? colorFromString(subject) : Colors.green,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(subject,
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
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        lastMsg ?? 'Tap to start chatting',
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 14, color: lastMsg != null ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                                    ),
                                  ),
                                  if (isOpen) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 10, height: 10,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
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
