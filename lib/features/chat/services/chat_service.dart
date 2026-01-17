import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _chatsCollection => _firestore.collection('chats');

  // --- Chat Management ---

  // Get single chat stream (for User)
  Stream<Chat?> getChatStream(String userId) {
    return _chatsCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return Chat.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  // Get all chats stream (for Admin) - Ordered by lastMessageTime
  Stream<List<Chat>> getAllChatsStream() {
    return _chatsCollection
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    Chat.fromMap(doc.data() as Map<String, dynamic>, doc.id),
              )
              .toList();
        });
  }

  // Create or Update Chat (Ensures chat doc exists)
  Future<void> createOrUpdateChat({
    required String userId,
    required String userName,
    required String userEmail,
    String? userAvatar,
  }) async {
    final docRef = _chatsCollection.doc(userId);
    final doc = await docRef.get();

    if (!doc.exists) {
      // Create new chat
      final chat = Chat(
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        userAvatar: userAvatar,
        lastMessage:
            'مرحبًا 👋، أقدر أساعدك إزاي؟', // Initial system message preview
        lastMessageTime: DateTime.now(),
        userUnreadCount: 1, // System message is unread for user
        adminUnreadCount: 0,
        isOnline: true,
        lastSeen: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await docRef.set(chat.toMap());

      // Add initial system message
      await sendMessage(
        chatId: userId,
        senderId: 'system',
        text: 'مرحبًا 👋، أقدر أساعدك إزاي؟',
        type: MessageType.system,
      );
    } else {
      // Update user details & status
      await docRef.update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        // Optional: Update name/avatar if changed
      });
    }
  }

  // --- Message Management ---

  // Get messages stream
  Stream<List<Message>> getMessagesStream(String chatId) {
    return _chatsCollection
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Message.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Send Message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    MessageType type = MessageType.text,
    bool isAdmin = false,
  }) async {
    final messageRef = _chatsCollection
        .doc(chatId)
        .collection('messages')
        .doc();
    final timestamp = DateTime.now();

    final message = Message(
      id: messageRef.id,
      senderId: senderId,
      text: text,
      timestamp: timestamp,
      isRead: false,
      type: type,
    );

    // Batch write to update Chat and Add Message atomically
    final batch = _firestore.batch();

    // 1. Add Message
    batch.set(messageRef, message.toMap());

    // 2. Update Chat Metadata
    Map<String, dynamic> chatUpdate = {
      'lastMessage': type == MessageType.system ? 'رسالة تلقائية' : text,
      'lastMessageTime': Timestamp.fromDate(timestamp),
    };

    if (isAdmin) {
      chatUpdate['userUnreadCount'] = FieldValue.increment(1);
    } else if (senderId != 'system') {
      // User sent
      chatUpdate['adminUnreadCount'] = FieldValue.increment(1);
    }

    batch.update(_chatsCollection.doc(chatId), chatUpdate);

    await batch.commit();
  }

  // Mark Messages as Read
  Future<void> markMessagesAsRead(String chatId, bool isAdmin) async {
    // If Admin is reading, reset adminUnreadCount. If User, reset userUnreadCount.
    // Also explicitly mark message docs as read (optional, expensive for many docs).
    // For MVP, resetting the count on the Chat doc is often sufficient for badges.
    // However, to show "double check" marks, we update message docs.

    // Efficient approach: Reset count on Chat doc first
    await _chatsCollection.doc(chatId).update({
      isAdmin ? 'adminUnreadCount' : 'userUnreadCount': 0,
    });

    // Determine whose messages we are reading (Validates "isRead" on the message itself)
    // If I am Admin, I am reading User's messages.
    // Query unread messages sent by the 'other' party.
    // This part might be read-heavy, often skipped for simple apps, but let's do it for "IsRead" status.
    // ... For now, let's strictly stick to the counter for badges.
    // If we want "Seen" status on bubbles, we can implement it later.
  }

  // Update User Status (Online/Offline)
  Future<void> updateUserStatus(String userId, bool isOnline) async {
    await _chatsCollection.doc(userId).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // Delete Message
  Future<void> deleteMessage(String chatId, String messageId) async {
    await _chatsCollection
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  // Edit Message
  Future<void> editMessage(
    String chatId,
    String messageId,
    String newText,
  ) async {
    await _chatsCollection
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'text': newText, 'isEdited': true});
  }

  // Pin Message
  Future<void> pinMessage(
    String chatId,
    String messageId,
    bool isPinned,
  ) async {
    await _chatsCollection
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'isPinned': isPinned});
  }
}
