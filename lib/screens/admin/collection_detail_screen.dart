import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue, Timestamp;
import '../../services/admin_service.dart';

class CollectionDetailScreen extends StatefulWidget {
  final String collectionName;
  final IconData icon;
  final Color color;
  const CollectionDetailScreen({
    super.key,
    required this.collectionName,
    required this.icon,
    required this.color,
  });

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  final _adminService = AdminService();

  List<Map<String, dynamic>>? _docs;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final docs = await _adminService.getDocuments(widget.collectionName);
      if (mounted) setState(() { _docs = docs; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _addDocument() async => _showDocEditor(null);

  void _editDocument(Map<String, dynamic> doc) => _showDocEditor(doc);

  Future<void> _deleteDocument(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Delete document $docId?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _adminService.deleteDocument(widget.collectionName, docId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document deleted'), behavior: SnackBarBehavior.floating),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _showDocEditor(Map<String, dynamic>? existing) {
    final isEdit = existing != null;
    final keys = existing?.keys.where((k) => k != '_id').toList() ?? <String>['field1'];
    final ctrls = <String, TextEditingController>{};
    final types = <String, String>{};
    for (final k in keys) {
      final v = existing?[k];
      ctrls[k] = TextEditingController(text: _valToString(v));
      types[k] = _detectType(v);
    }

    showDialog(
      context: context,
      builder: (ctx) {
        var saving = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(isEdit ? 'Edit Document' : 'New Document'),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Collection: ${widget.collectionName}',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    ...ctrls.entries.map((e) {
                      final k = e.key;
                      final ctrl = e.value;
                      final type = types[k] ?? 'string';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(k, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: type == 'number'
                                  ? TextField(controller: ctrl, keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))
                                  : TextField(controller: ctrl,
                                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade300),
                              onPressed: () {
                                setDialogState(() {
                                  ctrls.remove(k);
                                  types.remove(k);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    if (!isEdit)
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Field'),
                        onPressed: () {
                          final fieldName = 'new_field${ctrls.length + 1}';
                          setDialogState(() {
                            ctrls[fieldName] = TextEditingController();
                            types[fieldName] = 'string';
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: saving ? null : () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              FilledButton(
                  onPressed: saving ? null : () async {
                  setDialogState(() => saving = true);
                  final navigator = Navigator.of(ctx);
                  final messenger = ScaffoldMessenger.of(context);
                  final data = <String, dynamic>{};
                  for (final e in ctrls.entries) {
                    final val = e.value.text.trim();
                    final type = types[e.key] ?? 'string';
                    if (val.isEmpty && !isEdit) continue;
                    data[e.key] = _parseValue(val, type);
                  }
                  try {
                    if (isEdit) {
                      await _adminService.updateDocument(widget.collectionName, existing['_id'], data);
                    } else {
                      await _adminService.addDocument(widget.collectionName, data);
                    }
                    if (!mounted) return;
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(content: Text(isEdit ? 'Document updated' : 'Document added'), behavior: SnackBarBehavior.floating),
                    );
                    _load();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), behavior: SnackBarBehavior.floating),
                    );
                  }
                },
                child: saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(isEdit ? 'Save' : 'Add'),
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
    final count = _docs?.length ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Icon(widget.icon, color: widget.color, size: 22),
          const SizedBox(width: 10),
          Text('${widget.collectionName.replaceAll('_', ' ')} ($count)',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
          IconButton(icon: const Icon(Icons.add_rounded), onPressed: _addDocument),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 12), Text('$_error'),
                  const SizedBox(height: 8),
                  OutlinedButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : (_docs ?? []).isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.folder_off_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No documents in this collection',
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      FilledButton.icon(icon: const Icon(Icons.add, size: 18), label: const Text('Add Document'), onPressed: _addDocument),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: (_docs ?? []).length,
                        itemBuilder: (context, index) {
                          final doc = (_docs ?? [])[index];
                          final docId = doc['_id'] as String? ?? '';
                          final preview = _preview(doc);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ExpansionTile(
                              leading: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                child: Icon(Icons.description_outlined, color: widget.color, size: 18),
                              ),
                              title: Text(docId.length > 20 ? '${docId.substring(0, 20)}...' : docId,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                              subtitle: Text(preview, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              children: [
                                ...doc.entries.where((e) => e.key != '_id').map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(width: 100, child: Text('${e.key}:',
                                          style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12, color: theme.colorScheme.primary))),
                                      Expanded(child: Text(_valToString(e.value),
                                          style: GoogleFonts.inter(fontSize: 12))),
                                    ],
                                  ),
                                )),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.edit_outlined, size: 14),
                                      label: const Text('Edit', style: TextStyle(fontSize: 12)),
                                      onPressed: () => _editDocument(doc),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      icon: Icon(Icons.delete_outline, size: 14, color: Colors.red),
                                      label: Text('Delete', style: TextStyle(fontSize: 12, color: Colors.red)),
                                      onPressed: () => _deleteDocument(docId),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _preview(Map<String, dynamic> doc) {
    final entries = doc.entries.where((e) => e.key != '_id').take(3);
    return entries.map((e) => '${e.key}: ${_valToString(e.value)}').join(' | ');
  }

  String _valToString(dynamic v) {
    if (v == null) return 'null';
    if (v is Timestamp) {
      final dt = v.toDate();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
    if (v is Map) return '{${v.length} fields}';
    if (v is List) return '[${v.length} items]';
    return v.toString();
  }

  String _detectType(dynamic v) {
    if (v == null) return 'string';
    if (v is num) return 'number';
    if (v is bool) return 'boolean';
    if (v is Timestamp || v is DateTime) return 'timestamp';
    return 'string';
  }

  dynamic _parseValue(String val, String type) {
    if (val.isEmpty) return '';
    switch (type) {
      case 'number': return num.tryParse(val) ?? 0;
      case 'boolean': return val.toLowerCase() == 'true';
      case 'timestamp': return FieldValue.serverTimestamp();
      default: return val;
    }
  }
}
