import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String bookingId;
  final String userId;
  final String propertyId;
  final String status;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final double depositPaid;
  final double remainingAmount;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;

  BookingModel({
    required this.bookingId,
    required this.userId,
    required this.propertyId,
    required this.status,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    required this.depositPaid,
    required this.remainingAmount,
    required this.totalAmount,
    required this.createdAt,
    this.expiresAt,
    this.metadata = const {},
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final userInfo = data['userInfo'] as Map<String, dynamic>?;

    return BookingModel(
      bookingId: doc.id,
      userId: data['userId'] ?? '',
      propertyId: data['propertyId'] ?? '',
      status: data['status'] ?? 'pending',
      firstName: userInfo != null ? userInfo['name'] : data['firstName'],
      lastName: userInfo != null
          ? ''
          : data['lastName'], // Name is usually full name in userInfo
      phoneNumber: userInfo != null
          ? (userInfo['phone'] ?? userInfo['phone_number'])
          : data['phoneNumber'],
      depositPaid: (data['depositPaid'] ?? 0).toDouble(),
      remainingAmount: (data['remainingAmount'] ?? 0).toDouble(),
      totalAmount: (data['totalPrice'] ?? data['amount'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      metadata: data,
    );
  }

  // Status Logic
  bool get isDepositPaid =>
      status == 'reserved' ||
      status == 'completed' ||
      status == 'paying_remaining';

  bool get isFullyPaid => status == 'completed';
}
