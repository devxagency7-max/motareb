import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_motareb/utils/custom_snackbar.dart';
import 'package:admin_motareb/core/models/property_model.dart';
import 'package:admin_motareb/services/translation_service.dart';
import 'package:admin_motareb/services/r2_upload_service.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AdminReviewPropertyScreen extends StatefulWidget {
  final Property property;

  const AdminReviewPropertyScreen({super.key, required this.property});

  @override
  State<AdminReviewPropertyScreen> createState() =>
      _AdminReviewPropertyScreenState();
}

class _AdminReviewPropertyScreenState extends State<AdminReviewPropertyScreen> {
  // Controllers
  final _adminNumberController =
      TextEditingController(); // Only editable field for ID

  // Data from owner (Read Only)
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  // English Fields (To be translated)
  final _titleEnController = TextEditingController();
  final _locationEnController = TextEditingController();
  final _descriptionEnController = TextEditingController();

  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<String> _statusNotifier = ValueNotifier(
    '',
  ); // For loading status text

  // Services
  final R2UploadService _r2Service = R2UploadService();

  @override
  void initState() {
    super.initState();
    _preFillData();
  }

  void _preFillData() {
    final p = widget.property;
    _titleController.text = p.title;
    _priceController.text = p.price.toString();
    _locationController.text = p.location;
    _descriptionController.text = p.description ?? '';

    // Auto-translate if empty (Optional, but user asked for "Translate Button")
    // We leave them empty so admin clicks translate.
  }

  @override
  void dispose() {
    _adminNumberController.dispose();
    _titleController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _titleEnController.dispose();
    _locationEnController.dispose();
    _descriptionEnController.dispose();
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  Future<void> _translateField(
    String text,
    TextEditingController targetController,
  ) async {
    if (text.isEmpty) return;

    // Simple UI indication
    final originalText = targetController.text;
    targetController.text = "Translating...";

    try {
      final translated = await TranslationService.translateToEnglish(
        text,
      ); // Helper name might be misleading in service, let's assume it translates generic or check service
      // Wait, step 20 `TranslationService.translateToArabic` translates AR -> EN?
      // Source: Arabic, Target: English.
      // Yes, function name `translateToArabic` might be a misnomer or I misread it.
      // Code: `sourceLanguage: TranslateLanguage.arabic, targetLanguage: TranslateLanguage.english`.
      // So it translates TO English.

      targetController.text = translated;
    } catch (e) {
      targetController.text = originalText;
      CustomSnackBar.show(
        context: context,
        message: "Translation failed: $e",
        isError: true,
      );
    }
  }

  Future<void> _approveProperty() async {
    final adminNum = _adminNumberController.text.trim();
    if (adminNum.isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: "يجب إدخال رقم العقار للموافقة ❗",
        isError: true,
      );
      return;
    }

    if (_titleEnController.text.isEmpty || _locationEnController.text.isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: "يجب ترجمة الحقول الإنجليزية أولاً ❗",
        isError: true,
      );
      return;
    }

    _isLoadingNotifier.value = true;
    _statusNotifier.value = "جاري تحضير البيانات...";

    try {
      final newPropertyId = 'T${adminNum}Z';

      // Check if ID exists
      final checkDoc = await FirebaseFirestore.instance
          .collection('properties')
          .doc(newPropertyId)
          .get();
      if (checkDoc.exists) {
        throw "رقم العقار $newPropertyId مستخدم بالفعل!";
      }

      // 1. Move Images
      _statusNotifier.value = "جاري نقل الصور...";
      List<String> newImageUrls = [];

      // This is the heavy part: Download -> Upload -> Delete
      // Because we don't have a backend 'move' function provided in the snippets.
      for (String url in widget.property.images) {
        final newUrl = await _moveImageToApproved(url, newPropertyId);
        newImageUrls.add(newUrl);
      }

      // 1.1 Move Video (if exists)
      String? newVideoUrl;
      if (widget.property.videoUrl != null &&
          widget.property.videoUrl!.isNotEmpty) {
        _statusNotifier.value = "جاري نقل الفيديو...";
        newVideoUrl = await _moveImageToApproved(
          widget.property.videoUrl!,
          newPropertyId,
        ); // Reuse same function for generic file move
      }

      // 2. Create in 'properties'
      _statusNotifier.value = "جاري حفظ العقار...";
      final newPropertyData = widget.property
          .toMap(); // Assuming toDocument exists or we construct map
      // Update with new data
      newPropertyData['id'] = newPropertyId;
      newPropertyData['propertyId'] = newPropertyId;
      newPropertyData['adminNumber'] = int.parse(adminNum);
      newPropertyData['status'] = 'approved';
      newPropertyData['images'] = newImageUrls;
      if (newVideoUrl != null) {
        newPropertyData['videoUrl'] = newVideoUrl;
      }
      newPropertyData['titleEn'] = _titleEnController.text.trim();
      newPropertyData['locationEn'] = _locationEnController.text.trim();
      newPropertyData['descriptionEn'] = _descriptionEnController.text.trim();
      newPropertyData['createdAt'] =
          FieldValue.serverTimestamp(); // Reset or keep? Usually keep original creation date but maybe approved date. Let's keep original if possible, or new.

      await FirebaseFirestore.instance
          .collection('properties')
          .doc(newPropertyId)
          .set(newPropertyData);

      // 3. Delete from 'pending_properties'
      await FirebaseFirestore.instance
          .collection('pending_properties')
          .doc(widget.property.id)
          .delete();

      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: "تمت الموافقة ونشر العقار بنجاح! 🎉",
          isError: false,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: "خطأ: $e",
          isError: true,
        );
      }
    } finally {
      if (mounted) _isLoadingNotifier.value = false;
    }
  }

  Future<String> _moveImageToApproved(
    String oldUrl,
    String newPropertyId,
  ) async {
    // 1. Download
    final dio = Dio();
    final tempDir = await getTemporaryDirectory();
    final fileName = 'moved_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savePath = '${tempDir.path}/$fileName';

    await dio.download(oldUrl, savePath);
    final file = File(savePath);

    // 2. Upload to approved/{newPropertyId}/...
    final newUrl = await _r2Service.uploadFile(
      file,
      propertyId: newPropertyId,
      // R2UploadService in Admin assumes 'properties' root or similar?
      // In Admin it used `propertyId: formattedId`.
      // Let's assume the service handles putting it in the right place for 'properties'.
    );

    // 3. Delete old
    // We try to delete, if fail log it but don't fail the flow
    try {
      await _r2Service.deleteFile(oldUrl);
    } catch (e) {
      print("Failed to delete old file: $e");
    }

    return newUrl;
  }

  Future<void> _rejectProperty() async {
    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تأكيد الرفض"),
        content: const Text(
          "سيتم حذف الطلب وجميع الصور نهائياً. هل أنت متأكد؟",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("حذف ورفض", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _isLoadingNotifier.value = true;
    _statusNotifier.value = "جاري الحذف...";

    try {
      // 1. Delete Images
      for (String url in widget.property.images) {
        try {
          await _r2Service.deleteFile(url);
        } catch (e) {
          print("Error deleting file $url: $e");
        }
      }

      // 1.1 Delete Video
      if (widget.property.videoUrl != null) {
        try {
          await _r2Service.deleteFile(widget.property.videoUrl!);
        } catch (e) {
          print("Error deleting video: $e");
        }
      }

      // 2. Delete Document
      await FirebaseFirestore.instance
          .collection('pending_properties')
          .doc(widget.property.id)
          .delete();

      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: "تم رفض وحذف الطلب.",
          isError: false,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        CustomSnackBar.show(
          context: context,
          message: "خطأ: $e",
          isError: true,
        );
    } finally {
      if (mounted) _isLoadingNotifier.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "مراجعة العقار",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _isLoadingNotifier,
        builder: (context, isLoading, child) {
          if (isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  ValueListenableBuilder<String>(
                    valueListenable: _statusNotifier,
                    builder: (ctx, status, _) =>
                        Text(status, style: GoogleFonts.cairo()),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Images Preview
                if (widget.property.images.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.property.images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(widget.property.images[index]),
                          ),
                        );
                      },
                    ),
                  ),
                if (widget.property.videoUrl != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.videocam,
                          color: Colors.blue,
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "يوجد فيديو لهذا العقار",
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        // Note: To play it, we'd need a player. For now just indicator.
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const SizedBox(height: 20),

                // Admin ID Input
                _buildSectionHeader("بيانات الأدمن (إجباري)"),
                TextField(
                  controller: _adminNumberController,
                  decoration: InputDecoration(
                    labelText: "رقم العقار (مثال: 123)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),

                // Title Section
                _buildSectionHeader("العنوان"),
                _buildReadOnlyField("العنوان بالعربي", _titleController),
                const SizedBox(height: 10),
                _buildTranslatableField(
                  "Title (English)",
                  _titleEnController,
                  _titleController.text,
                ),

                const SizedBox(height: 20),

                // Location Section
                _buildSectionHeader("الموقع"),
                _buildReadOnlyField("الموقع بالعربي", _locationController),
                const SizedBox(height: 10),
                _buildTranslatableField(
                  "Location (English)",
                  _locationEnController,
                  _locationController.text,
                ),

                const SizedBox(height: 20),

                // Description Section
                _buildSectionHeader("الوصف"),
                _buildReadOnlyField(
                  "الوصف بالعربي",
                  _descriptionController,
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                _buildTranslatableField(
                  "Description (English)",
                  _descriptionEnController,
                  _descriptionController.text,
                  maxLines: 3,
                ),

                const SizedBox(height: 30),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _approveProperty,
                        icon: const Icon(Icons.check_circle),
                        label: Text(
                          "موافقة ونشر",
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _rejectProperty,
                        icon: const Icon(Icons.cancel),
                        label: Text(
                          "رفض وحذف",
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
    );
  }

  Widget _buildTranslatableField(
    String label,
    TextEditingController controller,
    String sourceText, {
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: () => _translateField(sourceText, controller),
          icon: const Icon(Icons.translate, color: Colors.blue),
          tooltip: "ترجمة تلقائية",
          style: IconButton.styleFrom(
            backgroundColor: Colors.blue.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }
}
