import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../services/r2_upload_service.dart';

class AdminVerificationScreen extends StatelessWidget {
  const AdminVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'طلبات التوثيق',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF008695), Color(0xFF39BB5E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFFF5F7F9)),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('verificationStatus', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 80,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'لا توجد طلبات توثيق حالياً',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            final users = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 120, 16, 20),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index].data() as Map<String, dynamic>;
                final userId = users[index].id;

                return FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  delay: Duration(milliseconds: index * 100),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 15),
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
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.teal.shade50,
                        backgroundImage:
                            (user['photoUrl'] != null &&
                                user['photoUrl'].toString().isNotEmpty)
                            ? NetworkImage(user['photoUrl'])
                            : null,
                        child:
                            (user['photoUrl'] == null ||
                                user['photoUrl'].toString().isEmpty)
                            ? const Icon(Icons.person, color: Colors.teal)
                            : null,
                      ),
                      title: Text(
                        user['fullName'] ?? user['name'] ?? 'مستخدم بدون اسم',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        user['email'] ?? 'لا يوجد بريد',
                        style: GoogleFonts.cairo(fontSize: 12),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          _showVerificationDetails(context, user, userId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF39BB5E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text('مراجعة', style: GoogleFonts.cairo()),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showVerificationDetails(
    BuildContext context,
    Map<String, dynamic> user,
    String userId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'تفاصيل طلب التوثيق',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoTile(
                      'الاسم الكامل',
                      user['fullName'] ?? user['name'] ?? 'غير متوفر',
                    ),
                    _buildInfoTile(
                      'مكان الإقامة',
                      user['residence'] ?? 'غير متوفر',
                    ),
                    _buildInfoTile(
                      'تاريخ الميلاد',
                      user['birthDate'] ?? 'غير متوفر',
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'صور الهوية:',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildImageCard(
                            'الوجه الأمامي',
                            user['idFrontUrl'],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildImageCard(
                            'الوجه الخلفي',
                            user['idBackUrl'],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _showRejectionDialog(context, userId, user),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      'رفض',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveRequest(context, userId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF39BB5E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      'قبول التوثيق',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12),
          ),
          Text(
            value,
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(String label, String? url) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.cairo(fontSize: 12)),
        const SizedBox(height: 5),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: url != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(url, fit: BoxFit.cover),
                )
              : const Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      ],
    );
  }

  Future<void> _approveRequest(BuildContext context, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'verificationStatus': 'verified',
        'isVerified': true,
      });
      if (!context.mounted) return;
      Navigator.pop(context);
      _showSnack(context, 'تم قبول التوثيق بنجاح', isError: false);
    } catch (e) {
      if (!context.mounted) return;
      _showSnack(context, 'حدث خطأ: $e', isError: true);
    }
  }

  void _showRejectionDialog(
    BuildContext context,
    String userId,
    Map<String, dynamic> user,
  ) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'سبب الرفض',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'سيتم حذف صور الهوية وبيانات التحقق وإعلام المستخدم.',
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'اكتب سبب الرفض هنا...',
                hintStyle: GoogleFonts.cairo(fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                _showSnack(context, 'يرجى كتابة سبب الرفض', isError: true);
                return;
              }
              Navigator.pop(context); // Close dialog
              _rejectRequest(
                context,
                userId,
                user,
                reasonController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'تأكيد الرفض',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectRequest(
    BuildContext context,
    String userId,
    Map<String, dynamic> user,
    String reason,
  ) async {
    try {
      Navigator.pop(context); // Close bottom sheet to prevent user interaction

      // 1. Delete images from R2
      final r2Service = R2UploadService();
      if (user['idFrontUrl'] != null) {
        try {
          await r2Service.deleteFile(user['idFrontUrl']);
        } catch (_) {
          // Ignore deletion errors (file might be already gone)
        }
      }
      if (user['idBackUrl'] != null) {
        try {
          await r2Service.deleteFile(user['idBackUrl']);
        } catch (_) {}
      }

      // 2. Update Firestore (Delete fields, set status rejected)
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'verificationStatus': 'rejected',
        'isVerified': false,
        'rejectionReason': reason,
        'idFrontUrl': FieldValue.delete(),
        'idBackUrl': FieldValue.delete(),
        'residence': FieldValue.delete(),
        'governorate': FieldValue.delete(),
        'birthDate': FieldValue.delete(),
        'verificationSubmittedAt': FieldValue.delete(),
      });

      if (!context.mounted) return;
      _showSnack(context, 'تم رفض الطلب وحذف البيانات بنجاح', isError: false);
    } catch (e) {
      if (!context.mounted) return;
      _showSnack(context, 'حدث خطأ: $e', isError: true);
    }
  }

  void _showSnack(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
