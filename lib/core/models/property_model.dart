import 'package:cloud_firestore/cloud_firestore.dart';

class Property {
  final String id;
  final String title;
  final String location;
  final double price; // Changed to double
  final String imageUrl;
  final String type;
  final bool isVerified;
  final bool isNew;
  final double rating;
  final List<String> amenities; // Renamed from tags to match Admin usage
  final String status; // Added
  final DateTime createdAt; // Added

  final double? discountPrice; // Added
  final List<String> rules; // Added
  final String? featuredLabel; // Added "الكلمة المميزة"

  final String? description;
  final String? governorate;
  final String? gender;
  final List<String> paymentMethods;
  final List<String> universities;
  final int bedsCount;
  final int roomsCount;
  final List<String> images;

  // Helpers
  bool get hasAC => amenities.contains('ac') || amenities.contains('تكييف');

  Property({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    this.discountPrice,
    required this.imageUrl,
    required this.type,
    this.isVerified = false,
    this.isNew = false,
    this.rating = 0.0,
    this.amenities = const [],
    this.rules = const [],
    this.status = 'pending',
    required this.createdAt,
    this.featuredLabel,
    this.description,
    this.governorate,
    this.gender,
    this.paymentMethods = const [],
    this.universities = const [],
    this.bedsCount = 0,
    this.roomsCount = 0,
    this.images = const [],
  });

  factory Property.fromSnapshot(QueryDocumentSnapshot doc) {
    return Property.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  factory Property.fromMap(Map<String, dynamic> map, String documentId) {
    return Property(
      id: documentId,
      title: map['title'] ?? '',
      location: map['location'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      discountPrice: (map['discountPrice'] as num?)?.toDouble(),
      imageUrl: (map['images'] as List<dynamic>?)?.isNotEmpty == true
          ? (map['images'] as List<dynamic>).first.toString()
          : '',
      type: map['isBed'] == true
          ? 'سرير'
          : map['isRoom'] == true
          ? 'غرفة'
          : 'شقة',
      isVerified: map['isVerified'] ?? false,
      isNew: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate().isAfter(
              DateTime.now().subtract(const Duration(days: 7)),
            )
          : false,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      amenities:
          (map['amenities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      rules:
          (map['rules'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      featuredLabel: map['featuredLabel'],
      description: map['description'],
      governorate: map['governorate'],
      gender: map['gender'],
      paymentMethods:
          (map['paymentMethods'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      universities:
          (map['universities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      bedsCount: (map['bedsCount'] as num?)?.toInt() ?? 0,
      roomsCount: (map['roomsCount'] as num?)?.toInt() ?? 0,
      images:
          (map['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'location': location,
      'price': price,
      'discountPrice': discountPrice,
      'images': images,
      'isBed': type == 'سرير',
      'isRoom': type == 'غرفة',
      'isVerified': isVerified,
      'rating': rating,
      'amenities': amenities,
      'rules': rules,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'featuredLabel': featuredLabel,
      'description': description,
      'governorate': governorate,
      'gender': gender,
      'paymentMethods': paymentMethods,
      'universities': universities,
      'bedsCount': bedsCount,
      'roomsCount': roomsCount,
    };
  }
}
