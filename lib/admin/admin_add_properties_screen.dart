import 'dart:convert';
import 'dart:io';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:admin_motareb/utils/custom_snackbar.dart';

class AdminAddPropertyScreen extends StatefulWidget {
  const AdminAddPropertyScreen({super.key});

  @override
  State<AdminAddPropertyScreen> createState() => _AdminAddPropertyScreenState();
}

class _AdminAddPropertyScreenState extends State<AdminAddPropertyScreen> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController(); // Added
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _bedsController = TextEditingController();
  final _roomsController = TextEditingController();
  final _featuredLabelController = TextEditingController(); // New Field
  final _customRuleController = TextEditingController();
  final _customAmenityController = TextEditingController();
  final _customUniversityController =
      TextEditingController(); // Added Controller

  // Multi-Image Upload
  final List<String> _base64Images = [];
  final ImagePicker _picker = ImagePicker();

  // Dynamic Lists
  final List<String> _amenities = [];
  final List<String> _rules = [];

  // Selections
  final List<String> _selectedUnitTypes = []; // Changed to List
  String _selectedGender = 'male';
  final List<String> _paymentMethods = [];
  final List<String> _selectedUniversities = [];

  // Data Sources
  final List<String> _suggestedAmenities = [
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

  final List<String> _governorates = [
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
  ]; // Truncated for brevity, can add more
  String _selectedGovernorate = 'بني سويف';

  bool _isLoading = false;

  Future<void> _pickMultiImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        for (var image in images) {
          final bytes = await File(image.path).readAsBytes();
          final String base64String = base64Encode(bytes);
          setState(() {
            _base64Images.add(base64String);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'فشل اختيار الصور: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _submitProperty() async {
    // Validate
    if (_base64Images.isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: 'يجب إضافة صورة واحدة على الأقل 📸',
        isError: true,
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: 'عنوان الإعلان مطلوب (الزامي) ❗',
        isError: true,
      );
      return;
    }

    if (_priceController.text.trim().isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: 'سعر العقار مطلوب (الزامي) ❗',
        isError: true,
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: 'وصف العقار مطلوب (الزامي) 📝',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final String uid = user?.uid ?? 'admin_override_id';

      final propertyData = {
        'ownerId': uid,
        'title': _titleController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'discountPrice': _discountPriceController.text.trim().isNotEmpty
            ? double.tryParse(_discountPriceController.text.trim())
            : null,
        'location': _locationController.text.trim().isEmpty
            ? 'غير محدد'
            : _locationController.text.trim(),
        'governorate': _selectedGovernorate,
        'description': _descriptionController.text.trim(),
        'featuredLabel': _featuredLabelController.text.trim(),
        'images': _base64Images,
        'amenities': _amenities, // Dynamic list
        'rules': _rules, // Dynamic list
        // Map Unit Types to boolean flags for backward compatibility or filtering
        'isBed': _selectedUnitTypes.contains('bed'),
        'isRoom': _selectedUnitTypes.contains('room'),
        'isStudio': _selectedUnitTypes.contains('studio'),
        'unitTypes': _selectedUnitTypes, // Save list as well
        'status': 'approved', // Auto-approve for admin
        'createdAt': FieldValue.serverTimestamp(),
        'rating': 0.0,
        'ratingCount': 0,
        'agentName': 'المشرف',
        'gender': _selectedGender,
        'paymentMethods': _paymentMethods,
        'universities': _selectedUniversities,
        'bedsCount': int.tryParse(_bedsController.text.trim()) ?? 0,
        'roomsCount': int.tryParse(_roomsController.text.trim()) ?? 0,
      };

      await FirebaseFirestore.instance
          .collection('properties')
          .add(propertyData);

      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'تم نشر العقار بنجاح! 🎉',
          isError: false,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'حدث خطأ أثناء النشر: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'إضافة عقار جديد',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: FadeInUp(
          duration: const Duration(milliseconds: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Image Picker Section ---
              _buildSectionLabel('صور العقار 📸'),
              const SizedBox(height: 10),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _base64Images.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return GestureDetector(
                        onTap: _pickMultiImages,
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF39BB5E).withOpacity(0.1),
                                const Color(0xFF008695).withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF39BB5E),
                              style: BorderStyle.solid,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF39BB5E).withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_photo_alternate_rounded,
                                color: Color(0xFF39BB5E),
                                size: 35,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'إضافة صور',
                                style: GoogleFonts.cairo(
                                  color: const Color(0xFF39BB5E),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final base64Image = _base64Images[index - 1];
                    return Stack(
                      children: [
                        Container(
                          width: 120,
                          margin: const EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(
                              image: MemoryImage(base64Decode(base64Image)),
                              fit: BoxFit.cover,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _base64Images.removeAt(index - 1);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 25),

              // --- Main Info Glass Card ---
              _buildGlassCard(
                children: [
                  _buildSectionLabel('بيانات العقار الأساسية 🏠'),
                  const SizedBox(height: 15),
                  _buildTextField(
                    label: 'عنوان الإعلان المميز (الزامي) *',
                    hint: 'مثال: ستوديو فاخر بجوار الجامعة',
                    controller: _titleController,
                    icon: Icons.title,
                  ),
                  const SizedBox(height: 15),

                  // Price and Governorate in Vertical layout as requested
                  _buildTextField(
                    label: 'السعر (ج.م) (الزامي) *',
                    hint: '0.0',
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    icon: Icons.monetization_on_outlined,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    label: 'سعر الخصم (اختياري)',
                    hint: '0.0 (اتركه فارغاً إذا لا يوجد خصم)',
                    controller: _discountPriceController,
                    keyboardType: TextInputType.number,
                    icon: Icons.local_offer_outlined,
                  ),
                  const SizedBox(height: 15),
                  _buildDropdown(
                    label: 'المحافظة (الزامي) *',
                    value: _selectedGovernorate,
                    items: _governorates,
                    onChanged: (val) =>
                        setState(() => _selectedGovernorate = val!),
                  ),
                  const SizedBox(height: 15),

                  _buildTextField(
                    label: 'الموقع التفصيلي',
                    hint: 'الشارع، الحي، علامة مميزة...',
                    controller: _locationController,
                    icon: Icons.location_on_outlined,
                    maxLines: 3, // Increased lines
                  ),
                  const SizedBox(height: 15),

                  // --- Universities Selector ---
                  _buildUniversitiesSelector(),
                  const SizedBox(height: 15),
                  _buildTextField(
                    label: 'كلمة مميزة (بادج)',
                    hint: 'مثال: خصم خاص، فرصة، قريب جداً',
                    controller: _featuredLabelController,
                    icon: Icons.stars_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Description & Types ---
              _buildGlassCard(
                children: [
                  _buildSectionLabel('الوصف والتفاصيل 📝'),
                  const SizedBox(height: 15),
                  _buildTextField(
                    label: 'وصف كامل للعقار (الزامي) *',
                    hint: 'اكتب كل التفاصيل اللي تميز مكانك...',
                    controller: _descriptionController,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionLabel(
                    'نوع السكن (اختر كل ما ينطبق)',
                    fontSize: 14,
                  ),
                  Wrap(
                    spacing: 10,
                    children: [
                      _buildSelectableChip(
                        label: 'سرير',
                        value: 'bed',
                        selectedValues: _selectedUnitTypes,
                      ),
                      _buildSelectableChip(
                        label: 'غرفة',
                        value: 'room',
                        selectedValues: _selectedUnitTypes,
                      ),
                      _buildSelectableChip(
                        label: 'استوديو / شقة',
                        value: 'studio',
                        selectedValues: _selectedUnitTypes,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'عدد السراير',
                          hint: '0',
                          controller: _bedsController,
                          keyboardType: TextInputType.number,
                          icon: Icons.bed,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                          label: 'عدد الغرف',
                          hint: '0',
                          controller: _roomsController,
                          keyboardType: TextInputType.number,
                          icon: Icons.meeting_room,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Target Audience & Payment ---
              _buildGlassCard(
                children: [
                  _buildSectionLabel('الفئة المستهدفة ونظام الدفع 🎯'),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGradientSelectionCard(
                          title: 'شباب 👨',
                          isSelected:
                              _selectedGender == 'male' ||
                              _selectedGender == 'both',
                          onTap: () {
                            setState(() {
                              if (_selectedGender == 'female') {
                                _selectedGender = 'both';
                              } else if (_selectedGender == 'both') {
                                _selectedGender = 'female';
                              } else {
                                _selectedGender = 'male';
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 15), // Spacing
                      Expanded(
                        child: _buildGradientSelectionCard(
                          title: 'بنات 👩',
                          isSelected:
                              _selectedGender == 'female' ||
                              _selectedGender == 'both',
                          onTap: () {
                            setState(() {
                              if (_selectedGender == 'male') {
                                _selectedGender = 'both';
                              } else if (_selectedGender == 'both') {
                                _selectedGender = 'male';
                              } else {
                                _selectedGender = 'female';
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSectionLabel('نظام الدفع', fontSize: 14),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildSelectableChip(
                        label: 'شهري',
                        value: 'monthly',
                        selectedValues: _paymentMethods,
                      ),
                      _buildSelectableChip(
                        label: 'بالترم',
                        value: 'term',
                        selectedValues: _paymentMethods,
                      ),
                      _buildSelectableChip(
                        label: 'سنوي',
                        value: 'year',
                        selectedValues: _paymentMethods,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Amenities & Rules ---
              _buildGlassCard(
                children: [
                  _buildSectionLabel('المميزات والإضافات ✨'),
                  const SizedBox(height: 10),
                  // Suggested Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestedAmenities.map((amenity) {
                      final isSelected = _amenities.contains(amenity);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _amenities.remove(amenity);
                            } else {
                              _amenities.add(amenity);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: isSelected
                              ? BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF39BB5E),
                                      Color(0xFF008695),
                                    ],
                                    begin: Alignment.centerRight,
                                    end: Alignment.centerLeft,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF008695,
                                      ).withOpacity(0.3),
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                )
                              : BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                          child: Text(
                            amenity,
                            style: GoogleFonts.cairo(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  // Dynamic Add Field
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _buildDynamicAddField(
                      controller: _customAmenityController,
                      hint: 'أضف مميزة أخرى...',
                      onAdd: (val) {
                        setState(() => _amenities.add(val));
                      },
                    ),
                  ),
                  // List of custom added amenities (if not in suggested)
                  if (_amenities
                      .where((a) => !_suggestedAmenities.contains(a))
                      .isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Wrap(
                        spacing: 8,
                        children: _amenities
                            .where((a) => !_suggestedAmenities.contains(a))
                            .map((a) {
                              return Chip(
                                label: Text(a, style: GoogleFonts.cairo()),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () =>
                                    setState(() => _amenities.remove(a)),
                                backgroundColor: Colors.white,
                                shape: StadiumBorder(
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ),
                  const Divider(height: 30),
                  _buildSectionLabel('القواعد والشروط ⚠️'),
                  const SizedBox(height: 10),
                  _buildDynamicAddField(
                    controller: _customRuleController,
                    hint: 'أضف قاعدة جديدة (مثال: ممنوع التدخين)...',
                    onAdd: (val) {
                      setState(() => _rules.add(val));
                    },
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _rules.map((rule) {
                      return Chip(
                        label: Text(rule, style: GoogleFonts.cairo()),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => setState(() => _rules.remove(rule)),
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        labelStyle: const TextStyle(color: Colors.orange),
                        deleteIconColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Colors.orange),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // --- Submit Button ---
              GestureDetector(
                onTap: _isLoading ? null : _submitProperty,
                child: Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF008695).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'نشر الإعلان الآن',
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- Universities Logic ---
  Widget _buildUniversitiesSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('universities')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'حدث خطأ في تحميل الجامعات',
            style: GoogleFonts.cairo(color: Colors.red),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final universityNames = docs
            .map(
              (doc) => (doc.data() as Map<String, dynamic>)['name'] as String,
            )
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('الجامعات المجاورة 🎓', fontSize: 14),
            const SizedBox(height: 10),
            if (universityNames.isEmpty)
              Text(
                'لا توجد جامعات مضافة بعد',
                style: GoogleFonts.cairo(color: Colors.grey),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: universityNames.map((uni) {
                  return _buildSelectableChip(
                    label: uni,
                    value: uni,
                    selectedValues: _selectedUniversities,
                  );
                }).toList(),
              ),
            const SizedBox(height: 15),
            _buildDynamicAddField(
              controller: _customUniversityController,
              hint: 'أضف جامعة جديدة...',
              onAdd: (val) async {
                if (!universityNames.contains(val)) {
                  await FirebaseFirestore.instance
                      .collection('universities')
                      .add({
                        'name': val,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                  if (mounted) {
                    CustomSnackBar.show(
                      context: context,
                      message: 'تم إضافة الجامعة بنجاح ✅',
                      isError: false,
                    );
                    // Auto-select the newly added university
                    setState(() {
                      if (!_selectedUniversities.contains(val)) {
                        _selectedUniversities.add(val);
                      }
                    });
                  }
                } else {
                  if (mounted) {
                    CustomSnackBar.show(
                      context: context,
                      message: 'هذه الجامعة موجودة بالفعل ⚠️',
                      isError: true,
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- UI Helpers ---

  Widget _buildSectionLabel(String text, {double fontSize = 16}) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
        color: const Color(0xFF008695),
      ),
    );
  }

  Widget _buildGlassCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    String? hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.cairo(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
        labelStyle: GoogleFonts.cairo(color: Colors.grey.shade600),
        prefixIcon: icon != null
            ? Icon(icon, color: const Color(0xFF008695), size: 20)
            : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF39BB5E), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      items: items.map((String val) {
        return DropdownMenuItem<String>(
          value: val,
          child: Text(val, style: GoogleFonts.cairo()),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSelectableChip({
    required String label,
    required String value,
    required List<String> selectedValues,
  }) {
    final isSelected = selectedValues.contains(value);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedValues.remove(value);
          } else {
            selectedValues.add(value);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: isSelected
            ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF008695).withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              )
            : BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300),
              ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildGradientSelectionCard({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: isSelected
            ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF008695).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              )
            : BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200, width: 2),
              ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicAddField({
    required TextEditingController controller,
    required String hint,
    required Function(String) onAdd,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: GoogleFonts.cairo(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 10,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (val) {
              if (val.trim().isNotEmpty) {
                onAdd(val.trim());
                controller.clear();
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              onAdd(controller.text.trim());
              controller.clear();
            }
          },
          icon: const Icon(
            Icons.add_circle,
            color: Color(0xFF008695),
            size: 30,
          ),
        ),
      ],
    );
  }
}
