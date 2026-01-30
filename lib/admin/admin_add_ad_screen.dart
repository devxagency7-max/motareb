import 'dart:io';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:admin_motareb/core/utils/loc_extension.dart';
import 'package:admin_motareb/services/r2_upload_service.dart';
import 'package:admin_motareb/services/translation_service.dart';
import 'package:admin_motareb/utils/custom_snackbar.dart';
import 'package:uuid/uuid.dart';

import 'package:admin_motareb/models/ad_model.dart';

class AdminAddAdScreen extends StatefulWidget {
  final AdModel? adToEdit;
  const AdminAddAdScreen({super.key, this.adToEdit});

  @override
  State<AdminAddAdScreen> createState() => _AdminAddAdScreenState();
}

class _AdminAddAdScreenState extends State<AdminAddAdScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameArController;
  late final TextEditingController _nameEnController;
  late final TextEditingController _descArController;
  late final TextEditingController _descEnController;
  late final TextEditingController _addrArController;
  late final TextEditingController _addrEnController;
  late final TextEditingController _phoneController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _mapUrlController;

  late final TextEditingController _typeController;
  bool _isActive = true;
  final List<String> _imageUrls = [];
  bool _isLoading = false;
  final Map<String, double> _uploadProgress = {};

  final R2UploadService _uploadService = R2UploadService();
  final ImagePicker _picker = ImagePicker();
  late final String _adId;

  @override
  void initState() {
    super.initState();
    final ad = widget.adToEdit;
    _adId = ad?.id ?? const Uuid().v4();
    _nameArController = TextEditingController(text: ad?.nameAr);
    _nameEnController = TextEditingController(text: ad?.nameEn);
    _descArController = TextEditingController(text: ad?.descriptionAr);
    _descEnController = TextEditingController(text: ad?.descriptionEn);
    _addrArController = TextEditingController(text: ad?.addressAr);
    _addrEnController = TextEditingController(text: ad?.addressEn);
    _phoneController = TextEditingController(text: ad?.phone);
    _whatsappController = TextEditingController(text: ad?.whatsapp);
    _mapUrlController = TextEditingController(text: ad?.googleMapUrl);
    _typeController = TextEditingController(text: ad?.type);

    if (ad != null) {
      _isActive = ad.isActive;
      _imageUrls.addAll(ad.images);
    }
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _descArController.dispose();
    _descEnController.dispose();
    _addrArController.dispose();
    _addrEnController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _mapUrlController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _translate(
    TextEditingController source,
    TextEditingController target,
  ) async {
    if (source.text.isEmpty) return;
    setState(() => _isLoading = true);
    final translation = await TranslationService.translateToEnglish(
      source.text,
    );
    target.text = translation;
    setState(() => _isLoading = false);
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        for (var image in images) {
          final file = File(image.path);
          setState(() => _uploadProgress[file.path] = 0.1);

          final url = await _uploadService.uploadFile(
            file,
            propertyId: 'ads/$_adId',
          );

          setState(() {
            _imageUrls.add(url);
            _uploadProgress.remove(file.path);
          });
        }
      }
    } catch (e) {
      CustomSnackBar.show(
        context: context,
        message: 'Upload failed: $e',
        isError: true,
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrls.isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: 'Please add at least one image',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('ads').doc(_adId).set({
        'id': _adId,
        'nameAr': _nameArController.text,
        'nameEn': _nameEnController.text,
        'descriptionAr': _descArController.text,
        'descriptionEn': _descEnController.text,
        'addressAr': _addrArController.text,
        'addressEn': _addrEnController.text,
        'type': _typeController.text.trim(),
        'phone': _phoneController.text,
        'whatsapp': _whatsappController.text,
        'googleMapUrl': _mapUrlController.text.trim().isEmpty
            ? null
            : _mapUrlController.text.trim(),
        'images': _imageUrls,
        'isActive': _isActive,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Ad Saved Successfully! 🎉',
          isError: false,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      CustomSnackBar.show(
        context: context,
        message: 'Error: $e',
        isError: true,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.adToEdit != null ? loc.editAd : loc.addAd,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Images Section
              FadeInDown(child: _buildSectionTitle(loc.adImages)),
              const SizedBox(height: 15),
              FadeInDown(
                delay: const Duration(milliseconds: 100),
                child: _buildImagePicker(),
              ),

              const SizedBox(height: 30),

              // Basic Info
              _buildCardSection([
                _buildTextField(
                  _nameArController,
                  loc.nameAr,
                  Icons.title,
                  true,
                ),
                _buildTranslateField(
                  _nameArController,
                  _nameEnController,
                  loc.nameEn,
                ),
                const Divider(height: 30),
                _buildTextField(
                  _descArController,
                  loc.descAr,
                  Icons.description,
                  true,
                  maxLines: 3,
                ),
                _buildTranslateField(
                  _descArController,
                  _descEnController,
                  loc.descEn,
                  maxLines: 3,
                ),
                const Divider(height: 30),
                _buildTextField(
                  _addrArController,
                  loc.addrAr,
                  Icons.location_on,
                  true,
                ),
                _buildTranslateField(
                  _addrArController,
                  _addrEnController,
                  loc.addrEn,
                ),
              ]),

              const SizedBox(height: 20),

              // Contact Info
              _buildCardSection([
                _buildTextField(
                  _phoneController,
                  loc.phoneNumber,
                  Icons.phone,
                  true,
                  keyboardType: TextInputType.phone,
                ),
                _buildTextField(
                  _whatsappController,
                  loc.whatsappNumber,
                  Icons.chat,
                  true,
                  keyboardType: TextInputType.phone,
                ),
                _buildTextField(
                  _mapUrlController,
                  loc.googleMapLink,
                  Icons.map_outlined,
                  false,
                  hint: loc.enterGoogleMapLink,
                ),
              ]),

              const SizedBox(height: 20),

              // Type & Status
              _buildCardSection([
                _buildTextField(
                  _typeController,
                  loc.adType,
                  Icons.category,
                  true,
                  hint: 'مثال: مطعم، صيدلية، كافيه...',
                ),
                const SizedBox(height: 15),
                _buildStatusSwitch(),
              ]),

              const SizedBox(height: 40),

              // Submit Button
              FadeInUp(child: _buildSubmitButton()),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF008695),
      ),
    );
  }

  Widget _buildImagePicker() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF39BB5E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF39BB5E), width: 1.5),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, color: Color(0xFF39BB5E), size: 40),
                  SizedBox(height: 5),
                  Text(
                    'Add Photo',
                    style: TextStyle(
                      color: Color(0xFF39BB5E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ..._imageUrls.map(
            (url) => Container(
              width: 120,
              margin: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: NetworkImage(url),
                  fit: BoxFit.cover,
                ),
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => setState(() => _imageUrls.remove(url)),
                ),
              ),
            ),
          ),
          ..._uploadProgress.entries.map(
            (entry) => Container(
              width: 120,
              margin: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2F3640)
              : Colors.transparent,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool required, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.cairo(),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF008695)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
        validator: required
            ? (value) => value!.isEmpty ? 'Field Required' : null
            : null,
      ),
    );
  }

  Widget _buildTranslateField(
    TextEditingController source,
    TextEditingController target,
    String label, {
    int maxLines = 1,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            target,
            label,
            Icons.translate,
            true,
            maxLines: maxLines,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 55,
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: const Color(0xFF008695).withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF008695)),
            onPressed: () => _translate(source, target),
            tooltip: context.loc.translateToEn,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.loc.activeStatus,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Switch(
          value: _isActive,
          onChanged: (val) => setState(() => _isActive = val),
          activeColor: const Color(0xFF39BB5E),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _submit,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF39BB5E), Color(0xFF008695)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF008695).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  context.loc.save,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
