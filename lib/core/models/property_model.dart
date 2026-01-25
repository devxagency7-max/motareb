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
  final int bathroomsCount; // Added
  final String? videoUrl; // Added
  final int ratingCount; // Added
  final List<String> unitTypes; // Added
  final int singleRoomsCount;
  final int doubleRoomsCount;
  final int singleBedsCount;
  final int doubleBedsCount;
  final List<String> images;
  final List<Map<String, dynamic>> rooms; // Added for new units structure

  // Helpers
  bool get hasAC => amenities.contains('ac') || amenities.contains('تكييف');
  bool get isBed => unitTypes.contains('bed') || type == 'سرير';
  bool get isRoom => unitTypes.contains('room') || type == 'غرفة';
  bool get isStudio => unitTypes.contains('studio') || type == 'ستوديو';

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
    this.singleRoomsCount = 0,
    this.doubleRoomsCount = 0,
    this.singleBedsCount = 0,
    this.doubleBedsCount = 0,
    this.bathroomsCount = 1,
    this.images = const [],
    this.videoUrl,
    this.ratingCount = 0,
    this.unitTypes = const [],
    this.rooms = const [],
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
      ratingCount: (map['ratingCount'] as num?)?.toInt() ?? 0,
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
      singleRoomsCount: (map['singleRoomsCount'] as num?)?.toInt() ?? 0,
      doubleRoomsCount: (map['doubleRoomsCount'] as num?)?.toInt() ?? 0,
      singleBedsCount: (map['singleBedsCount'] as num?)?.toInt() ?? 0,
      doubleBedsCount: (map['doubleBedsCount'] as num?)?.toInt() ?? 0,
      bathroomsCount: (map['bathroomsCount'] as num?)?.toInt() ?? 1,
      images:
          (map['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      videoUrl: map['videoUrl'],
      unitTypes:
          (map['unitTypes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      rooms:
          (map['rooms'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
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
      'videoUrl': videoUrl,
      'isBed': type == 'سرير',
      'isRoom': type == 'غرفة',
      'isVerified': isVerified,
      'rating': rating,
      'ratingCount': ratingCount,
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
      'singleRoomsCount': singleRoomsCount,
      'doubleRoomsCount': doubleRoomsCount,
      'singleBedsCount': singleBedsCount,
      'doubleBedsCount': doubleBedsCount,
      'bathroomsCount': bathroomsCount,
      'unitTypes': unitTypes,
      'rooms': rooms,
    };
  }
}
