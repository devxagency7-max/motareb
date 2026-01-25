import 'dart:async';
import 'dart:io';
import '../../../../services/r2_upload_service.dart';
import 'package:flutter/material.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final R2UploadService _r2Service = R2UploadService();
  AuthProvider _authProvider;

  // Streams
  Stream<List<Chat>>? _adminChatsStream;
  Stream<List<Message>>? _messagesStream;

  // State
  bool _isLoading = false;
  String? _currentChatId; // ID of the chat currently open

  bool get isLoading => _isLoading;
  String? get currentUserId => _authProvider.user?.uid;

  ChatProvider(this._authProvider) {
    if (_authProvider.isAuthenticated) {
      // If admin, we could init admin stream, but better to do it lazily on screen open
    }
  }

  void updateAuth(AuthProvider auth) {
    _authProvider = auth;
    notifyListeners();
  }

  // --- Admin Methods ---

  Stream<List<Chat>> get adminChatsStream {
    _adminChatsStream ??= _chatService.getAllChatsStream();
    return _adminChatsStream!;
  }

  // --- User/Shared Methods ---

  Future<void> initUserChat() async {
    final userId = _authProvider.user?.uid;
    // Fallback data if userData is not yet loaded
    final userMap = _authProvider.userData ?? {};

    if (userId == null) {
      debugPrint("ChatProvider: User ID is null, cannot init chat.");
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Ensure chat doc exists (with system message if new)
      await _chatService.createOrUpdateChat(
        userId: userId,
        userName: userMap['name'] ?? 'مستخدم',
        userEmail: userMap['email'] ?? '',
        userAvatar: null,
      );

      _currentChatId = userId;
      // Start streaming messages
      _messagesStream = _chatService.getMessagesStream(userId);

      // Hook into online status (Simple implementations)
      _chatService.updateUserStatus(userId, true);
    } catch (e) {
      debugPrint("Error initializing chat: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set active chat (For Admin clicking a user)
  void setActiveChat(String chatId) {
    _currentChatId = chatId;
    _messagesStream = _chatService.getMessagesStream(chatId);
    // Mark as read immediately when opening
    if (_authProvider.isAdmin) {
      _chatService.markMessagesAsRead(chatId, true);
    } else {
      _chatService.markMessagesAsRead(chatId, false);
    }
    notifyListeners();
  }

  Stream<List<Message>> get currentMessagesStream {
    if (_currentChatId == null) return const Stream.empty();
    return _messagesStream ?? const Stream.empty();
  }

  // Send Message
  Future<void> sendMessage(String text) async {
    if (_currentChatId == null || text.trim().isEmpty) return;

    if (_authProvider.user == null) {
      debugPrint("ChatProvider: User is null. Cannot send message.");
      return;
    }

    final senderId = _authProvider.user!.uid;
    final isAdmin = _authProvider.isAdmin;

    try {
      await _chatService.sendMessage(
        chatId: _currentChatId!,
        senderId: senderId,
        text: text.trim(),
        isAdmin: isAdmin,
        type: MessageType.text,
      );
    } catch (e) {
      debugPrint("Error sending message: $e");
      rethrow;
    }
  }

  Future<void> sendImageMessage(File imageFile) async {
    if (_currentChatId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final String imageUrl = await _r2Service.uploadFile(
        imageFile,
        propertyId: 'chat_images/$_currentChatId',
      );

      if (_authProvider.user == null) {
        debugPrint("ChatProvider: User is null. Cannot send image.");
        return;
      }

      final senderId = _authProvider.user!.uid;
      final isAdmin = _authProvider.isAdmin;

      await _chatService.sendMessage(
        chatId: _currentChatId!,
        senderId: senderId,
        text: imageUrl, // For images, the text field contains the URL
        isAdmin: isAdmin,
        type: MessageType.image,
      );
    } catch (e) {
      debugPrint("Error sending image: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Dispose/Cleanup
  void disposeChat() {
    if (_currentChatId != null && !_authProvider.isAdmin) {
      // If user, set offline
      _chatService.updateUserStatus(_currentChatId!, false);
    }
    _currentChatId = null;
    _messagesStream = null;
  }

  // Admin Controls
  Future<void> deleteMessage(String messageId) async {
    if (_currentChatId == null) return;
    await _chatService.deleteMessage(_currentChatId!, messageId);
  }

  Future<void> editMessage(String messageId, String newText) async {
    if (_currentChatId == null) return;
    await _chatService.editMessage(_currentChatId!, messageId, newText);
  }

  Future<void> pinMessage(String messageId, bool isPinned) async {
    if (_currentChatId == null) return;
    await _chatService.pinMessage(_currentChatId!, messageId, isPinned);
  }
}
