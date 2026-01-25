import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../providers/chat_provider.dart';
import '../models/message_model.dart';
import '../../auth/providers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String userName;

  const ChatScreen({super.key, required this.chatId, required this.userName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Scroll Controllers for "Jump to Pin" functionality
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  int _currentPinnedIndex =
      -1; // Index in the list of Pinned Messages (not the main list)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().setActiveChat(widget.chatId);
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatProvider>().sendMessage(text);
    _chatController.clear();
    // Scroll to bottom (index 0)
    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: 0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        if (!mounted) return;
        context.read<ChatProvider>().sendImageMessage(File(image.path));
        // Scroll to bottom
        if (_itemScrollController.isAttached) {
          _itemScrollController.jumpTo(index: 0);
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _scrollToNextPinnedMessage(List<Message> messages) {
    // 1. Find indices of all pinned messages
    final pinnedIndices = <int>[];
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].isPinned) {
        pinnedIndices.add(i);
      }
    }

    if (pinnedIndices.isEmpty) return;

    setState(() {
      // Move to next pinned message
      _currentPinnedIndex++;
      if (_currentPinnedIndex >= pinnedIndices.length) {
        _currentPinnedIndex = 0; // Wrap around
      }
    });

    final targetIndex = pinnedIndices[_currentPinnedIndex];

    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: targetIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    // Accessing stream directly in Widget tree isn't ideal for "finding all pinned messages" logic
    // effectively, but we can do it inside StreamBuilder.

    return StreamBuilder<List<Message>>(
      stream: chatProvider.currentMessagesStream,
      builder: (context, snapshot) {
        final messages = snapshot.data ?? [];
        final hasPinnedMessages = messages.any((m) => m.isPinned);

        return Scaffold(
          backgroundColor: const Color(0xFFE5E5E5).withOpacity(0.5),
          appBar: _buildAppBar(hasPinnedMessages, messages),
          body: Column(
            children: [
              Expanded(
                child: chatProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (snapshot.hasError)
                    ? const Center(child: Text('حدث خطأ'))
                    : (messages.isEmpty)
                    ? const Center(child: Text('لا توجد رسائل بعد'))
                    : ScrollablePositionedList.builder(
                        itemScrollController: _itemScrollController,
                        itemPositionsListener: _itemPositionsListener,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 20,
                        ),
                        reverse: true, // Index 0 is bottom
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe =
                              msg.senderId ==
                              context.read<ChatProvider>().currentUserId;

                          // Date Grouping Logic
                          bool showDate = false;
                          // Since list is reversed, "next" message in list is actually the *previous* message in time.
                          // We want to show date header ABOVE the message if the message BEFORE it (in time) is different day.
                          // But in reversed list:
                          // Index + 1 is the OLDER message.
                          if (index == messages.length - 1) {
                            showDate = true; // Oldest message always gets date
                          } else {
                            final nextMsg =
                                messages[index + 1]; // Older message
                            final currentDay = DateTime(
                              msg.timestamp.year,
                              msg.timestamp.month,
                              msg.timestamp.day,
                            );
                            final prevDay = DateTime(
                              nextMsg.timestamp.year,
                              nextMsg.timestamp.month,
                              nextMsg.timestamp.day,
                            );
                            if (currentDay != prevDay) {
                              showDate = true;
                            }
                          }

                          return Column(
                            children: [
                              if (showDate) _buildDateHeader(msg.timestamp),
                              if (msg.type == MessageType.system)
                                _buildSystemMessage(msg)
                              else
                                _buildMessageBubble(context, msg, isMe),
                            ],
                          );
                        },
                      ),
              ),
              _buildInputArea(chatProvider.isLoading),
            ],
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(bool hasPinned, List<Message> messages) {
    return AppBar(
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF008695),
            child: Text(
              widget.userName.isNotEmpty ? widget.userName[0] : '?',
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'المستخدم',
                  style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 1,
      centerTitle: false,
      iconTheme: const IconThemeData(color: Colors.black),
      actions: [
        if (hasPinned)
          IconButton(
            icon: const Icon(Icons.push_pin, color: Colors.orange),
            onPressed: () => _scrollToNextPinnedMessage(messages),
            tooltip: 'الانتقال للرسائل المثبتة',
          ),
        IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
      ],
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    String text;
    if (msgDate == today) {
      text = 'اليوم';
    } else if (msgDate == yesterday) {
      text = 'أمس';
    } else {
      text = DateFormat('d MMMM yyyy', 'ar').format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 15),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.cairo(fontSize: 12, color: Colors.black54),
      ),
    );
  }

  Widget _buildSystemMessage(Message msg) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          msg.text,
          style: GoogleFonts.cairo(fontSize: 11, color: Colors.blueGrey),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, Message msg, bool isMe) {
    final isAdmin = context.read<AuthProvider>().isAdmin;

    return FadeInUp(
      duration: const Duration(milliseconds: 200),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: isAdmin ? () => _showMessageOptions(context, msg) : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              gradient: isMe
                  ? const LinearGradient(
                      colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: !isMe ? Colors.white : null,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 0),
                bottomRight: Radius.circular(!isMe ? 16 : 0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.isPinned) _buildPinnedIndicator(),

                  // Content
                  if (msg.type == MessageType.image)
                    _buildImageContent(msg, isMe)
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Linkify(
                        text: msg.text,
                        onOpen: (link) async {
                          if (await canLaunchUrl(Uri.parse(link.url))) {
                            await launchUrl(
                              Uri.parse(link.url),
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        style: GoogleFonts.cairo(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                        linkStyle: GoogleFonts.cairo(
                          color: isMe ? Colors.white : Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                  // Metadata (Time + Ticks)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 8,
                      right: 8,
                      bottom: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (msg.isEdited)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.edit,
                              size: 10,
                              color: isMe ? Colors.white70 : Colors.grey,
                            ),
                          ),
                        Text(
                          DateFormat('hh:mm a').format(msg.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            msg.isRead ? Icons.done_all : Icons.done,
                            size: 14,
                            color: msg.isRead
                                ? Colors.blueAccent.shade100
                                : Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinnedIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.push_pin, size: 12, color: Colors.orange),
          const SizedBox(width: 4),
          Text(
            'مثبتة',
            style: GoogleFonts.cairo(fontSize: 10, color: Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent(Message msg, bool isMe) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) =>
              Dialog(child: InteractiveViewer(child: Image.network(msg.text))),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          msg.text,
          width: 200,
          fit: BoxFit.cover,
          loadingBuilder: (ctx, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 200,
              height: 200,
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 200,
              height: 200,
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isLoading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.add_photo_alternate_rounded,
                color: Color(0xFF008695),
              ),
              onPressed: isLoading ? null : _pickAndSendImage,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _chatController,
                  maxLines: 5,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالة...',
                    hintStyle: GoogleFonts.cairo(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: isLoading ? null : _sendMessage,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF008695).withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context, Message msg) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pin / Unpin
              ListTile(
                leading: Icon(
                  msg.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                  color: Colors.orange,
                ),
                title: Text(
                  msg.isPinned ? 'إلغاء التثبيت' : 'تثبيت الرسالة',
                  style: GoogleFonts.cairo(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.read<ChatProvider>().pinMessage(
                    msg.id,
                    !msg.isPinned,
                  );
                },
              ),
              if (msg.type == MessageType.text) ...[
                // Edit
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: Text('تعديل', style: GoogleFonts.cairo()),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(context, msg);
                  },
                ),
                // Copy
                ListTile(
                  leading: const Icon(Icons.copy, color: Colors.grey),
                  title: Text('نسخ', style: GoogleFonts.cairo()),
                  onTap: () {
                    // Clipboard logic
                    Navigator.pop(context);
                  },
                ),
              ],
              // Delete
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text('حذف', style: GoogleFonts.cairo()),
                onTap: () {
                  Navigator.pop(context);
                  context.read<ChatProvider>().deleteMessage(msg.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, Message msg) {
    final TextEditingController editController = TextEditingController(
      text: msg.text,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'تعديل الرسالة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: editController,
            maxLines: 3,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (editController.text.trim().isNotEmpty) {
                  context.read<ChatProvider>().editMessage(
                    msg.id,
                    editController.text.trim(),
                  );
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008695),
              ),
              child: Text('حفظ', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
