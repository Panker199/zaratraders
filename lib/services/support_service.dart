import 'package:cloud_firestore/cloud_firestore.dart';

class SupportService {
  static final SupportService _instance = SupportService._();
  static SupportService get instance => _instance;

  final FirebaseFirestore? _firestore;
  SupportService._() : _firestore = _initFirestore();
  factory SupportService() => _instance;

  static FirebaseFirestore? _initFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference? get _tickets => _firestore?.collection('support_tickets');

  bool get _available => _firestore != null;

  /// Returns all tickets ordered by createdAt DESC (simple index).
  /// Filters by userId client-side so NO composite index is needed.
  Stream<List<Map<String, dynamic>>> getTicketsStream({String? userId}) {
    if (!_available) return Stream.value([]);
    try {
      return _tickets!
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                return data;
              })
              .where((t) => userId == null || t['userId'] == userId)
              .toList());
    } catch (e) {
      return Stream.error(e);
    }
  }

  Future<String> createTicket(String userId, String userName, String subject) async {
    if (!_available) return '';
    final doc = await _tickets!.add({
      'userId': userId,
      'userName': userName,
      'subject': subject,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Finds an open ticket for [userId] or creates a new one with a generic subject.
  /// Fetches all user tickets, filters client-side (avoids composite index).
  Future<Map<String, dynamic>> getOrCreateActiveTicket(String userId, String userName) async {
    if (!_available) return {};
    final snap = await _tickets!
        .orderBy('createdAt', descending: true)
        .get();
    final open = snap.docs
        .map((d) {
          final data = d.data() as Map<String, dynamic>;
          data['id'] = d.id;
          return data;
        })
        .where((t) => t['userId'] == userId && t['status'] == 'open')
        .toList();
    if (open.isNotEmpty) return open.first;
    final id = await createTicket(userId, userName, 'Live Chat');
    final doc = await _tickets!.doc(id).get();
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return {'id': id};
    data['id'] = doc.id;
    return data;
  }

  Future<void> updateTicketStatus(String ticketId, String status) async {
    if (!_available) return;
    await _tickets!.doc(ticketId).update({'status': status});
  }

  /// Messages are stored as a subcollection of each ticket:
  ///   support_tickets/{ticketId}/messages/{messageId}
  /// This allows ordering by timestamp WITHOUT a composite index.
  CollectionReference? _messagesRef(String ticketId) =>
      _firestore?.collection('support_tickets/$ticketId/messages');

  Stream<List<Map<String, dynamic>>> getMessagesStream(String ticketId) {
    if (!_available) return Stream.value([]);
    try {
      return _messagesRef(ticketId)!
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snap) => snap.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                return data;
              }).toList());
    } catch (e) {
      return Stream.error(e);
    }
  }

  Future<void> sendMessage(String ticketId, String senderId, String senderRole, String text, {String? replyToId, String? replyToText}) async {
    if (!_available) return;
    final msgData = <String, dynamic>{
      'ticketId': ticketId,
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };
    if (replyToId != null) {
      msgData['replyToId'] = replyToId;
      msgData['replyToText'] = replyToText;
    }
    await _messagesRef(ticketId)!.add(msgData);
    await _tickets!.doc(ticketId).update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> editMessage(String ticketId, String messageId, String newText) async {
    if (!_available) return;
    await _messagesRef(ticketId)!.doc(messageId).update({
      'text': newText,
      'edited': true,
      'editedAt': FieldValue.serverTimestamp(),
    });
    // Update ticket's last message if this was the latest
    final lastMsg = await _messagesRef(ticketId)!
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (lastMsg.docs.isNotEmpty && lastMsg.docs.first.id == messageId) {
      await _tickets!.doc(ticketId).update({'lastMessage': newText});
    }
  }

  Future<void> deleteMessage(String ticketId, String messageId) async {
    if (!_available) return;
    await _messagesRef(ticketId)!.doc(messageId).delete();
    // Update last message
    final remaining = await _messagesRef(ticketId)!
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (remaining.docs.isNotEmpty) {
      final data = remaining.docs.first.data() as Map<String, dynamic>;
      await _tickets!.doc(ticketId).update({
        'lastMessage': data['text'] ?? '',
        'lastMessageAt': data['timestamp'],
      });
    } else {
      await _tickets!.doc(ticketId).update({
        'lastMessage': '',
        'lastMessageAt': null,
      });
    }
  }

  Future<void> deleteTicket(String ticketId) async {
    if (!_available) return;
    // Delete all messages in subcollection
    final msgs = await _messagesRef(ticketId)!.get();
    for (final doc in msgs.docs) {
      await doc.reference.delete();
    }
    // Delete ticket document
    await _tickets!.doc(ticketId).delete();
  }

  Future<void> markAsRead(String ticketId, String messageId) async {
    if (!_available) return;
    await _messagesRef(ticketId)!.doc(messageId).update({'read': true});
  }

  /// Returns a stream of the number of open tickets (admin dashboard badge).
  Stream<int> getOpenTicketCountStream() {
    if (!_available) return Stream.value(0);
    return _tickets!
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => d.data() as Map<String, dynamic>)
            .where((t) => t['status'] == 'open')
            .length);
  }

  /// Extracts the Firebase Console index-creation URL from a Firestore error
  static String? extractIndexUrl(Object error) {
    final msg = error.toString();
    final idx = msg.indexOf('https://console.firebase.google.com');
    if (idx == -1) return null;
    final end = msg.indexOf(' ', idx);
    return end == -1 ? msg.substring(idx) : msg.substring(idx, end);
  }
}
