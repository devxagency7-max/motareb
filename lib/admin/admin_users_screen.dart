import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'إدارة المستخدمين',
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
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'لا يوجد مستخدمين حالياً',
                  style: GoogleFonts.cairo(fontSize: 16),
                ),
              );
            }

            final users = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 120, 16, 20),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final userNode = users[index];
                final user = userNode.data() as Map<String, dynamic>;
                final userId = userNode.id;

                // Priority: fullName > name > "Anonymous"
                final displayName =
                    user['fullName'] ?? user['name'] ?? 'مستخدم بدون اسم';
                final photoUrl = user['photoUrl'];

                return FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  delay: Duration(milliseconds: index * 50),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: Theme.of(context).brightness == Brightness.dark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2F3640)
                            : Colors.transparent,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () => _showUserDetails(context, user, userId),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 15,
                          ),
                          child: Row(
                            children: [
                              // Photo Avatar
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(
                                      0xFF39BB5E,
                                    ).withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Colors.grey.shade100,
                                  backgroundImage:
                                      (photoUrl != null &&
                                          photoUrl.toString().isNotEmpty)
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  child:
                                      (photoUrl == null ||
                                          photoUrl.toString().isEmpty)
                                      ? const Icon(
                                          Icons.person,
                                          color: Color(0xFF008695),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 15),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    Text(
                                      user['email'] ?? 'لا يوجد بريد',
                                      style: GoogleFonts.cairo(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // Status Badge
                              _buildSimpleBadge(user),

                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildSimpleBadge(Map<String, dynamic> user) {
    final bool isVerified = user['isVerified'] == true;
    final String status = user['verificationStatus'] ?? 'none';

    Color color = Colors.grey;
    String label = 'غير موثق';

    if (isVerified) {
      color = Colors.blue;
      label = 'موثق';
    } else if (status == 'pending') {
      color = Colors.orange;
      label = 'قيد المراجعة';
    } else if (status == 'rejected') {
      color = Colors.red;
      label = 'مرفوض';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _showUserDetails(
    BuildContext context,
    Map<String, dynamic> user,
    String userId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UserDetailsSheet(user: user, userId: userId),
    );
  }
}

class _UserDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> user;
  final String userId;

  const _UserDetailsSheet({required this.user, required this.userId});

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return 'غير متوفر';
    if (ts is Timestamp) {
      return DateFormat('yyyy/MM/dd hh:mm a').format(ts.toDate());
    }
    return ts.toString();
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = user['photoUrl'];
    final displayName = user['fullName'] ?? user['name'] ?? 'بدون اسم';
    final String status = user['verificationStatus'] ?? 'none';
    final bool isBanned = user['isBanned'] == true;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2F3640)
              : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Profile Section
                  Center(
                    child: Column(
                      children: [
                        _buildAvatar(photoUrl, context),
                        const SizedBox(height: 15),
                        Text(
                          displayName,
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        _buildVerificationStatusChip(
                          status,
                          user['isVerified'],
                        ),
                        if (isBanned)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Chip(
                              label: Text(
                                'محظور',
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                              backgroundColor: Colors.black,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  Text(
                    'المعلومات الأساسية',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Divider(),
                  _buildDetailTile(
                    Icons.email_outlined,
                    'البريد الإلكتروني',
                    user['email'],
                    context,
                  ),
                  _buildDetailTile(
                    Icons.perm_identity,
                    'رقم المعرف (UID)',
                    userId,
                    context,
                  ),
                  _buildDetailTile(
                    Icons.category_outlined,
                    'نوع الحساب (Role)',
                    user['role'],
                    context,
                  ),
                  _buildDetailTile(
                    Icons.login,
                    'طريقة التسجيل (Provider)',
                    user['provider'],
                    context,
                  ),

                  const SizedBox(height: 30),
                  Text(
                    'بيانات التوثيق والإقامة',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Divider(),
                  _buildDetailTile(
                    Icons.location_city,
                    'المحافظة',
                    user['governorate'],
                    context,
                  ),
                  _buildDetailTile(
                    Icons.home_outlined,
                    'السكن / العنوان',
                    user['residence'],
                    context,
                  ),
                  _buildDetailTile(
                    Icons.cake_outlined,
                    'تاريخ الميلاد',
                    user['birthDate'],
                    context,
                  ),

                  const SizedBox(height: 30),
                  Text(
                    'التواريخ والسجلات',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Divider(),
                  _buildDetailTile(
                    Icons.add_circle_outline,
                    'تاريخ الانضمام',
                    _formatTimestamp(user['createdAt']),
                    context,
                  ),
                  _buildDetailTile(
                    Icons.history,
                    'آخر ظهور',
                    _formatTimestamp(user['lastLoginAt']),
                    context,
                  ),
                  _buildDetailTile(
                    Icons.verified_outlined,
                    'تاريخ تقديم التوثيق',
                    _formatTimestamp(user['verificationSubmittedAt']),
                    context,
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? url, BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF39BB5E), Color(0xFF008695)],
        ),
      ),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: isDark ? const Color(0xFF1E2329) : Colors.white,
        child: CircleAvatar(
          radius: 47,
          backgroundColor: isDark
              ? const Color(0xFF121212)
              : Colors.grey.shade100,
          backgroundImage: (url != null && url.isNotEmpty)
              ? NetworkImage(url)
              : null,
          child: (url == null || url.isEmpty)
              ? const Icon(Icons.person, size: 50, color: Color(0xFF008695))
              : null,
        ),
      ),
    );
  }

  Widget _buildVerificationStatusChip(String status, dynamic isVerified) {
    Color color = Colors.grey;
    String label = 'غير موثق';

    if (isVerified == true) {
      color = Colors.blue;
      label = 'حساب موثق ✅';
    } else if (status == 'pending') {
      color = Colors.orange;
      label = 'قيد مراجعة البيانات ⏳';
    } else if (status == 'rejected') {
      color = Colors.red;
      label = 'طلب التوثيق مرفوض ❌';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDetailTile(
    IconData icon,
    String label,
    dynamic value,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF008695).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF008695)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  (value == null || value.toString().isEmpty)
                      ? 'غير متوفر'
                      : value.toString(),
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
