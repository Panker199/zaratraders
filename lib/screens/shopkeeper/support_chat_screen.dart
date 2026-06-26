import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/support_service.dart';
import '../../utils/messenger_helper.dart';

class SupportChatScreen extends StatefulWidget {
  final Map<String, dynamic> ticket;
  const SupportChatScreen({super.key, required this.ticket});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _supportService = SupportService();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  bool _showScrollButton = false;
  String? _replyToId;
  String? _replyToText;
  String? _replyToSender;
  String? _editingMessageId;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _openIndexUrl(String url) {
    Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Index URL copied — paste it in your browser')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    final auth = context.read<AuthService>();
    final user = auth.currentUser;

    if (_editingMessageId != null) {
      try {
        await _supportService.editMessage(widget.ticket['id'], _editingMessageId!, text);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to edit message: $e')),
          );
        }
      }
      _cancelEdit();
      return;
    }

    try {
      await _supportService.sendMessage(
        widget.ticket['id'],
        user?.id ?? '',
        user?.role.name ?? 'shopkeeper',
        text,
        replyToId: _replyToId,
        replyToText: _replyToText,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
    _cancelReply();
    _msgCtrl.clear();
    _scrollToBottom();
  }

  void _cancelReply() {
    setState(() {
      _replyToId = null;
      _replyToText = null;
      _replyToSender = null;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingMessageId = null;
    });
    _msgCtrl.clear();
  }

  void _startReply(String msgId, String text, String senderName) {
    setState(() {
      _replyToId = msgId;
      _replyToText = text.length > 80 ? '${text.substring(0, 80)}...' : text;
      _replyToSender = senderName;
    });
    _focusNode.requestFocus();
  }

  void _startEdit(String msgId, String text) {
    setState(() {
      _editingMessageId = msgId;
    });
    _msgCtrl.text = text;
    _msgCtrl.selection = TextSelection.fromPosition(TextPosition(offset: text.length));
    _focusNode.requestFocus();
  }

  void _deleteMessage(String msgId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              try {
                await _supportService.deleteMessage(widget.ticket['id'], msgId);
                nav.pop();
              } catch (e) {
                nav.pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete message: $e')),
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

  void _deleteConversation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text('Are you sure you want to delete this entire conversation? All messages will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final outerNav = Navigator.of(context);
              try {
                await _supportService.deleteTicket(widget.ticket['id']);
                if (mounted) {
                  nav.pop();
                  outerNav.pop();
                }
              } catch (e) {
                nav.pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete conversation: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted && _scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ticket = widget.ticket;
    final auth = context.read<AuthService>();
    final myRole = auth.currentUser?.role.name ?? '';
    final myId = auth.currentUser?.id ?? '';
    final isOpen = ticket['status'] == 'open';
    final isShopkeeper = myRole == 'shopkeeper';
    final otherName = isShopkeeper ? 'Admin' : (ticket['userName'] as String? ?? 'Shopkeeper');

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              child: Text(
                initials(otherName),
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(otherName,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(isOpen ? 'Online' : 'Resolved',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 22),
            onSelected: (v) async {
              final messenger = ScaffoldMessenger.of(context);
              if (v == 'resolve') {
                try {
                  await _supportService.updateTicketStatus(ticket['id'], 'resolved');
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to update status: $e')),
                    );
                  }
                }
              } else if (v == 'reopen') {
                try {
                  await _supportService.updateTicketStatus(ticket['id'], 'open');
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to update status: $e')),
                    );
                  }
                }
              } else if (v == 'delete') {
                _deleteConversation();
              } else if (v == 'copy_id') {
                Clipboard.setData(ClipboardData(text: ticket['id']));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ticket ID copied')),
                );
              }
            },
            itemBuilder: (_) => [
              if (isOpen)
                const PopupMenuItem(value: 'resolve', child: ListTile(leading: Icon(Icons.check_circle_outline), title: Text('Mark Resolved'), dense: true)),
              if (!isOpen)
                const PopupMenuItem(value: 'reopen', child: ListTile(leading: Icon(Icons.replay), title: Text('Reopen'), dense: true)),
              const PopupMenuItem(value: 'copy_id', child: ListTile(leading: Icon(Icons.copy, size: 20), title: Text('Copy Ticket ID'), dense: true)),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Delete Conversation', style: TextStyle(color: Colors.red)), dense: true),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supportService.getMessagesStream(ticket['id']),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  final url = SupportService.extractIndexUrl(snap.error!);
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.error),
                            const SizedBox(height: 12),
                            Text('Database index required',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.colorScheme.error)),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Create this index in Firebase Console → Firestore → Indexes:',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                                  const SizedBox(height: 12),
                                  Text('Collection: messages under support_tickets/{id}',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                                  const SizedBox(height: 4),
                                  Text('Field: timestamp (Ascending)',
                                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            if (url != null) ...[
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () => _openIndexUrl(url),
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                label: const Text('Copy Index URL'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }
                final messages = snap.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 56, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text('No messages yet', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text('Send a message to start the conversation',
                            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollCtrl.hasClients) {
                    final max = _scrollCtrl.position.maxScrollExtent;
                    if (_scrollCtrl.offset >= max - 100) {
                      _scrollCtrl.animateTo(max, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
                    }
                  }
                });
                return NotificationListener<ScrollNotification>(
                  onNotification: (scroll) {
                    if (scroll is ScrollUpdateNotification) {
                      final show = _scrollCtrl.hasClients && _scrollCtrl.position.maxScrollExtent - _scrollCtrl.offset > 150;
                      if (show != _showScrollButton) setState(() => _showScrollButton = show);
                    }
                    return false;
                  },
                  child: Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final msg = messages[i];
                          final isMe = msg['senderId'] == myId;
                          final rawTs = msg['timestamp'] as dynamic;
                          final showDateHeader = i == 0 || _differentDay(messages[i - 1]['timestamp'], rawTs);
                          final senderName = isMe ? 'You' : (msg['senderRole'] as String? ?? '');
                          return Column(
                            children: [
                              if (showDateHeader)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: _DateChip(dateHeader(rawTs)),
                                ),
                              _MessageBubble(
                                message: msg['text'] as String? ?? '',
                                isMe: isMe,
                                time: formatTime(rawTs),
                                senderRole: msg['senderRole'] as String? ?? '',
                                senderName: isMe ? '' : senderName,
                                isEdited: msg['edited'] == true,
                                replyToText: msg['replyToText'] as String?,
                                replyToSender: _findReplySender(messages, msg['replyToId'] as String?),
                                onLongPress: () => _showMessageOptions(msg, isMe, myId),
                                onReply: () => _startReply(
                                  msg['id'] as String,
                                  msg['text'] as String? ?? '',
                                  senderName,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      if (_showScrollButton)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: FloatingActionButton.small(
                            heroTag: 'scrollDown',
                            onPressed: _scrollToBottom,
                            backgroundColor: theme.colorScheme.surface,
                            child: Icon(Icons.keyboard_arrow_down, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildInputBar(theme),
        ],
      ),
    );
  }

  String? _findReplySender(List<Map<String, dynamic>> messages, String? replyToId) {
    if (replyToId == null) return null;
    for (final m in messages) {
      if (m['id'] == replyToId) {
        return m['senderRole'] as String?;
      }
    }
    return null;
  }

  void _showMessageOptions(Map<String, dynamic> msg, bool isMe, String myId) {
    final isOwnMessage = msg['senderId'] == myId;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (isOwnMessage) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Message'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _startEdit(msg['id'] as String, msg['text'] as String? ?? '');
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Message', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _deleteMessage(msg['id'] as String);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.reply_rounded),
              title: const Text('Reply'),
              onTap: () {
                Navigator.of(ctx).pop();
                final senderName = isMe ? 'You' : (msg['senderRole'] as String? ?? '');
                _startReply(msg['id'] as String, msg['text'] as String? ?? '', senderName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy Text'),
              onTap: () {
                Navigator.of(ctx).pop();
                Clipboard.setData(ClipboardData(text: msg['text'] as String? ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copied')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme) {
    final hasReply = _replyToId != null;
    final hasEdit = _editingMessageId != null;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, -1))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasReply)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                border: Border(
                  left: BorderSide(color: theme.colorScheme.primary, width: 3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Replying to ${_replyToSender ?? 'message'}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                        const SizedBox(height: 2),
                        Text(_replyToText ?? '',
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _cancelReply,
                  ),
                ],
              ),
            ),
          if (hasEdit)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                border: Border(
                  left: BorderSide(color: Colors.orange, width: 3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined, size: 18, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Editing message',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange.shade700)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _cancelEdit,
                  ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: hasEdit ? 'Edit message...' : 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 15),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        maxLines: 4,
                        minLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: hasEdit ? Colors.orange : theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        hasEdit ? Icons.check_rounded : Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _differentDay(dynamic a, dynamic b) {
    if (a == null || b == null) return false;
    try {
      final da = (a as dynamic).toDate() as DateTime;
      final db = (b as dynamic).toDate() as DateTime;
      return da.year != db.year || da.month != db.month || da.day != db.day;
    } catch (_) {
      return false;
    }
  }
}

class _DateChip extends StatelessWidget {
  final String text;
  const _DateChip(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String time;
  final String senderRole;
  final String senderName;
  final bool isEdited;
  final String? replyToText;
  final String? replyToSender;
  final VoidCallback? onLongPress;
  final VoidCallback? onReply;

  const _MessageBubble({
    required this.message, required this.isMe, required this.time,
    this.senderRole = '', this.senderName = '',
    this.isEdited = false, this.replyToText, this.replyToSender,
    this.onLongPress, this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isMe && senderName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 2),
              child: Text(senderName,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant)),
            ),
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
                margin: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (replyToText != null)
                      Container(
                        constraints: BoxConstraints(maxWidth: screenWidth * 0.72),
                        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color: isMe
                              ? theme.colorScheme.primary.withValues(alpha: 0.2)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: isMe ? theme.colorScheme.onPrimary.withValues(alpha: 0.5) : theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(replyToSender ?? 'message',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                    color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.primary)),
                            const SizedBox(height: 2),
                            Text(replyToText!,
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12,
                                    color: isMe
                                        ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                                        : theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 9, 14, 7),
                      decoration: BoxDecoration(
                        color: isMe ? theme.colorScheme.primary : theme.colorScheme.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                          bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 2, offset: const Offset(0, 1)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(message,
                              style: TextStyle(fontSize: 15,
                                  color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface, height: 1.35)),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(time,
                                  style: TextStyle(fontSize: 11,
                                      color: isMe ? theme.colorScheme.onPrimary.withValues(alpha: 0.7) : theme.colorScheme.onSurfaceVariant)),
                              if (isEdited) ...[
                                const SizedBox(width: 4),
                                Text('(edited)',
                                    style: TextStyle(fontSize: 10,
                                        fontStyle: FontStyle.italic,
                                        color: isMe ? theme.colorScheme.onPrimary.withValues(alpha: 0.6) : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7))),
                              ],
                              if (isMe) ...[
                                const SizedBox(width: 3),
                                Icon(Icons.done_all, size: 14, color: theme.colorScheme.onPrimary.withValues(alpha: 0.7)),
                              ],
                              if (!isMe && onReply != null) ...[
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: onReply,
                                  child: Icon(Icons.reply_rounded, size: 16,
                                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
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
            ),
          ),
        ],
      ),
    );
  }
}
