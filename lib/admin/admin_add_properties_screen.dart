import 'dart:async';
import 'dart:io';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:admin_motareb/utils/custom_snackbar.dart';
import 'package:admin_motareb/services/r2_upload_service.dart';

import 'package:admin_motareb/core/models/property_model.dart'; // Add Import

class AdminAddPropertyScreen extends StatefulWidget {
  final Property? propertyToEdit; // Add optional property

  const AdminAddPropertyScreen({super.key, this.propertyToEdit});

  @override
  State<AdminAddPropertyScreen> createState() => _AdminAddPropertyScreenState();
}

class _AdminAddPropertyScreenState extends State<AdminAddPropertyScreen> {
  // --- Controllers ---
  final _adminNumberController = TextEditingController(); // Renamed
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _bathroomsController = TextEditingController(text: '1'); // Default 1
  // NEW: Rooms Notifier for dynamic units
  final ValueNotifier<List<Map<String, dynamic>>> _roomsNotifier =
      ValueNotifier([]);
  final _featuredLabelController = TextEditingController();

  // Custom add controllers
  final _customRuleController = TextEditingController();
  final _customAmenityController = TextEditingController();
  final _customUniversityController = TextEditingController();

  // --- State Management (ValueNotifiers) ---
  final ValueNotifier<List<String>> _imagesNotifier = ValueNotifier([]);
  final ValueNotifier<String?> _videoUrlNotifier = ValueNotifier(null);

  // Validation State
  final ValueNotifier<String?> _idErrorNotifier = ValueNotifier(
    null,
  ); // NEW: For ID validation error
  final ValueNotifier<bool> _isCheckingIdNotifier = ValueNotifier(
    false,
  ); // NEW: Loading state for check

  final ValueNotifier<List<String>> _amenitiesNotifier = ValueNotifier([]);
  final ValueNotifier<List<String>> _rulesNotifier = ValueNotifier([]);

  // Selections
  final ValueNotifier<List<String>> _selectedUnitTypesNotifier = ValueNotifier(
    [],
  );
  final ValueNotifier<String> _selectedGenderNotifier = ValueNotifier('male');
  final ValueNotifier<List<String>> _paymentMethodsNotifier = ValueNotifier([]);
  final ValueNotifier<List<String>> _selectedUniversitiesNotifier =
      ValueNotifier([]);
  final ValueNotifier<String> _selectedGovernorateNotifier = ValueNotifier(
    'بني سويف',
  );

  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(false);

  final ImagePicker _picker = ImagePicker();

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.propertyToEdit != null) {
      _preFillData();
    } else {
      _adminNumberController.addListener(_onIdChanged);
    }
  }

  void _onIdChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _checkIdAvailability();
    });
  }

  Future<void> _checkIdAvailability() async {
    final number = _adminNumberController.text.trim();
    if (number.isEmpty) {
      _idErrorNotifier.value = null;
      return;
    }

    _isCheckingIdNotifier.value = true;
    final potentialId = 'T${number}Z';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('properties')
          .doc(potentialId)
          .get();

      if (doc.exists) {
        _idErrorNotifier.value = 'لا يمكن الاستخدام ⛔';
      } else {
        _idErrorNotifier.value = null; // Available
      }
    } catch (e) {
      // Handle error cleanly, maybe minor log
      _idErrorNotifier.value = null;
    } finally {
      _isCheckingIdNotifier.value = false;
    }
  }

  void _preFillData() {
    final p = widget.propertyToEdit!;

    // Extract ID Number
    // Assumes format T123Z -> 123
    final idMatch = RegExp(r'T(\d+)Z').firstMatch(p.id);
    if (idMatch != null) {
      _adminNumberController.text = idMatch.group(1) ?? '';
    } else {
      _adminNumberController.text = p.id;
    }

    _titleController.text = p.title;
    _priceController.text = p.price.toString();
    _discountPriceController.text = p.discountPrice?.toString() ?? '';
    _locationController.text = p.location;
    _descriptionController.text = p.description ?? '';
    _bathroomsController.text = p.bathroomsCount.toString(); // Bathrooms

    // Pre-fill rooms if available
    if (p.rooms.isNotEmpty) {
      _roomsNotifier.value = List.from(p.rooms);
    }
    _featuredLabelController.text = p.featuredLabel ?? '';

    _imagesNotifier.value = List.from(p.images);
    _videoUrlNotifier.value = p.videoUrl;

    _amenitiesNotifier.value = List.from(p.amenities);
    _rulesNotifier.value = List.from(p.rules);

    _selectedGenderNotifier.value = p.gender ?? 'male';
    _selectedGovernorateNotifier.value = p.governorate ?? 'بني سويف';
    _paymentMethodsNotifier.value = List.from(p.paymentMethods);
    _selectedUniversitiesNotifier.value = List.from(p.universities);

    // Reconstruct unit types
    List<String> types = [];
    if (p.unitTypes.isNotEmpty) {
      types = List.from(p.unitTypes); // If we added this field to model
    } else {
      // Fallback relative to booleans if unitTypes not yet in model fully
      // But we just added it to map in submit, check model if it has unitTypes
      // For safety, let's derive
      if (p.isBed) types.add('bed');
      if (p.isRoom) types.add('room');
      // studio?
    }
    _selectedUnitTypesNotifier.value = types;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _adminNumberController.removeListener(_onIdChanged);
    _adminNumberController
        .dispose(); // Do not verify logic again, just clean up
    _titleController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _bathroomsController.dispose();
    _roomsNotifier.dispose();
    _featuredLabelController.dispose();
    _customRuleController.dispose();
    _customAmenityController.dispose();
    _customUniversityController.dispose();

    _imagesNotifier.dispose();
    _videoUrlNotifier.dispose();
    _amenitiesNotifier.dispose();
    _rulesNotifier.dispose();
    _selectedUnitTypesNotifier.dispose();
    _selectedGenderNotifier.dispose();
    _paymentMethodsNotifier.dispose();
    _selectedUniversitiesNotifier.dispose();
    _selectedGovernorateNotifier.dispose();
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  Future<void> _submitProperty() async {
    // Validate ID First
    if (_adminNumberController.text.trim().isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: 'يجب إدخال رقم العقار أولاً ❗',
        isError: true,
      );
      return;
    }
    // Optional: Re-check duplicates here if paranoia is needed, but we rely on the initial check for UX.
    if (widget.propertyToEdit == null && _idErrorNotifier.value != null) {
      CustomSnackBar.show(
        context: context,
        message: 'رقم العقار غير متاح: ${_idErrorNotifier.value}',
        isError: true,
      );
      return;
    }

    // Validate Other Fields
    if (_imagesNotifier.value.isEmpty) {
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

    _isLoadingNotifier.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      final String uid = user?.uid ?? 'admin_override_id';

      final String adminNumberStr = _adminNumberController.text.trim();
      final String finalPropertyId = 'T${adminNumberStr}Z';

      // If editing, preserve original ID if it was T...Z, or use the new controller one?
      // Generally we might want to disallow ID changes, but let's stick to using the controller value because pre-fill put it there.
      // If user changed ID, it acts like a new property or overwrite.

      final propertyData = {
        'id': finalPropertyId, // T#Z
        'propertyId': finalPropertyId,
        'adminNumber': int.tryParse(adminNumberStr) ?? 0,
        'ownerId': uid,
        'title': _titleController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'discountPrice': _discountPriceController.text.trim().isNotEmpty
            ? double.tryParse(_discountPriceController.text.trim())
            : null,
        'location': _locationController.text.trim().isEmpty
            ? 'غير محدد'
            : _locationController.text.trim(),
        'governorate': _selectedGovernorateNotifier.value,
        'description': _descriptionController.text.trim(),
        'featuredLabel': _featuredLabelController.text.trim(),
        'images': _imagesNotifier.value,
        'videoUrl': _videoUrlNotifier.value,
        'amenities': _amenitiesNotifier.value,
        'rules': _rulesNotifier.value,
        'isBed': _selectedUnitTypesNotifier.value.contains('bed'),
        'isRoom': _selectedUnitTypesNotifier.value.contains('room'),
        'isStudio': _selectedUnitTypesNotifier.value.contains('studio'),
        'unitTypes': _selectedUnitTypesNotifier.value,
        'status': widget.propertyToEdit != null
            ? widget.propertyToEdit!.status
            : 'approved',
        'createdAt': widget.propertyToEdit != null
            ? widget.propertyToEdit!.createdAt
            : FieldValue.serverTimestamp(),
        'rating': widget.propertyToEdit?.rating ?? 0.0,
        'ratingCount': widget.propertyToEdit?.ratingCount ?? 0,
        'agentName': 'المشرف',
        'gender': _selectedGenderNotifier.value,
        'paymentMethods': _paymentMethodsNotifier.value,
        'universities': _selectedUniversitiesNotifier.value,
        'bedsCount': _roomsNotifier.value.fold<int>(
          0,
          (sum, room) => sum + (room['beds'] as int? ?? 0),
        ),
        'roomsCount': _roomsNotifier.value.length,
        'singleRoomsCount': 0, // Deprecated/Legacy
        'doubleRoomsCount': 0, // Deprecated/Legacy
        'singleBedsCount': 0, // Deprecated/Legacy
        'doubleBedsCount': 0, // Deprecated/Legacy
        'bathroomsCount': int.tryParse(_bathroomsController.text.trim()) ?? 1,
        'rooms': _roomsNotifier.value, // NEW: Save rooms list
      };

      if (widget.propertyToEdit != null) {
        // Update existing
        await FirebaseFirestore.instance
            .collection('properties')
            .doc(
              widget.propertyToEdit!.id,
            ) // Use ORIGINAL doc id to ensure update
            .update(propertyData);

        // Note: If user changed the ID Number in text field, `finalPropertyId` will change.
        // But we are updating `widget.propertyToEdit!.id`.
        // If we want to allow ID change, we must delete old doc and create new one.
        // For simplicity, let's assume update keeps same doc ID, but if controller text changed, we might have mismatch.
        // PLAN: We should disable ID editing in Edit Mode.
      } else {
        // Create new
        await FirebaseFirestore.instance
            .collection('properties')
            .doc(finalPropertyId)
            .set(propertyData);
      }

      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: widget.propertyToEdit != null
              ? 'تم تحديث العقار بنجاح! ✅'
              : 'تم نشر العقار بنجاح! 🎉',
          isError: false,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'حدث خطأ: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) _isLoadingNotifier.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.propertyToEdit != null
              ? 'تعديل بيانات العقار'
              : 'إضافة عقار جديد',
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
              // --- Admin Number Input ---
              Container(
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
                padding: const EdgeInsets.all(15),
                margin: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رقم العقار (يحدد الادمن فقط الرقم) *',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _adminNumberController,
                            keyboardType: TextInputType.number,
                            readOnly:
                                widget.propertyToEdit !=
                                null, // Lock ID in edit mode
                            style: TextStyle(
                              color: widget.propertyToEdit != null
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'مثال: 123',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              fillColor: widget.propertyToEdit != null
                                  ? Colors.grey.shade100
                                  : null,
                              filled: widget.propertyToEdit != null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ValueListenableBuilder<bool>(
                          valueListenable: _isCheckingIdNotifier,
                          builder: (context, isChecking, _) {
                            if (isChecking) {
                              return const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                    // ID Preview & Error
                    ValueListenableBuilder<String?>(
                      valueListenable: _idErrorNotifier,
                      builder: (context, error, _) {
                        return ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _adminNumberController,
                          builder: (context, val, _) {
                            if (val.text.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            final previewId = 'T-${val.text}Z';
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'ID : $previewId',
                                      style: GoogleFonts.cairo(
                                        color: Colors.blueGrey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (error != null) ...[
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        error,
                                        style: GoogleFonts.cairo(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ] else if (widget.propertyToEdit != null) ...[
                                    const SizedBox(width: 10),
                                    const Text('🔒 (للقراءة فقط)'),
                                  ] else ...[
                                    const SizedBox(width: 10),
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              // --- Image Picker Section ---
              _ImagesPickerSection(
                imagesNotifier: _imagesNotifier,
                videoNotifier: _videoUrlNotifier,
                picker: _picker,
                adminNumberController: _adminNumberController, // Passed
                idErrorNotifier: _idErrorNotifier, // Passed
              ),
              const SizedBox(height: 25),

              // --- Main Info Glass Card ---
              _MainInfoCard(
                titleController: _titleController,
                priceController: _priceController,
                discountPriceController: _discountPriceController,
                locationController: _locationController,
                featuredLabelController: _featuredLabelController,
                governorateNotifier: _selectedGovernorateNotifier,
                // Passing university stuff to be used inside or alongside
                universitiesNotifier: _selectedUniversitiesNotifier,
                customUniversityController: _customUniversityController,
              ),
              const SizedBox(height: 20),

              // --- Booking & Unit Details (Refactored) ---
              _AvailableUnitsCard(
                roomsNotifier: _roomsNotifier,
                bathroomsController: _bathroomsController,
                priceController: _priceController,
                discountPriceController: _discountPriceController,
              ),
              const SizedBox(height: 20),

              // --- Description ---
              _DescriptionCard(descriptionController: _descriptionController),
              const SizedBox(height: 20),

              // --- Target Audience & Payment ---
              _AudiencePaymentCard(
                genderNotifier: _selectedGenderNotifier,
                paymentMethodsNotifier: _paymentMethodsNotifier,
              ),
              const SizedBox(height: 20),

              // --- Amenities & Rules ---
              _AmenitiesRulesCard(
                amenitiesNotifier: _amenitiesNotifier,
                rulesNotifier: _rulesNotifier,
                customAmenityController: _customAmenityController,
                customRuleController: _customRuleController,
              ),
              const SizedBox(height: 30),

              // --- Submit Button ---
              ValueListenableBuilder<bool>(
                valueListenable: _isLoadingNotifier,
                builder: (context, isLoading, child) {
                  return GestureDetector(
                    onTap: isLoading ? null : _submitProperty,
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
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    widget.propertyToEdit != null
                                        ? 'حفظ التعديلات'
                                        : 'نشر الإعلان الآن',
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
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// ========================== SEPARATE WIDGETS =============================
// =========================================================================

// --- 1. Images Picker Section ---
// --- 1. Images & Video Picker Section ---
class _ImagesPickerSection extends StatefulWidget {
  final ValueNotifier<List<String>> imagesNotifier;
  final ValueNotifier<String?> videoNotifier;
  final ImagePicker picker;
  final TextEditingController adminNumberController; // Changed
  final ValueNotifier<String?> idErrorNotifier; // New

  const _ImagesPickerSection({
    required this.imagesNotifier,
    required this.videoNotifier,
    required this.picker,
    required this.adminNumberController, // Changed
    required this.idErrorNotifier, // New
  });

  @override
  State<_ImagesPickerSection> createState() => _ImagesPickerSectionState();
}

class _ImagesPickerSectionState extends State<_ImagesPickerSection> {
  final R2UploadService _uploadService = R2UploadService();
  final Map<String, double> _uploadProgress =
      {}; // File path -> progress (0.0 to 1.0)

  // Concurrency Helper
  Future<void> _processUploads(List<File> files) async {
    final number = widget.adminNumberController.text.trim();
    if (number.isEmpty) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'يجب إدخال رقم العقار أولاً! ⚠️',
          isError: true,
        );
      }
      return;
    }
    if (widget.idErrorNotifier.value != null) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: '❌ لا يمكن الرفع: المسلسل موجود بالفعل',
          isError: true,
        );
      }
      return;
    }

    final formattedId = 'T${number}Z';

    // Process sequentially (one by one)
    for (final file in files) {
      if (!mounted) return; // Guard clause

      setState(() {
        _uploadProgress[file.path] = 0.1; // Started
      });

      try {
        // Upload with FormattedID
        final url = await _uploadService.uploadFile(
          file,
          propertyId: formattedId,
        );

        if (mounted) {
          // Add URL to notifier
          final currentUrls = List<String>.from(widget.imagesNotifier.value);
          currentUrls.add(url);
          widget.imagesNotifier.value = currentUrls;

          setState(() {
            _uploadProgress.remove(file.path); // Done
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _uploadProgress.remove(file.path); // Failed
          });
          CustomSnackBar.show(
            context: context,
            message: 'فشل رفع صورة: $e',
            isError: true,
          );
        }
      }
    }
  }

  Future<void> _pickMultiImages(BuildContext context) async {
    try {
      final List<XFile> images = await widget.picker.pickMultiImage();
      if (images.isNotEmpty) {
        final files = images.map((x) => File(x.path)).toList();
        await _processUploads(files);
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

  Future<void> _pickVideo(BuildContext context) async {
    final number = widget.adminNumberController.text.trim();
    if (number.isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: 'يجب إدخال رقم العقار أولاً! ⚠️',
        isError: true,
      );
      return;
    }
    if (widget.idErrorNotifier.value != null) {
      CustomSnackBar.show(
        context: context,
        message: '❌ لا يمكن الرفع: المسلسل موجود بالفعل',
        isError: true,
      );
      return;
    }

    final formattedId = 'T${number}Z';

    try {
      final XFile? video = await widget.picker.pickVideo(
        source: ImageSource.gallery,
      );
      if (video != null) {
        final file = File(video.path);

        setState(() {
          _uploadProgress[file.path] = 0.1;
        });

        try {
          final url = await _uploadService.uploadFile(
            file,
            propertyId: formattedId,
            onProgress: (sent, total) {
              if (mounted) {
                setState(() {
                  _uploadProgress[file.path] = sent / total;
                });
              }
            },
          );
          if (mounted) {
            widget.videoNotifier.value = url;
            setState(() {
              _uploadProgress.remove(file.path);
            });
            CustomSnackBar.show(
              context: context,
              message: 'تم رفع الفيديو بنجاح 🎥',
              isError: false,
            );
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _uploadProgress.remove(file.path);
            });
            CustomSnackBar.show(
              context: context,
              message: 'فشل رفع الفيديو: $e',
              isError: true,
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'خطأ في اختيار الفيديو: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _deleteVideo(BuildContext context, String url) async {
    setState(() {
      _uploadProgress['deleting_video'] = 0.5;
    });

    try {
      await _uploadService.deleteFile(url);
      if (mounted) {
        widget.videoNotifier.value = null; // Clear from UI
        CustomSnackBar.show(
          context: context,
          message: 'تم حذف الفيديو بنجاح 🗑️',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'فشل حذف الفيديو: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadProgress.remove('deleting_video');
        });
      }
    }
  }

  Future<void> _deleteImage(BuildContext context, String url) async {
    // Show loading or feedback?
    // For now, let's just try to delete.
    // Ideally we show a loading indicator on that specific image, but 'uploadProgress' is mainly for files.
    // Let's use a simple blocking approach or optimistic.

    // We'll mark it in a local set if we want to show a spinner,
    // but for simplicity let's just await and show result.

    try {
      await _uploadService.deleteFile(url);

      if (mounted) {
        final updated = List<String>.from(widget.imagesNotifier.value);
        updated.remove(url);
        widget.imagesNotifier.value = updated;

        CustomSnackBar.show(
          context: context,
          message: 'تم حذف الصورة بنجاح 🗑️',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'فشل حذف الصورة: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Images ---
        _SectionLabel('صور العقار 📸'),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: ValueListenableBuilder<List<String>>(
            valueListenable: widget.imagesNotifier,
            builder: (context, imageUrls, child) {
              // Combine uploaded URLs with currently uploading tasks if we wanted to show placeholders.
              // For simplicity, we show Uploading logic separately or use a loading overlay?
              // Let's keep it simple: Show 'Add' button + Uploaded Images.
              // If _uploadProgress is not empty, we can show a global spinner or placeholders.

              final isUploading = _uploadProgress.isNotEmpty;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: imageUrls.length + 1 + (isUploading ? 1 : 0),
                itemBuilder: (context, index) {
                  // 1. Add Button
                  if (index == 0) {
                    return GestureDetector(
                      onTap: isUploading
                          ? null
                          : () => _pickMultiImages(context),
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(left: 10),
                        decoration: BoxDecoration(
                          color: isUploading ? Colors.grey.shade200 : null,
                          gradient: isUploading
                              ? null
                              : LinearGradient(
                                  colors: [
                                    const Color(0xFF39BB5E).withOpacity(0.1),
                                    const Color(0xFF008695).withOpacity(0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isUploading
                                ? Colors.grey
                                : const Color(0xFF39BB5E),
                            style: BorderStyle.solid,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isUploading)
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else ...[
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
                          ],
                        ),
                      ),
                    );
                  }

                  // 2. Uploading Indicator (if active)
                  if (isUploading && index == 1) {
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(left: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.blueAccent.withOpacity(0.5),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${_uploadProgress.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'جاري الرفع...',
                              style: TextStyle(fontSize: 10),
                            ),
                            const SizedBox(height: 5),
                            const CircularProgressIndicator(strokeWidth: 2),
                          ],
                        ),
                      ),
                    );
                  }

                  // 3. Display Image
                  final urlIndex = index - 1 - (isUploading ? 1 : 0);
                  // Safety check
                  if (urlIndex < 0 || urlIndex >= imageUrls.length)
                    return const SizedBox();

                  final url = imageUrls[urlIndex];

                  return Stack(
                    children: [
                      Container(
                        width: 120,
                        margin: const EdgeInsets.only(left: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: NetworkImage(url),
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
                          onTap: () =>
                              _deleteImage(context, url), // Call delete here
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
              );
            },
          ),
        ),

        // --- Video ---
        const SizedBox(height: 20),
        _SectionLabel('فيديو العقار (اختياري) 🎥'),
        const SizedBox(height: 10),
        ValueListenableBuilder<String?>(
          valueListenable: widget.videoNotifier,
          builder: (context, videoUrl, child) {
            final isUploadingVideo = _uploadProgress.keys.any(
              (k) => k.endsWith('.mp4') || k.endsWith('.mov'),
            );
            final isDeleting = _uploadProgress.containsKey('deleting_video');

            if (videoUrl != null) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'تم رفع الفيديو بنجاح ✅',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isDeleting)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteVideo(context, videoUrl),
                      ),
                  ],
                ),
              );
            }

            if (isUploadingVideo) {
              final activeUploadPath = _uploadProgress.keys.firstWhere(
                (k) => k.endsWith('.mp4') || k.endsWith('.mov'),
                orElse: () => '',
              );
              final progress = _uploadProgress[activeUploadPath] ?? 0.0;
              final percentage = (progress * 100).toStringAsFixed(0);

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'جاري رفع الفيديو...',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.blue.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue.shade700,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ],
                ),
              );
            }

            return GestureDetector(
              onTap: (isDeleting) ? null : () => _pickVideo(context),
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'اضغط لرفع فيديو',
                        style: GoogleFonts.cairo(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// --- 2. Main Info Card ---
class _MainInfoCard extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController priceController;
  final TextEditingController discountPriceController;
  final TextEditingController locationController;
  final TextEditingController featuredLabelController;
  final ValueNotifier<String> governorateNotifier;
  final ValueNotifier<List<String>> universitiesNotifier;
  final TextEditingController customUniversityController;

  const _MainInfoCard({
    required this.titleController,
    required this.priceController,
    required this.discountPriceController,
    required this.locationController,
    required this.featuredLabelController,
    required this.governorateNotifier,
    required this.universitiesNotifier,
    required this.customUniversityController,
  });

  static const List<String> _governorates = [
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
  Widget build(BuildContext context) {
    return _GlassCard(
      children: [
        _SectionLabel('بيانات العقار الأساسية 🏠'),
        const SizedBox(height: 15),
        _CustomTextField(
          label: 'عنوان الإعلان المميز (الزامي) *',
          hint: 'مثال: ستوديو فاخر بجوار الجامعة',
          controller: titleController,
          icon: Icons.title,
        ),
        const SizedBox(height: 15),
        _CustomTextField(
          label: 'السعر (ج.م) (الزامي) *',
          hint: '0.0',
          controller: priceController,
          keyboardType: TextInputType.number,
          icon: Icons.monetization_on_outlined,
        ),
        const SizedBox(height: 15),
        _CustomTextField(
          label: 'سعر الخصم (اختياري)',
          hint: '0.0 (اتركه فارغاً إذا لا يوجد خصم)',
          controller: discountPriceController,
          keyboardType: TextInputType.number,
          icon: Icons.local_offer_outlined,
        ),
        const SizedBox(height: 15),
        ValueListenableBuilder<String>(
          valueListenable: governorateNotifier,
          builder: (context, currentGov, child) {
            return DropdownButtonFormField<String>(
              value: currentGov,
              decoration: InputDecoration(
                labelText: 'المحافظة (الزامي) *',
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
              items: _governorates.map((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(val, style: GoogleFonts.cairo()),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) governorateNotifier.value = val;
              },
            );
          },
        ),
        const SizedBox(height: 15),
        _CustomTextField(
          label: 'الموقع التفصيلي',
          hint: 'الشارع، الحي، علامة مميزة...',
          controller: locationController,
          icon: Icons.location_on_outlined,
          maxLines: 3,
        ),
        const SizedBox(height: 15),

        // --- Universities Selector (Nested) ---
        _UniversitiesSelectorSection(
          selectedUniversitiesNotifier: universitiesNotifier,
          customUniversityController: customUniversityController,
        ),
        const SizedBox(height: 15),
        _CustomTextField(
          label: 'كلمة مميزة (بادج)',
          hint: 'مثال: خصم خاص، فرصة، قريب جداً',
          controller: featuredLabelController,
          icon: Icons.stars_rounded,
        ),
      ],
    );
  }
}

// --- 2.1 Universities Selector Logic ---
class _UniversitiesSelectorSection extends StatelessWidget {
  final ValueNotifier<List<String>> selectedUniversitiesNotifier;
  final TextEditingController customUniversityController;

  const _UniversitiesSelectorSection({
    required this.selectedUniversitiesNotifier,
    required this.customUniversityController,
  });

  @override
  Widget build(BuildContext context) {
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
        final globalUniversities = docs
            .map(
              (doc) => (doc.data() as Map<String, dynamic>)['name'] as String,
            )
            .toList();

        return ValueListenableBuilder<List<String>>(
          valueListenable: selectedUniversitiesNotifier,
          builder: (context, selected, child) {
            // Merge global list with any locally added universities that aren't in the global list
            // We use a Set to ensure uniqueness and then convert back to list
            final allUniversities = {
              ...globalUniversities,
              ...selected,
            }.toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel('الجامعات المجاورة 🎓', fontSize: 14),
                const SizedBox(height: 10),
                if (allUniversities.isEmpty)
                  Text(
                    'لا توجد جامعات مضافة بعد',
                    style: GoogleFonts.cairo(color: Colors.grey),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allUniversities.map((uni) {
                      return _SelectableChip(
                        label: uni,
                        value: uni,
                        isSelected: selected.contains(uni),
                        onTap: () {
                          final list = List<String>.from(selected);
                          if (list.contains(uni)) {
                            list.remove(uni);
                          } else {
                            list.add(uni);
                          }
                          selectedUniversitiesNotifier.value = list;
                        },
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 15),
                _DynamicAddField(
                  controller: customUniversityController,
                  hint: 'أضف جامعة جديدة (خاصة بهذا العقار)...',
                  onAdd: (val) {
                    final trimmedVal = val.trim();
                    if (trimmedVal.isNotEmpty) {
                      // Check if already selected
                      final list = List<String>.from(
                        selectedUniversitiesNotifier.value,
                      );
                      if (!list.contains(trimmedVal)) {
                        list.add(trimmedVal);
                        selectedUniversitiesNotifier.value = list;

                        CustomSnackBar.show(
                          context: context,
                          message: 'تم إضافة الجامعة للعقار ✅',
                          isError: false,
                        );
                      } else {
                        CustomSnackBar.show(
                          context: context,
                          message: 'هذه الجامعة مضافة بالفعل ⚠️',
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
      },
    );
  }
}

// --- 3. Description Card ---
class _DescriptionCard extends StatelessWidget {
  final TextEditingController descriptionController;

  const _DescriptionCard({required this.descriptionController});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      children: [
        _SectionLabel('وصف المكان 📝'),
        const SizedBox(height: 15),
        _CustomTextField(
          label: 'وصف كامل للعقار (الزامي) *',
          hint: 'اكتب كل التفاصيل اللي تميز مكانك...',
          controller: descriptionController,
          maxLines: 4,
        ),
      ],
    );
  }
}

// --- 3.5 Available Units Card (New) ---
class _AvailableUnitsCard extends StatefulWidget {
  final ValueNotifier<List<Map<String, dynamic>>> roomsNotifier;
  final TextEditingController bathroomsController;
  final TextEditingController priceController;
  final TextEditingController discountPriceController;

  const _AvailableUnitsCard({
    required this.roomsNotifier,
    required this.bathroomsController,
    required this.priceController,
    required this.discountPriceController,
  });

  @override
  State<_AvailableUnitsCard> createState() => _AvailableUnitsCardState();
}

class _AvailableUnitsCardState extends State<_AvailableUnitsCard> {
  Timer? _debouncePrice;

  @override
  void initState() {
    super.initState();
    widget.priceController.addListener(_onPriceChanged);
    widget.discountPriceController.addListener(_onPriceChanged);
  }

  @override
  void dispose() {
    widget.priceController.removeListener(_onPriceChanged);
    widget.discountPriceController.removeListener(_onPriceChanged);
    _debouncePrice?.cancel();
    super.dispose();
  }

  void _onPriceChanged() {
    if (_debouncePrice?.isActive ?? false) _debouncePrice!.cancel();
    _debouncePrice = Timer(const Duration(milliseconds: 500), () {
      _recalculatePrices();
    });
  }

  void _recalculatePrices() {
    // Priority: Discount Price > Regular Price
    final discountText = widget.discountPriceController.text.trim();
    final regularText = widget.priceController.text.trim();

    double totalPrice = double.tryParse(discountText) ?? 0.0;
    if (totalPrice <= 0) {
      totalPrice = double.tryParse(regularText) ?? 0.0;
    }

    final currentRooms = List<Map<String, dynamic>>.from(
      widget.roomsNotifier.value,
    );
    if (currentRooms.isEmpty) return;

    // Calculate Total Weight
    // Single Room = 2 units
    // Others = Number of beds
    int totalWeight = 0;
    for (var room in currentRooms) {
      final type = room['type'];
      final beds = (room['beds'] as int?) ?? 0;

      if (type == 'Single') {
        totalWeight += 2;
      } else {
        totalWeight += beds;
      }
    }

    if (totalWeight == 0) return;

    final pricePerUnit = totalPrice / totalWeight;

    // Apply Prices
    final updatedRooms = currentRooms.map((room) {
      final type = room['type'];
      final beds = (room['beds'] as int?) ?? 0;

      double roomPrice;
      if (type == 'Single') {
        roomPrice = pricePerUnit * 2;
      } else {
        roomPrice = pricePerUnit * beds;
      }

      // Calculate Bed Price
      double bedPrice = beds > 0 ? roomPrice / beds : 0.0;

      final newRoom = Map<String, dynamic>.from(room);
      newRoom['price'] = double.parse(roomPrice.toStringAsFixed(2));
      newRoom['bedPrice'] = double.parse(
        bedPrice.toStringAsFixed(2),
      ); // New: Store Bed Price
      return newRoom;
    }).toList();

    widget.roomsNotifier.value = updatedRooms;
  }

  void _addRoom(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddRoomSheet(
        onAdd: (room) {
          final list = List<Map<String, dynamic>>.from(
            widget.roomsNotifier.value,
          );
          list.add(room);
          widget.roomsNotifier.value = list;

          // Trigger Recalculate immediately
          _recalculatePrices();

          Navigator.pop(context);
        },
      ),
    );
  }

  void _removeRoom(int index) {
    final list = List<Map<String, dynamic>>.from(widget.roomsNotifier.value);
    list.removeAt(index);
    widget.roomsNotifier.value = list;

    // Trigger Recalculate
    _recalculatePrices();
  }

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _SectionLabel('المرافق وتوزيع الغرف 🛏️', fontSize: 13),
            ),
            const SizedBox(width: 8),
            // Bathrooms
            SizedBox(
              width: 90,
              child: _CustomTextField(
                label: 'الحمامات',
                hint: '1',
                controller: widget.bathroomsController,
                keyboardType: TextInputType.number,
                icon: Icons.bathtub_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _SectionLabel('الوحدات المتاحة', fontSize: 16),
        const SizedBox(height: 10),
        ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: widget.roomsNotifier,
          builder: (context, rooms, child) {
            return Column(
              children: [
                if (rooms.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.meeting_room_outlined,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'لا توجد غرف مضافة بعد',
                          style: GoogleFonts.cairo(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rooms.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      // derive label
                      String label = 'غرفة مخصصة';
                      final type = room['type'];
                      if (type == 'Single')
                        label = 'غرفة فردية (سنجل)';
                      else if (type == 'Double')
                        label = 'غرفة مزدوجة (2 سرير)';
                      else if (type == 'Triple')
                        label = 'غرفة ثلاثية (3 سراير)';

                      final beds = room['beds'] ?? 0;
                      final price = room['price'] ?? 0.0;
                      final bedPrice = room['bedPrice'] ?? 0.0;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF39BB5E).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.bed,
                                color: Color(0xFF39BB5E),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'عدد السراير: $beds',
                                    style: GoogleFonts.cairo(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Text(
                                        'الغرفة: $price ج.م',
                                        style: GoogleFonts.cairo(
                                          color: const Color(0xFF008695),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Container(
                                        height: 10,
                                        width: 1,
                                        color: Colors.grey,
                                      ),
                                      Text(
                                        'السرير: $bedPrice ج.م',
                                        style: GoogleFonts.cairo(
                                          color: Colors.orange.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () =>
                                  _editRoomDetails(context, index, room),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _removeRoom(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 15),
                // Add Button
                GestureDetector(
                  onTap: () => _addRoom(context),
                  child: Container(
                    width: double.infinity,
                    height: 45,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF39BB5E)),
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFF39BB5E).withOpacity(0.05),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, color: Color(0xFF39BB5E)),
                        const SizedBox(width: 5),
                        Text(
                          'إضافة غرفة',
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF39BB5E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _editRoomDetails(
    BuildContext context,
    int index,
    Map<String, dynamic> room,
  ) {
    showDialog(
      context: context,
      builder: (context) => _RoomEditDialog(
        currentRoom: room,
        onSave: (updatedRoom) {
          final list = List<Map<String, dynamic>>.from(
            widget.roomsNotifier.value,
          );
          list[index] = updatedRoom;
          widget.roomsNotifier.value = list;
        },
      ),
    );
  }
}

// --- New Edit Dialog ---
class _RoomEditDialog extends StatefulWidget {
  final Map<String, dynamic> currentRoom;
  final Function(Map<String, dynamic>) onSave;

  const _RoomEditDialog({required this.currentRoom, required this.onSave});

  @override
  State<_RoomEditDialog> createState() => _RoomEditDialogState();
}

class _RoomEditDialogState extends State<_RoomEditDialog> {
  late TextEditingController _bedsController;
  late TextEditingController _roomPriceController;
  late TextEditingController _bedPriceController;

  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    final beds = widget.currentRoom['beds'] ?? 0;
    final roomPrice = widget.currentRoom['price'] ?? 0.0;
    final bedPrice =
        widget.currentRoom['bedPrice'] ?? (beds > 0 ? roomPrice / beds : 0.0);

    _bedsController = TextEditingController(text: beds.toString());
    _roomPriceController = TextEditingController(text: roomPrice.toString());
    _bedPriceController = TextEditingController(text: bedPrice.toString());

    // Listeners for auto-calc logic in dialog
    _roomPriceController.addListener(_onRoomPriceChanged);
    _bedPriceController.addListener(_onBedPriceChanged);
    _bedsController.addListener(_onBedsChanged);
  }

  void _onRoomPriceChanged() {
    if (_isUpdating) return;
    _isUpdating = true;

    final roomPrice = double.tryParse(_roomPriceController.text) ?? 0.0;
    final beds = double.tryParse(_bedsController.text) ?? 1.0;

    // Update Bed Price
    if (beds > 0) {
      final bedPrice = roomPrice / beds;
      _bedPriceController.text = bedPrice.toStringAsFixed(2);
    }

    _isUpdating = false;
  }

  void _onBedPriceChanged() {
    if (_isUpdating) return;
    _isUpdating = true;

    final bedPrice = double.tryParse(_bedPriceController.text) ?? 0.0;
    final beds = double.tryParse(_bedsController.text) ?? 1.0;

    // Update Room Price
    final roomPrice = bedPrice * beds;
    _roomPriceController.text = roomPrice.toStringAsFixed(2);

    _isUpdating = false;
  }

  void _onBedsChanged() {
    if (_isUpdating) return;
    _isUpdating = true;

    final bedPrice = double.tryParse(_bedPriceController.text) ?? 0.0;
    final beds = double.tryParse(_bedsController.text) ?? 1.0;

    final roomPrice = bedPrice * beds;
    _roomPriceController.text = roomPrice.toStringAsFixed(2);

    _isUpdating = false;
  }

  @override
  void dispose() {
    _bedsController.dispose();
    _roomPriceController.dispose();
    _bedPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'تعديل تفاصيل الغرفة',
        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _bedsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'عدد السراير',
                suffixIcon: const Icon(Icons.bed),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _roomPriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'سعر الغرفة بالكامل',
                suffixText: 'ج.م',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _bedPriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'سعر السرير الواحد',
                suffixText: 'ج.م',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                fillColor: Colors.orange.withOpacity(0.1),
                filled: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () {
            final beds = int.tryParse(_bedsController.text) ?? 0;
            final roomPrice = double.tryParse(_roomPriceController.text) ?? 0.0;
            final bedPrice = double.tryParse(_bedPriceController.text) ?? 0.0;

            final updatedRoom = Map<String, dynamic>.from(widget.currentRoom);
            updatedRoom['beds'] = beds;
            updatedRoom['price'] = roomPrice;
            updatedRoom['bedPrice'] = bedPrice;

            widget.onSave(updatedRoom);
            Navigator.pop(context);
          },
          child: Text(
            'حفظ التعديلات',
            style: GoogleFonts.cairo(
              color: const Color(0xFF39BB5E),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// --- Add Room Sheet ---
class _AddRoomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  const _AddRoomSheet({required this.onAdd});

  @override
  State<_AddRoomSheet> createState() => _AddRoomSheetState();
}

class _AddRoomSheetState extends State<_AddRoomSheet> {
  String _selectedType = 'Single';
  final _bedsController = TextEditingController();

  final List<String> _types = ['Single', 'Double', 'Triple', 'Custom'];

  @override
  void initState() {
    super.initState();
    // Default beds
    _updateBedsFromType();
  }

  void _updateBedsFromType() {
    if (_selectedType == 'Single')
      _bedsController.text = '1';
    else if (_selectedType == 'Double')
      _bedsController.text = '2';
    else if (_selectedType == 'Triple')
      _bedsController.text = '3';
    else
      _bedsController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'إضافة غرفة جديدة',
            style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Type Selector
          Text(
            'نوع الغرفة',
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: _types.map((type) {
              final isSelected = _selectedType == type;
              String label = type;
              if (type == 'Single') label = 'سنجل';
              if (type == 'Double') label = 'مزدوجة';
              if (type == 'Triple') label = 'ثلاثية';
              if (type == 'Custom') label = 'تخصيص عدد';

              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                selectedColor: const Color(0xFF39BB5E).withOpacity(0.2),
                labelStyle: GoogleFonts.cairo(
                  color: isSelected ? const Color(0xFF39BB5E) : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _selectedType = type;
                      _updateBedsFromType();
                    });
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          // Bed Count Input (Enabled if Custom, or ReadOnly if preset?)
          // User said "add number of rooms to it freely", suggesting edits allowed.
          // Let's allow editing always but prefill based on type.
          Text(
            'عدد السراير بالغرفة',
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bedsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'أدخل عدد السراير',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
            ),
          ),

          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39BB5E),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final beds = int.tryParse(_bedsController.text) ?? 0;
                if (beds <= 0) {
                  return; // show error?
                }

                widget.onAdd({
                  'type': _selectedType,
                  'beds': beds,
                  'createdAt': DateTime.now().toIso8601String(),
                });
              },
              child: Text(
                'إضافة',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 4. Audience & Payment Card ---
class _AudiencePaymentCard extends StatelessWidget {
  final ValueNotifier<String> genderNotifier;
  final ValueNotifier<List<String>> paymentMethodsNotifier;

  const _AudiencePaymentCard({
    required this.genderNotifier,
    required this.paymentMethodsNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      children: [
        _SectionLabel('الفئة المستهدفة ونظام الدفع 🎯'),
        const SizedBox(height: 15),
        ValueListenableBuilder<String>(
          valueListenable: genderNotifier,
          builder: (context, gender, child) {
            return Row(
              children: [
                Expanded(
                  child: _GradientSelectionCard(
                    title: 'شباب 👨',
                    isSelected: gender == 'male' || gender == 'both',
                    onTap: () {
                      if (gender == 'female') {
                        genderNotifier.value = 'both';
                      } else if (gender == 'both') {
                        genderNotifier.value = 'female';
                      } else {
                        genderNotifier.value = 'male';
                      }
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _GradientSelectionCard(
                    title: 'بنات 👩',
                    isSelected: gender == 'female' || gender == 'both',
                    onTap: () {
                      if (gender == 'male') {
                        genderNotifier.value = 'both';
                      } else if (gender == 'both') {
                        genderNotifier.value = 'male';
                      } else {
                        genderNotifier.value = 'female';
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        _SectionLabel('نظام الدفع', fontSize: 14),
        const SizedBox(height: 8),
        ValueListenableBuilder<List<String>>(
          valueListenable: paymentMethodsNotifier,
          builder: (context, selected, child) {
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _SelectableChip(
                  label: 'شهري',
                  value: 'monthly',
                  isSelected: selected.contains('monthly'),
                  onTap: () => _togglePayment('monthly', selected),
                ),
                _SelectableChip(
                  label: 'بالترم',
                  value: 'term',
                  isSelected: selected.contains('term'),
                  onTap: () => _togglePayment('term', selected),
                ),
                _SelectableChip(
                  label: 'سنوي',
                  value: 'year',
                  isSelected: selected.contains('year'),
                  onTap: () => _togglePayment('year', selected),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _togglePayment(String value, List<String> current) {
    final list = List<String>.from(current);
    if (list.contains(value)) {
      list.remove(value);
    } else {
      list.add(value);
    }
    paymentMethodsNotifier.value = list;
  }
}

// --- 5. Amenities & Rules Card ---
class _AmenitiesRulesCard extends StatelessWidget {
  final ValueNotifier<List<String>> amenitiesNotifier;
  final ValueNotifier<List<String>> rulesNotifier;
  final TextEditingController customAmenityController;
  final TextEditingController customRuleController;

  const _AmenitiesRulesCard({
    required this.amenitiesNotifier,
    required this.rulesNotifier,
    required this.customAmenityController,
    required this.customRuleController,
  });

  static const List<String> _suggestedAmenities = [
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

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      children: [
        _SectionLabel('المميزات والإضافات ✨'),
        const SizedBox(height: 10),
        // Suggested
        ValueListenableBuilder<List<String>>(
          valueListenable: amenitiesNotifier,
          builder: (context, amenities, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestedAmenities.map((amenity) {
                    final isSelected = amenities.contains(amenity);
                    return GestureDetector(
                      onTap: () {
                        final list = List<String>.from(amenities);
                        if (isSelected) {
                          list.remove(amenity);
                        } else {
                          list.add(amenity);
                        }
                        amenitiesNotifier.value = list;
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
                // Custom Added List (not in suggested)
                if (amenities.any((a) => !_suggestedAmenities.contains(a)))
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Wrap(
                      spacing: 8,
                      children: amenities
                          .where((a) => !_suggestedAmenities.contains(a))
                          .map((a) {
                            return Chip(
                              label: Text(a, style: GoogleFonts.cairo()),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                final list = List<String>.from(amenities);
                                list.remove(a);
                                amenitiesNotifier.value = list;
                              },
                              backgroundColor: Colors.white,
                              shape: StadiumBorder(
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ),
              ],
            );
          },
        ),
        // Dynamic Add
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: _DynamicAddField(
            controller: customAmenityController,
            hint: 'أضف مميزة أخرى...',
            onAdd: (val) {
              final list = List<String>.from(amenitiesNotifier.value);
              list.add(val);
              amenitiesNotifier.value = list;
            },
          ),
        ),
        const Divider(height: 30),
        _SectionLabel('القواعد والشروط ⚠️'),
        const SizedBox(height: 10),
        _DynamicAddField(
          controller: customRuleController,
          hint: 'أضف قاعدة جديدة (مثال: ممنوع التدخين)...',
          onAdd: (val) {
            final list = List<String>.from(rulesNotifier.value);
            list.add(val);
            rulesNotifier.value = list;
          },
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<List<String>>(
          valueListenable: rulesNotifier,
          builder: (context, rules, child) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rules.map((rule) {
                return Chip(
                  label: Text(rule, style: GoogleFonts.cairo()),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    final list = List<String>.from(rulesNotifier.value);
                    list.remove(rule);
                    rulesNotifier.value = list;
                  },
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  labelStyle: const TextStyle(color: Colors.orange),
                  deleteIconColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.orange),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

// =========================================================================
// ========================== HELPERS & SHARED =============================
// =========================================================================

class _SectionLabel extends StatelessWidget {
  final String text;
  final double fontSize;

  const _SectionLabel(this.text, {this.fontSize = 16});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
        color: const Color(0xFF008695),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final List<Widget> children;
  const _GlassCard({required this.children});

  @override
  Widget build(BuildContext context) {
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
}

class _CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;
  final IconData? icon;

  const _CustomTextField({
    required this.label,
    this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _SelectableChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableChip({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
}

class _GradientSelectionCard extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _GradientSelectionCard({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _DynamicAddField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Function(String) onAdd;

  const _DynamicAddField({
    required this.controller,
    required this.hint,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
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
