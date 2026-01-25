import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:admin_motareb/utils/custom_snackbar.dart';

class AdminAddPropertyController extends ChangeNotifier {
  // Text Controllers
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final discountPriceController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();
  final bedsController = TextEditingController();
  final roomsController = TextEditingController();
  final singleRoomsController = TextEditingController(); // NEW
  final doubleRoomsController = TextEditingController(); // NEW
  final singleBedsController = TextEditingController(); // NEW
  final doubleBedsController = TextEditingController(); // NEW
  final featuredLabelController = TextEditingController();
  final customRuleController = TextEditingController();
  final customAmenityController = TextEditingController();
  final customUniversityController = TextEditingController();

  // Multi-Image Upload
  final List<String> base64Images = [];
  final ImagePicker _picker = ImagePicker();

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
          final bytes = await File(image.path).readAsBytes();
          final String base64String = base64Encode(bytes);
          base64Images.add(base64String);
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
    base64Images.removeAt(index);
    notifyListeners();
  }

  Future<void> submitProperty(BuildContext context) async {
    // Validate
    if (base64Images.isEmpty) {
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
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      final String uid = user?.uid ?? 'admin_override_id';

      final propertyData = {
        'ownerId': uid,
        'title': titleController.text.trim(),
        'price': double.tryParse(priceController.text.trim()) ?? 0.0,
        'discountPrice': discountPriceController.text.trim().isNotEmpty
            ? double.tryParse(discountPriceController.text.trim())
            : null,
        'location': locationController.text.trim().isEmpty
            ? 'غير محدد'
            : locationController.text.trim(),
        'governorate': selectedGovernorate,
        'description': descriptionController.text.trim(),
        'featuredLabel': featuredLabelController.text.trim(),
        'images': base64Images,
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
      notifyListeners();
    }
  }

  // Method to add new university to Firestore and selection
  Future<void> addNewUniversity(BuildContext context, String name) async {
    if (name.trim().isEmpty) return;

    // We don't need to check duplicates locally as we fetch from DB,
    // but good to show feedback.
    // The previous logic checked duplicate names against UI list.
    // We can do that in UI or here if we pass the list.
    // For simplicity, we just add it to firestore, and selection logic is in UI/Controller.

    // Note: The UI logic had the check. We should ideally move that check here
    // but the list of *available* universities comes from a Stream in the UI.
    // So the controller doesn't automatically know all available universities unless we stream it here.
    // To keep it simple as requested, let's keep the stream in the UI (View)
    // and just call a simple add method here, or pass the list to this method.

    try {
      // Check if exists logic is better handled where data is available.
      // We'll trust the caller for now or just add it.
      // Actually, to fully separate, the stream should be here too?
      // Usually streams are okay in UI for simple cases.
      // Let's just add to firestore here.

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
    priceController.dispose();
    discountPriceController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    bedsController.dispose();
    roomsController.dispose();
    singleRoomsController.dispose();
    doubleRoomsController.dispose();
    singleBedsController.dispose();
    doubleBedsController.dispose();
    featuredLabelController.dispose();
    customRuleController.dispose();
    customAmenityController.dispose();
    customUniversityController.dispose();
    super.dispose();
  }
}
