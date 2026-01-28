import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_motareb/core/utils/loc_extension.dart';
import 'package:admin_motareb/models/ad_model.dart';
import 'package:admin_motareb/admin/admin_add_ad_screen.dart';
import 'package:admin_motareb/utils/custom_snackbar.dart';

class AdminAdsListScreen extends StatelessWidget {
  const AdminAdsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.ads,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ads')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 80,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    loc.noAdsFound,
                    style: GoogleFonts.cairo(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final ad = AdModel.fromMap(doc.data() as Map<String, dynamic>);

              return FadeInUp(
                delay: Duration(milliseconds: index * 50),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2F3640)
                          : Colors.grey.withOpacity(0.1),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(ad.images.first),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    title: Text(
                      ad.nameAr,
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ad.type,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF008695),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: ad.isActive ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              ad.isActive ? 'Active' : 'Inactive',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.blue,
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AdminAddAdScreen(adToEdit: ad),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _showDeleteDialog(context, ad),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdminAddAdScreen()),
        ),
        backgroundColor: const Color(0xFF008695),
        label: Text(
          loc.addAd,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, AdModel ad) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.loc.deleteAd, style: GoogleFonts.cairo()),
        content: Text(context.loc.deleteAdConfirm, style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.loc.cancel, style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('ads')
                  .doc(ad.id)
                  .delete();
              if (context.mounted) {
                Navigator.pop(context);
                CustomSnackBar.show(
                  context: context,
                  message: 'Deleted Successfully',
                  isError: false,
                );
              }
            },
            child: Text(
              context.loc.delete,
              style: GoogleFonts.cairo(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
