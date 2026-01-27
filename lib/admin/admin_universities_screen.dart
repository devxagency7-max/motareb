import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUniversitiesScreen extends StatefulWidget {
  const AdminUniversitiesScreen({super.key});

  @override
  State<AdminUniversitiesScreen> createState() =>
      _AdminUniversitiesScreenState();
}

class _AdminUniversitiesScreenState extends State<AdminUniversitiesScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nameEnController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showUniversityDialog({String? id, Map<String, dynamic>? data}) {
    _nameController.text = data?['name'] ?? '';
    _nameEnController.text = data?['nameEn'] ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          id == null ? 'إضافة جامعة' : 'تعديل الجامعة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'اسم الجامعة (عربي)',
                labelStyle: GoogleFonts.cairo(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E2329)
                    : Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: Theme.of(context).brightness == Brightness.dark
                      ? const BorderSide(color: Color(0xFF2F3640))
                      : BorderSide.none,
                ),
              ),
              style: GoogleFonts.cairo(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _nameEnController,
              decoration: InputDecoration(
                labelText: 'University Name (EN)',
                labelStyle: GoogleFonts.cairo(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E2329)
                    : Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: Theme.of(context).brightness == Brightness.dark
                      ? const BorderSide(color: Color(0xFF2F3640))
                      : BorderSide.none,
                ),
              ),
              style: GoogleFonts.cairo(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.left,
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final nameAr = _nameController.text.trim();
              final nameEn = _nameEnController.text.trim();
              if (nameAr.isNotEmpty) {
                final Map<String, dynamic> updateData = {
                  'name': nameAr,
                  'nameEn': nameEn.isEmpty ? nameAr : nameEn,
                };
                if (id == null) {
                  updateData['createdAt'] = FieldValue.serverTimestamp();
                  await _firestore.collection('universities').add(updateData);
                } else {
                  await _firestore
                      .collection('universities')
                      .doc(id)
                      .update(updateData);
                }
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF39BB5E),
            ),
            child: Text(
              id == null ? 'إضافة' : 'تعديل',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteUniversity(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'حذف الجامعة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
        content: Text(
          'هل أنت متأكد من حذف هذه الجامعة؟',
          style: GoogleFonts.cairo(),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection('universities').doc(id).delete();
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('حذف', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'إدارة الجامعات',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUniversityDialog(),
        backgroundColor: const Color(0xFF39BB5E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('universities')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('حدث خطأ ما', style: GoogleFonts.cairo()),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'لا توجد جامعات مضافة بعد',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: Theme.of(context).cardTheme.color,
                elevation: Theme.of(context).brightness == Brightness.dark
                    ? 0
                    : 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school, color: Colors.blue),
                    ),
                    title: Text(
                      data['name'] ?? '',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    subtitle: Text(
                      data['nameEn'] ?? data['name'] ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.amber),
                          onPressed: () =>
                              _showUniversityDialog(id: doc.id, data: data),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteUniversity(doc.id),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameEnController.dispose();
    super.dispose();
  }
}
