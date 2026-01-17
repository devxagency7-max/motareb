import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property_model.dart';

class PropertiesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Property>> getPropertiesStream() {
    return _firestore
        .collection('properties')
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Property.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  Future<List<Property>> getFeaturedProperties() async {
    // Logic for featured properties (e.g., highly rated or specific flag)
    // For now, returning top rated
    final snapshot = await _firestore
        .collection('properties')
        .where('status', isEqualTo: 'approved')
        .orderBy('rating', descending: true)
        .limit(5)
        .get();

    return snapshot.docs.map((doc) {
      return Property.fromMap(doc.data(), doc.id);
    }).toList();
  }
}
