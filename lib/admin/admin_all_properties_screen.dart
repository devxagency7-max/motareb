import 'dart:convert';
import 'package:admin_motareb/admin/admin_add_properties_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../core/models/property_model.dart';
// import 'admin_add_property_screen.dart';
import 'admin_property_details_screen.dart';

class AdminAllPropertiesScreen extends StatefulWidget {
  const AdminAllPropertiesScreen({super.key});

  @override
  State<AdminAllPropertiesScreen> createState() =>
      _AdminAllPropertiesScreenState();
}

class _AdminAllPropertiesScreenState extends State<AdminAllPropertiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: Text(
          'إدارة كل الشقق',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // ADMIN ADDING PROPERTY
          // For now, we reuse the Owner's screen.
          // Ideally, we'd pass a flag to auto-approve, but let's keep it simple:
          // Admin adds -> it goes to Pending -> Admin approves it.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminAddPropertyScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF39BB5E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'بحث عن شقة...',
                  hintStyle: GoogleFonts.cairo(color: Colors.grey),
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
          ),

          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('properties')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'حدث خطأ في تحميل البيانات',
                      style: GoogleFonts.cairo(color: Colors.red),
                    ),
                  );
                }

                var docs = snapshot.data!.docs;

                // Client-side filtering because Firestore strictly limited
                // on combined text search queries without external services like Algolia.
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = (data['title'] ?? '')
                        .toString()
                        .toLowerCase();
                    return title.contains(_searchQuery);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد عقارات مطابقة',
                      style: GoogleFonts.cairo(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final property = Property.fromSnapshot(doc);

                    return FadeInUp(
                      key: ValueKey(property.id), // Important for performance
                      duration: const Duration(milliseconds: 300),
                      child: _buildPropertyListItem(context, property),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyListItem(BuildContext context, Property property) {
    Color statusColor;
    String statusText;

    switch (property.status) {
      case 'approved':
        statusColor = Colors.green;
        statusText = 'نشط ✅';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'مرفوض ❌';
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'قيد المراجعة ⏳';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AdminPropertyDetailsScreen(property: property),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 80,
                height: 80,
                child: property.images.isNotEmpty
                    ? (property.images.first.startsWith('http')
                          ? Image.network(
                              property.images.first,
                              fit: BoxFit.cover,
                            )
                          : Image.memory(
                              const Base64Decoder().convert(
                                property.images.first,
                              ),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image),
                            ))
                    : Image.asset(
                        'assets/images/intro2.png',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(width: 15),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${property.price.toInt()} ج.م',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF008695),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.cairo(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
