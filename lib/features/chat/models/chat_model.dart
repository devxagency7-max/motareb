import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String userId;
  final String userName;
  final String userEmail;
  final String? userAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int userUnreadCount;
  final int adminUnreadCount;
  final bool isOnline;
  final DateTime lastSeen;
  final DateTime createdAt;

  Chat({
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.userUnreadCount,
    required this.adminUnreadCount,
    required this.isOnline,
    required this.lastSeen,
    required this.createdAt,
  });

  factory Chat.fromMap(Map<String, dynamic> map, String id) {
    return Chat(
      userId: id, // Doc ID is the userId
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userAvatar: map['userAvatar'],
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime:
          (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userUnreadCount: map['userUnreadCount'] ?? 0,
      adminUnreadCount: map['adminUnreadCount'] ?? 0,
      isOnline: map['isOnline'] ?? false,
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userAvatar': userAvatar,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'userUnreadCount': userUnreadCount,
      'adminUnreadCount': adminUnreadCount,
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
