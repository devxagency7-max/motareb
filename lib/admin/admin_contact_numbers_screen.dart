import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminContactNumbersScreen extends StatefulWidget {
  const AdminContactNumbersScreen({super.key});

  @override
  State<AdminContactNumbersScreen> createState() =>
      _AdminContactNumbersScreenState();
}

class _AdminContactNumbersScreenState extends State<AdminContactNumbersScreen> {
  final TextEditingController _numberController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _addNumber() async {
    String number = _numberController.text.trim();

    if (number.isEmpty) {
      _showError('يرجى إدخال الرقم');
      return;
    }

    if (!number.startsWith('01')) {
      _showError('يجب أن يبدأ الرقم بـ 01');
      return;
    }

    if (number.length != 11) {
      _showError('يجب أن يتكون الرقم من 11 خانة');
      return;
    }

    try {
      await _firestore.collection('contact_numbers').add({
        'number': number,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _numberController.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تمت إضافة الرقم بنجاح')));
      }
    } catch (e) {
      _showError('حدث خطأ أثناء الإضافة: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _deleteNumber(String id) async {
    try {
      await _firestore.collection('contact_numbers').doc(id).delete();
    } catch (e) {
      _showError('حدث خطأ أثناء الحذف: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'إدارة أرقام التواصل',
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _numberController,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.cairo(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      hintText: 'أدخل رقم الهاتف (مثلاً 010...)',
                      hintStyle: GoogleFonts.cairo(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade500
                            : Colors.grey,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E2329)
                          : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide:
                            Theme.of(context).brightness == Brightness.dark
                            ? const BorderSide(color: Color(0xFF2F3640))
                            : BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide:
                            Theme.of(context).brightness == Brightness.dark
                            ? const BorderSide(color: Color(0xFF2F3640))
                            : BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addNumber,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF39BB5E),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'إضافة',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('contact_numbers')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'لا توجد أرقام مضافة حالياً',
                        style: GoogleFonts.cairo(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      var data = doc.data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        color: Theme.of(context).cardTheme.color,
                        elevation:
                            Theme.of(context).brightness == Brightness.dark
                            ? 0
                            : 2,
                        child: ListTile(
                          title: Text(
                            data['number'],
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteNumber(doc.id),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
