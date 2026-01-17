import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/models/property_model.dart';
import '../utils/custom_snackbar.dart';

class AdminPropertyDetailsScreen extends StatefulWidget {
  final Property property;

  const AdminPropertyDetailsScreen({super.key, required this.property});

  @override
  State<AdminPropertyDetailsScreen> createState() =>
      _AdminPropertyDetailsScreenState();
}

class _AdminPropertyDetailsScreenState
    extends State<AdminPropertyDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _isEditing = false;
  late Property _currentProperty;

  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _discountPriceController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _featuredLabelController;

  // Selection States
  String? _selectedGovernorate;
  String _selectedGender = 'both';
  String _selectedType = 'شقة';
  List<String> _selectedAmenities = [];
  List<String> _selectedRules = [];

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
  ];

  @override
  void initState() {
    super.initState();
    _currentProperty = widget.property;
    _initializeControllers();
  }

  void _initializeControllers() {
    _titleController = TextEditingController(text: _currentProperty.title);
    _priceController = TextEditingController(
      text: _currentProperty.price.toString(),
    );
    _discountPriceController = TextEditingController(
      text: _currentProperty.discountPrice != null
          ? _currentProperty.discountPrice.toString()
          : '',
    );
    _locationController = TextEditingController(
      text: _currentProperty.location,
    );
    _descriptionController = TextEditingController(
      text: _currentProperty.description ?? '',
    );
    _featuredLabelController = TextEditingController(
      text: _currentProperty.featuredLabel ?? '',
    );

    _selectedGovernorate = _currentProperty.governorate;
    _selectedGender = _currentProperty.gender ?? 'both';
    _selectedType = _currentProperty.type;
    _selectedAmenities = List.from(_currentProperty.amenities);
    _selectedRules = List.from(_currentProperty.rules);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _featuredLabelController.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset controllers to current property values if cancelled
        _initializeControllers();
      }
    });
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      final double price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final double? discountPrice =
          _discountPriceController.text.trim().isNotEmpty
          ? double.tryParse(_discountPriceController.text.trim())
          : null;

      final updates = {
        'title': _titleController.text.trim(),
        'price': price,
        'discountPrice': discountPrice,
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'featuredLabel': _featuredLabelController.text.trim(),
        'governorate': _selectedGovernorate,
        'gender': _selectedGender,
        'type':
            _selectedType, // Note: This might need mapping to isBed/isRoom if those boolean flags are used strictly
        // For now trusting the Property model structure.
        // Actually Property.fromMap logic uses isBed/isRoom flags to derive 'type'.
        // We need to update those flags too based on _selectedType type.
        'isBed': _selectedType == 'سرير',
        'isRoom': _selectedType == 'غرفة',
        // amenities, rules, etc. could be added here if we build UI for them
      };

      await _firestore
          .collection('properties')
          .doc(_currentProperty.id)
          .update(updates);

      // Refresh data
      final doc = await _firestore
          .collection('properties')
          .doc(_currentProperty.id)
          .get();
      if (doc.exists) {
        setState(() {
          _currentProperty = Property.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
          _isEditing = false;
        });
      }

      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'تم حفظ التعديلات بنجاح ✅',
        );
      }
    } catch (e) {
      if (mounted)
        CustomSnackBar.show(
          context: context,
          message: 'خطأ: $e',
          isError: true,
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePropertyField(
    Map<String, dynamic> data,
    String message,
  ) async {
    setState(() => _isLoading = true);
    try {
      await _firestore
          .collection('properties')
          .doc(_currentProperty.id)
          .update(data);
      final doc = await _firestore
          .collection('properties')
          .doc(_currentProperty.id)
          .get();
      if (doc.exists) {
        setState(() {
          _currentProperty = Property.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        });
      }
      if (mounted) CustomSnackBar.show(context: context, message: message);
    } catch (e) {
      if (mounted)
        CustomSnackBar.show(
          context: context,
          message: 'خطأ: $e',
          isError: true,
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleVisibility() async {
    final newStatus = _currentProperty.status == 'approved'
        ? 'hidden'
        : 'approved';
    await _updatePropertyField({
      'status': newStatus,
    }, newStatus == 'approved' ? 'تم إظهار العقار ✅' : 'تم إخفاء العقار 🙈');
  }

  Future<void> _toggleVerification() async {
    final newValue = !_currentProperty.isVerified;
    await _updatePropertyField({
      'isVerified': newValue,
    }, newValue ? 'تم توثيق العقار 🌟' : 'تم إلغاء التوثيق ❌');
  }

  Future<void> _approveProperty() async {
    await _updatePropertyField({
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
    }, 'تم قبول العقار بنجاح! ✅');
    if (mounted) Navigator.pop(context);
  }

  Future<void> _rejectProperty() async {
    String? reason;
    await showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(
            'رفض العقار',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'سبب الرفض...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                reason = controller.text;
                Navigator.pop(context);
              },
              child: const Text(
                'تأكيد الرفض',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
    if (reason == null) return;
    await _updatePropertyField({
      'status': 'rejected',
      'rejectedReason': reason,
    }, 'تم رفض العقار ❌');
    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteProperty() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'حذف نهائي',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من حذف هذا العقار؟ لا يمكن التراجع.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      await _firestore
          .collection('properties')
          .doc(_currentProperty.id)
          .delete();
      if (mounted) {
        CustomSnackBar.show(context: context, message: 'تم الحذف بنجاح 🗑️');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        CustomSnackBar.show(
          context: context,
          message: 'خطأ: $e',
          isError: true,
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'تعديل العقار' : 'تفاصيل العقار',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: _isLoading ? null : _saveChanges,
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: _toggleEditMode,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: _toggleEditMode,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _isLoading ? null : _deleteProperty,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Status Bar ---
                  if (!_isEditing) _buildStatusCard(),
                  const SizedBox(height: 20),

                  // --- Images ---
                  _buildImageGallery(),
                  const SizedBox(height: 20),

                  // --- Admin Controls (View Mode Only) ---
                  if (!_isEditing) ...[
                    _buildAdminControls(),
                    const SizedBox(height: 20),
                  ],

                  // --- Main Details ---
                  _buildGlassCard(
                    title: 'البيانات الأساسية 🏠',
                    children: [
                      // Featured Label
                      if (_isEditing)
                        _buildEditableField(
                          'الكلمة المميزة (اختياري)',
                          _featuredLabelController,
                        )
                      else if (_currentProperty.featuredLabel != null &&
                          _currentProperty.featuredLabel!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _currentProperty.featuredLabel!,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      const Divider(),

                      // Title
                      if (_isEditing)
                        _buildEditableField('عنوان الإعلان *', _titleController)
                      else
                        _buildInfoRow(
                          Icons.title,
                          'العنوان',
                          _currentProperty.title,
                        ),

                      const Divider(),

                      // Price
                      if (_isEditing) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildEditableField(
                                'السعر (ج.م) *',
                                _priceController,
                                isNumber: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildEditableField(
                                'الخصم (اختياري)',
                                _discountPriceController,
                                isNumber: true,
                              ),
                            ),
                          ],
                        ),
                      ] else
                        _buildInfoRow(
                          Icons.monetization_on,
                          'السعر',
                          _currentProperty.discountPrice != null
                              ? '${_currentProperty.discountPrice} ج.م (بدلاً من ${_currentProperty.price})'
                              : '${_currentProperty.price} ج.م',
                        ),

                      const Divider(),

                      // Location & Governorate
                      if (_isEditing)
                        DropdownButtonFormField<String>(
                          value: _selectedGovernorate,
                          decoration: InputDecoration(
                            labelText: 'المحافظة',
                            labelStyle: GoogleFonts.cairo(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: _governorates
                              .map(
                                (g) => DropdownMenuItem(
                                  child: Text(g, style: GoogleFonts.cairo()),
                                  value: g,
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedGovernorate = val),
                        )
                      else
                        _buildInfoRow(
                          Icons.map,
                          'المحافظة',
                          _currentProperty.governorate ?? 'غير محدد',
                        ),

                      const SizedBox(height: 10),

                      if (_isEditing)
                        _buildEditableField(
                          'العنوان التفصيلي *',
                          _locationController,
                        )
                      else
                        _buildInfoRow(
                          Icons.location_on,
                          'العنوان التفصيلي',
                          _currentProperty.location,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- Target Audience ---
                  _buildGlassCard(
                    title: 'الفئة المستهدفة 🎯',
                    children: [
                      // Gender
                      if (_isEditing)
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: InputDecoration(
                            labelText: 'الجنس المطلوب',
                            labelStyle: GoogleFonts.cairo(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'male',
                              child: Text('شباب فقط'),
                            ),
                            DropdownMenuItem(
                              value: 'female',
                              child: Text('بنات فقط'),
                            ),
                            DropdownMenuItem(
                              value: 'both',
                              child: Text('مختلط / عائلات'),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedGender = val!),
                        )
                      else
                        _buildInfoRow(
                          Icons.wc,
                          'الجنس المطلوب',
                          _currentProperty.gender == 'male'
                              ? 'شباب 👨'
                              : _currentProperty.gender == 'female'
                              ? 'بنات 👩'
                              : 'مختلط 👥',
                        ),

                      const Divider(),
                      _buildInfoRow(
                        Icons.school,
                        'الجامعات القريبة',
                        _currentProperty.universities.isEmpty
                            ? 'لا يوجد'
                            : _currentProperty.universities.join('، '),
                      ),
                      const Divider(),
                      _buildInfoRow(
                        Icons.payments,
                        'نظام الدفع',
                        _currentProperty.paymentMethods.isEmpty
                            ? 'غير محدد'
                            : _currentProperty.paymentMethods.join('، '),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- Unit Details ---
                  _buildGlassCard(
                    title: 'تفاصيل السكن 🛌',
                    children: [
                      if (_isEditing)
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: InputDecoration(
                            labelText: 'نوع الوحدة',
                            labelStyle: GoogleFonts.cairo(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'شقة',
                              child: Text('شقة كاملة'),
                            ),
                            DropdownMenuItem(
                              value: 'غرفة',
                              child: Text('غرفة'),
                            ),
                            DropdownMenuItem(
                              value: 'سرير',
                              child: Text('سرير'),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedType = val!),
                        )
                      else
                        _buildInfoRow(
                          Icons.home_work,
                          'نوع الوحدة',
                          _currentProperty.type,
                        ),

                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoRow(
                              Icons.bed,
                              'عدد السراير',
                              '${_currentProperty.bedsCount}',
                            ),
                          ),
                          Expanded(
                            child: _buildInfoRow(
                              Icons.meeting_room,
                              'عدد الغرف',
                              '${_currentProperty.roomsCount}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- Description ---
                  _buildGlassCard(
                    title: 'الوصف 📝',
                    children: [
                      if (_isEditing)
                        _buildEditableField(
                          'الوصف التفصيلي',
                          _descriptionController,
                          maxLines: 5,
                        )
                      else
                        Text(
                          _currentProperty.description ?? 'لا يوجد وصف',
                          style: GoogleFonts.cairo(
                            color: Colors.grey[700],
                            height: 1.6,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- Amenities ---
                  _buildGlassCard(
                    title: 'المميزات ✨',
                    children: [
                      if (_currentProperty.amenities.isEmpty)
                        Text(
                          'لا يوجد مميزات مسجلة',
                          style: GoogleFonts.cairo(color: Colors.grey),
                        ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _currentProperty.amenities
                            .map(
                              (a) => Chip(
                                label: Text(
                                  a,
                                  style: GoogleFonts.cairo(fontSize: 12),
                                ),
                                backgroundColor: Colors.teal.withOpacity(0.1),
                                labelStyle: const TextStyle(color: Colors.teal),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- Rules ---
                  _buildGlassCard(
                    title: 'القواعد والشروط ⚠️',
                    children: [
                      if (_currentProperty.rules.isEmpty)
                        Text(
                          'لا يوجد قواعد مسجلة',
                          style: GoogleFonts.cairo(color: Colors.grey),
                        ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _currentProperty.rules
                            .map(
                              (r) => Chip(
                                label: Text(
                                  r,
                                  style: GoogleFonts.cairo(fontSize: 12),
                                ),
                                backgroundColor: Colors.orange.withOpacity(0.1),
                                labelStyle: const TextStyle(
                                  color: Colors.orange,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // --- UI Components ---

  Widget _buildEditableField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: Colors.grey[600]),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF008695)),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color color;
    String text;
    IconData icon;

    switch (_currentProperty.status) {
      case 'approved':
        color = Colors.green;
        text = 'نشط / مقبول';
        icon = Icons.check_circle;
        break;
      case 'pending':
        color = Colors.orange;
        text = 'قيد المراجعة';
        icon = Icons.hourglass_top;
        break;
      case 'hidden':
        color = Colors.grey;
        text = 'مخفي';
        icon = Icons.visibility_off;
        break;
      case 'rejected':
        color = Colors.red;
        text = 'مرفوض';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.blue;
        text = _currentProperty.status;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'حالة العقار',
                style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                text,
                style: GoogleFonts.cairo(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_currentProperty.isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, color: Colors.blue, size: 16),
                  const SizedBox(width: 5),
                  Text(
                    'موثق',
                    style: GoogleFonts.cairo(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminControls() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تحكم الادمن 🛠️',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  label: _currentProperty.status == 'approved'
                      ? 'إخفاء'
                      : 'إظهار',
                  icon: _currentProperty.status == 'approved'
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.blueGrey,
                  onTap: _toggleVisibility,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildControlButton(
                  label: _currentProperty.isVerified
                      ? 'إلغاء التوثيق'
                      : 'توثيق',
                  icon: Icons.verified,
                  color: Colors.blue,
                  onTap: _toggleVerification,
                ),
              ),
            ],
          ),
          if (_currentProperty.status == 'pending') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildControlButton(
                    label: 'قبول',
                    icon: Icons.check,
                    color: Colors.green,
                    onTap: _approveProperty,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildControlButton(
                    label: 'رفض',
                    icon: Icons.close,
                    color: Colors.red,
                    onTap: _rejectProperty,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.cairo(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    if (_currentProperty.images.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _currentProperty.images.length,
        itemBuilder: (context, index) {
          final img = _currentProperty.images[index];
          return Container(
            width: 300,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: img.startsWith('http')
                    ? NetworkImage(img)
                    : MemoryImage(base64Decode(img)) as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlassCard({
    required String title,
    required List<Widget> children,
  }) {
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF008695),
            ),
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
