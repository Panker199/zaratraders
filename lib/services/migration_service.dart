import 'package:cloud_firestore/cloud_firestore.dart';

class MigrationService {
  final FirebaseFirestore? _db;

  MigrationService() : _db = _createFirestore();

  static FirebaseFirestore? _createFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Migrates messages from old top-level support_messages collection
  /// to subcollections under each ticket. Returns number of messages migrated.
  Future<int> migrateMessages() async {
    if (_db == null) return 0;
    final oldMessages = await _db.collection('support_messages').get();
    int migrated = 0;
    for (final doc in oldMessages.docs) {
      final data = doc.data();
      final ticketId = data['ticketId'] as String?;
      if (ticketId == null) continue;
      await _db.collection('support_tickets').doc(ticketId)
          .collection('messages').doc(doc.id).set(data);
      migrated++;
    }
    return migrated;
  }

  /// Adds firstName/lastName to existing users that only have the old `name` field
  Future<int> migrateUserFields() async {
    if (_db == null) return 0;
    final snapshot = await _db.collection('users').get();
    int updated = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final hasFirstName = data.containsKey('firstName');
      final name = data['name'] as String? ?? '';

      if (!hasFirstName && name.isNotEmpty) {
        final parts = name.trim().split(' ');
        await doc.reference.update({
          'firstName': parts[0],
          'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : '',
        });
        updated++;
      }
    }
    return updated;
  }
}
