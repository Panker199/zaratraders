import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/support_service.dart';
import 'support_chat_screen.dart';
import 'messages_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _subjectCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    super.dispose();
  }

  Future<void> _startLiveChat() async {
    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    if (user == null) return;
    try {
      final ticket = await SupportService().getOrCreateActiveTicket(user.id, user.name);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SupportChatScreen(ticket: ticket)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start chat: $e')),
      );
    }
  }

  Future<void> _submitTicket() async {
    final subject = _subjectCtrl.text.trim();
    if (subject.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final auth = context.read<AuthService>();
      final user = auth.currentUser;
      if (user != null) {
        await SupportService().createTicket(user.id, user.name, subject);
      }
      _subjectCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket submitted — we\'ll get back to you soon')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit ticket: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Support', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.support_agent_rounded, size: 48, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text('How can we help you?',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _startLiveChat,
                      icon: const Icon(Icons.chat_rounded, size: 20),
                      label: Text('Live Chat', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.confirmation_number_rounded, size: 22, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Submit a Ticket',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _subjectCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Describe your issue or question...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submitTicket,
                      child: _submitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Submit Ticket'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MessagesScreen()),
            ),
            icon: const Icon(Icons.history_rounded, size: 18),
            label: const Text('View My Tickets'),
          ),
          const SizedBox(height: 20),
          Text('Frequently Asked Questions',
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          ..._faqs.map((faq) => _FaqTile(question: faq.$1, answer: faq.$2)),
        ],
      ),
    );
  }
}

const _faqs = [
  ('How do I place an order?', 'Go to the Store tab, browse products, tap "Order Now" on any item, select quantity and any variant, then fill in your delivery details and confirm.'),
  ('How do I track my order?', 'Go to "My Orders" from the dashboard. Tap any order to see its status and delivery location on the map.'),
  ('How do I check stock levels?', 'Your dashboard shows total stock, inventory value, low-stock alerts, and out-of-stock items. You can also tap "Inventory" for full details.'),
  ('How do I contact support?', 'Use the "Live Chat" button above to start a real-time conversation, or submit a ticket and we\'ll respond via Messages.'),
  ('Can I cancel an order?', 'Orders can be cancelled only while they are in "Pending" status. Once confirmed or shipped, please contact support for assistance.'),
  ('How do I update my profile?', 'Profile management is available from the settings area. Your name and contact details are shown at the top of the dashboard.'),
];

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.question,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 10),
                Text(widget.answer,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
