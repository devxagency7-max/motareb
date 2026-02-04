import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:admin_motareb/utils/custom_snackbar.dart';
import 'package:admin_motareb/services/r2_upload_service.dart';

class AdminAddPropertyController extends ChangeNotifier {
  // Services
  final R2UploadService _r2Service = R2UploadService();
  final ImagePicker _picker = ImagePicker();

  // Text Controllers
  final titleController = TextEditingController();
  final titleEnController = TextEditingController(); // NEW
  final priceController = TextEditingController();
  final discountPriceController = TextEditingController();
  final locationController = TextEditingController();
  final locationEnController = TextEditingController(); // NEW
  final descriptionController = TextEditingController();
  final descriptionEnController = TextEditingController(); // NEW
  final bedsController = TextEditingController();
  final roomsController = TextEditingController();
  final singleRoomsController = TextEditingController(); // NEW
  final doubleRoomsController = TextEditingController(); // NEW
  final singleBedsController = TextEditingController(); // NEW
  final doubleBedsController = TextEditingController(); // NEW
  final featuredLabelController = TextEditingController();
  final featuredLabelEnController = TextEditingController(); // NEW
  final customRuleController = TextEditingController();
  final customAmenityController = TextEditingController();
  final customUniversityController = TextEditingController();

  // Selected Images (Files instead of Base64)
  final List<File> selectedImageFiles = [];

  // Dynamic Lists
  final List<String> amenities = [];
  final List<String> rules = [];

  // Selections
  final List<String> selectedUnitTypes = [];
  String selectedGender = 'male';
  final List<String> paymentMethods = [];
  final List<String> selectedUniversities = [];

  // Data Sources
  final List<String> suggestedAmenities = [
    'واي فاي',
    'تكييف',
    'بلكونة',
    'مطبخ',
    'مفروش',
    'أسانسير',
    'أمن',
    'جراج',
    'قريب من المواصلات',
  ];

  final List<String> governorates = [
    'القاهرة',
    'الجيزة',
    'الإسكندرية',
    'الدقهلية',
    'البحر الأحمر',
    'البحيرة',
    'الفيوم',
    'الغربية',
    'الإسماعيلية',
    'المنوفية',
    'المنيا',
    'القليوبية',
    'الوادي الجديد',
    'السويس',
    'أسوان',
    'أسيوط',
    'بني سويف',
    'بورسعيد',
    'دمياط',
    'الشرقية',
    'جنوب سيناء',
    'كفر الشيخ',
    'مطروح',
    'الأقصر',
    'قنا',
    'شمال سيناء',
    'سوهاج',
  ];

  String selectedGovernorate = 'بني سويف';
  bool isLoading = false;
  String loadingStatus = ''; // NEW: To show progress in UI

  void setGovernorate(String? val) {
    if (val != null) {
      selectedGovernorate = val;
      notifyListeners();
    }
  }

  void toggleGender() {
    if (selectedGender == 'female') {
      selectedGender = 'both';
    } else if (selectedGender == 'both') {
      selectedGender = 'male';
    } else {
      selectedGender = 'female';
    }
    notifyListeners();
  }

  void toggleSelection(List<String> list, String value) {
    if (list.contains(value)) {
      list.remove(value);
    } else {
      list.add(value);
    }
    notifyListeners();
  }

  void addCustomItem(List<String> list, String value) {
    if (value.trim().isNotEmpty) {
      list.add(value.trim());
      notifyListeners();
    }
  }

  void removeItem(List<String> list, String value) {
    list.remove(value);
    notifyListeners();
  }

  Future<void> pickMultiImages(BuildContext context) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        for (var image in images) {
          selectedImageFiles.add(File(image.path));
        }
        notifyListeners();
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'فشل اختيار الصور: $e',
          isError: true,
        );
      }
    }
  }

  void removeImage(int index) {
    selectedImageFiles.removeAt(index);
    notifyListeners();
  }

  Future<void> submitProperty(BuildContext context) async {
    // Validate
    if (selectedImageFiles.isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: 'يجب إضافة صورة واحدة على الأقل 📸',
        isError: true,
      );
      return;
    }

    if (titleController.text.trim().isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: 'عنوان الإعلان مطلوب (الزامي) ❗',
        isError: true,
      );
      return;
    }

    if (priceController.text.trim().isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: 'سعر العقار مطلوب (الزامي) ❗',
        isError: true,
      );
      return;
    }

    if (descriptionController.text.trim().isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: 'وصف العقار مطلوب (الزامي) 📝',
        isError: true,
      );
      return;
    }

    isLoading = true;
    loadingStatus = 'بدء عملية النشر...';
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      final String uid = user?.uid ?? 'admin_override_id';

      // 1. Upload images to R2 one by one
      List<String> imageUrls = [];
      for (int i = 0; i < selectedImageFiles.length; i++) {
        loadingStatus =
            'جاري رفع الصورة ${i + 1} من ${selectedImageFiles.length}...';
        notifyListeners();

        final url = await _r2Service.uploadFile(
          selectedImageFiles[i],
          propertyId: 'temp_admin_upload', // Will be grouped later if needed
        );
        imageUrls.add(url);
      }

      loadingStatus = 'جاري حفظ بيانات العقار...';
      notifyListeners();

      final propertyData = {
        'ownerId': uid,
        'title': titleController.text.trim(),
        'titleEn': titleEnController.text.trim().isEmpty
            ? titleController.text.trim()
            : titleEnController.text.trim(),
        'price': double.tryParse(priceController.text.trim()) ?? 0.0,
        'discountPrice': discountPriceController.text.trim().isNotEmpty
            ? double.tryParse(discountPriceController.text.trim())
            : null,
        'location': locationController.text.trim().isEmpty
            ? 'غير محدد'
            : locationController.text.trim(),
        'locationEn': locationEnController.text.trim().isEmpty
            ? locationController.text.trim()
            : locationEnController.text.trim(),
        'governorate': selectedGovernorate,
        'description': descriptionController.text.trim(),
        'descriptionEn': descriptionEnController.text.trim().isEmpty
            ? descriptionController.text.trim()
            : descriptionEnController.text.trim(),
        'featuredLabel': featuredLabelController.text.trim(),
        'featuredLabelEn': featuredLabelEnController.text.trim().isEmpty
            ? featuredLabelController.text.trim()
            : featuredLabelEnController.text.trim(),
        'images': imageUrls, // URLs instead of Base64
        'amenities': amenities,
        'rules': rules,
        'isBed': selectedUnitTypes.contains('bed'),
        'isRoom': selectedUnitTypes.contains('room'),
        'isStudio': selectedUnitTypes.contains('studio'),
        'unitTypes': selectedUnitTypes,
        'status': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
        'rating': 0.0,
        'ratingCount': 0,
        'agentName': 'المشرف',
        'gender': selectedGender,
        'paymentMethods': paymentMethods,
        'universities': selectedUniversities,
        'bedsCount': int.tryParse(bedsController.text.trim()) ?? 0,
        'roomsCount': int.tryParse(roomsController.text.trim()) ?? 0,
        'singleRoomsCount':
            int.tryParse(singleRoomsController.text.trim()) ?? 0,
        'doubleRoomsCount':
            int.tryParse(doubleRoomsController.text.trim()) ?? 0,
        'singleBedsCount': int.tryParse(singleBedsController.text.trim()) ?? 0,
        'doubleBedsCount': int.tryParse(doubleBedsController.text.trim()) ?? 0,
      };

      await FirebaseFirestore.instance
          .collection('properties')
          .add(propertyData);

      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'تم نشر العقار بنجاح! 🎉',
          isError: false,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'حدث خطأ أثناء النشر: $e',
          isError: true,
        );
      }
    } finally {
      isLoading = false;
      loadingStatus = '';
      notifyListeners();
    }
  }

  // Method to add new university to Firestore and selection
  Future<void> addNewUniversity(BuildContext context, String name) async {
    if (name.trim().isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('universities').add({
        'name': name.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'تم إضافة الجامعة بنجاح ✅',
          isError: false,
        );
      }

      // Auto select it?
      if (!selectedUniversities.contains(name.trim())) {
        selectedUniversities.add(name.trim());
        notifyListeners();
      }
    } catch (e) {
      // handle error
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    titleEnController.dispose();
    priceController.dispose();
    discountPriceController.dispose();
    locationController.dispose();
    locationEnController.dispose();
    descriptionController.dispose();
    descriptionEnController.dispose();
    bedsController.dispose();
    roomsController.dispose();
    singleRoomsController.dispose();
    doubleRoomsController.dispose();
    singleBedsController.dispose();
    doubleBedsController.dispose();
    featuredLabelController.dispose();
    featuredLabelEnController.dispose();
    customRuleController.dispose();
    customAmenityController.dispose();
    customUniversityController.dispose();
    super.dispose();
  }
}
