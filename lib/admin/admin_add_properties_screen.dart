import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:admin_motareb/utils/custom_snackbar.dart';
import 'package:admin_motareb/core/models/property_model.dart';
import 'package:admin_motareb/core/utils/loc_extension.dart';

// Import refactored widgets
import 'widgets/add_property/images_picker_section.dart';
import 'widgets/add_property/main_info_card.dart';
import 'widgets/add_property/available_units_card.dart';
import 'widgets/add_property/description_card.dart';
import 'widgets/add_property/audience_payment_card.dart';
import 'widgets/add_property/amenities_rules_card.dart';

class AdminAddPropertyScreen extends StatefulWidget {
  final Property? propertyToEdit;

  const AdminAddPropertyScreen({super.key, this.propertyToEdit});

  @override
  State<AdminAddPropertyScreen> createState() => _AdminAddPropertyScreenState();
}

class _AdminAddPropertyScreenState extends State<AdminAddPropertyScreen> {
  // --- Controllers ---
  final _adminNumberController = TextEditingController();
  final _titleController = TextEditingController();
  final _titleEnController = TextEditingController(); // NEW
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _depositController = TextEditingController(); // NEW
  final _locationController = TextEditingController();
  final _locationEnController = TextEditingController(); // NEW
  final _descriptionController = TextEditingController();
  final _descriptionEnController = TextEditingController(); // NEW
  final _bathroomsController = TextEditingController(text: '1');
  final ValueNotifier<List<Map<String, dynamic>>> _roomsNotifier =
      ValueNotifier([]);

  final _customRuleController = TextEditingController();
  final _customRuleEnController = TextEditingController();
  final _customAmenityController = TextEditingController();
  final _customAmenityEnController = TextEditingController();
  final _customUniversityController = TextEditingController();
  final _customUniversityEnController = TextEditingController();
  final _customNearbyPlaceController = TextEditingController(); // NEW
  final _customNearbyPlaceEnController = TextEditingController(); // NEW

  // --- Booking Modes State ---
  final ValueNotifier<String> _bookingModeNotifier = ValueNotifier('unit');
  final ValueNotifier<bool> _isFullApartmentNotifier = ValueNotifier(false);
  final _totalBedsController = TextEditingController();
  final _apartmentRoomsCountController = TextEditingController();
  final _roomTypeController = TextEditingController();
  final _bedPriceController = TextEditingController();

  // --- State Management (ValueNotifiers) ---
  final ValueNotifier<List<String>> _imagesNotifier = ValueNotifier([]);
  final ValueNotifier<String?> _videoUrlNotifier = ValueNotifier(null);

  final ValueNotifier<String?> _idErrorNotifier = ValueNotifier(null);
  final ValueNotifier<bool> _isCheckingIdNotifier = ValueNotifier(false);

  final ValueNotifier<List<Map<String, dynamic>>> _amenitiesNotifier =
      ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> _rulesNotifier =
      ValueNotifier([]);

  final ValueNotifier<List<String>> _selectedUnitTypesNotifier = ValueNotifier(
    [],
  );
  final ValueNotifier<String> _selectedGenderNotifier = ValueNotifier('male');
  final ValueNotifier<List<String>> _paymentMethodsNotifier = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>>
  _selectedUniversitiesNotifier = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>>
  _selectedNearbyPlacesNotifier = ValueNotifier([]); // NEW
  final ValueNotifier<String> _selectedGovernorateNotifier = ValueNotifier(
    'بني سويف',
  );

  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _bookingEnabledNotifier = ValueNotifier(true);

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

      if (!mounted) return;

      if (doc.exists) {
        _idErrorNotifier.value = 'لا يمكن الاستخدام ⛔';
      } else {
        _idErrorNotifier.value = null;
      }
    } catch (e) {
      if (mounted) _idErrorNotifier.value = null;
    } finally {
      if (mounted) _isCheckingIdNotifier.value = false;
    }
  }

  void _preFillData() {
    final p = widget.propertyToEdit!;

    final idMatch = RegExp(r'T(\d+)Z').firstMatch(p.id);
    if (idMatch != null) {
      _adminNumberController.text = idMatch.group(1) ?? '';
    } else {
      _adminNumberController.text = p.id;
    }

    _titleController.text = p.title;
    _titleEnController.text = p.titleEn;
    _priceController.text = p.price.toString();
    _discountPriceController.text = p.discountPrice?.toString() ?? '';
    _depositController.text = p.requiredDeposit?.toString() ?? '';
    _locationController.text = p.location;
    _locationEnController.text = p.locationEn;
    _descriptionController.text = p.description ?? '';
    _descriptionEnController.text = p.descriptionEn ?? '';
    _bathroomsController.text = p.bathroomsCount.toString();

    if (p.rooms.isNotEmpty) {
      _roomsNotifier.value = List.from(p.rooms);
    }

    _imagesNotifier.value = List<String>.from(p.images);
    _videoUrlNotifier.value = p.videoUrl;

    _amenitiesNotifier.value = p.amenities.map<Map<String, dynamic>>((e) {
      if (e is Map) return Map<String, dynamic>.from(e);
      return {'ar': e.toString(), 'en': e.toString()};
    }).toList();
    _rulesNotifier.value = p.rules.map<Map<String, dynamic>>((e) {
      if (e is Map) return Map<String, dynamic>.from(e);
      return {'ar': e.toString(), 'en': e.toString()};
    }).toList();

    _selectedGenderNotifier.value = p.gender ?? 'male';
    _selectedGovernorateNotifier.value = p.governorate ?? 'بني سويف';
    _paymentMethodsNotifier.value = List.from(p.paymentMethods);
    _selectedUniversitiesNotifier.value = p.universities
        .map<Map<String, dynamic>>((e) {
          if (e is Map) return Map<String, dynamic>.from(e);
          return {'ar': e.toString(), 'en': e.toString()};
        })
        .toList();

    _selectedNearbyPlacesNotifier.value = p.nearbyPlaces
        .map<Map<String, dynamic>>((e) {
          if (e is Map) return Map<String, dynamic>.from(e);
          return {'ar': e.toString(), 'en': e.toString()};
        })
        .toList();

    List<String> types = [];
    if (p.unitTypes.isNotEmpty) {
      types = List.from(p.unitTypes);
    } else {
      if (p.isBed) types.add('bed');
      if (p.isRoom) types.add('room');
    }
    _selectedUnitTypesNotifier.value = types;

    _bookingModeNotifier.value = p.bookingMode;
    _isFullApartmentNotifier.value = p.isFullApartmentBooking;
    _totalBedsController.text = p.totalBeds > 0 ? p.totalBeds.toString() : '';
    _bedPriceController.text = p.bedPrice > 0 ? p.bedPrice.toString() : '';
    _apartmentRoomsCountController.text = p.apartmentRoomsCount > 0
        ? p.apartmentRoomsCount.toString()
        : '';
    _roomTypeController.text = p.generalRoomType ?? '';
    _bedPriceController.text = p.bedPrice > 0 ? p.bedPrice.toString() : '';
    _bookingEnabledNotifier.value = p.bookingEnabled;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _adminNumberController.removeListener(_onIdChanged);
    _adminNumberController.dispose();
    _titleController.dispose();
    _titleEnController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _depositController.dispose();
    _locationController.dispose();
    _locationEnController.dispose();
    _descriptionController.dispose();
    _descriptionEnController.dispose();
    _bathroomsController.dispose();
    _roomsNotifier.dispose();
    _customRuleController.dispose();
    _customRuleEnController.dispose();
    _customAmenityController.dispose();
    _customAmenityEnController.dispose();
    _customUniversityController.dispose();
    _customUniversityEnController.dispose();
    _customNearbyPlaceController.dispose();
    _customNearbyPlaceEnController.dispose();
    _bookingModeNotifier.dispose();
    _isFullApartmentNotifier.dispose();
    _totalBedsController.dispose();
    _bedPriceController.dispose();
    _apartmentRoomsCountController.dispose();
    _roomTypeController.dispose();

    _imagesNotifier.dispose();
    _videoUrlNotifier.dispose();
    _amenitiesNotifier.dispose();
    _rulesNotifier.dispose();
    _selectedUnitTypesNotifier.dispose();
    _selectedGenderNotifier.dispose();
    _paymentMethodsNotifier.dispose();
    _selectedUniversitiesNotifier.dispose();
    _selectedNearbyPlacesNotifier.dispose();
    _selectedGovernorateNotifier.dispose();
    _isLoadingNotifier.dispose();
    _bookingEnabledNotifier.dispose();
    super.dispose();
  }

  Future<void> _submitProperty() async {
    if (_adminNumberController.text.trim().isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: 'يجب إدخال رقم العقار أولاً ❗',
        isError: true,
      );
      return;
    }
    if (widget.propertyToEdit == null && _idErrorNotifier.value != null) {
      CustomSnackBar.show(
        context: context,
        message: 'رقم العقار غير متاح: ${_idErrorNotifier.value}',
        isError: true,
      );
      return;
    }

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

      final propertyData = {
        'id': finalPropertyId,
        'propertyId': finalPropertyId,
        'adminNumber': int.tryParse(adminNumberStr) ?? 0,
        'ownerId': uid,
        'title': _titleController.text.trim(),
        'titleEn': _titleEnController.text.trim().isEmpty
            ? _titleController.text.trim()
            : _titleEnController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'discountPrice': _discountPriceController.text.trim().isNotEmpty
            ? double.tryParse(_discountPriceController.text.trim())
            : null,
        'requiredDeposit': _depositController.text.trim().isNotEmpty
            ? double.tryParse(_depositController.text.trim())
            : null,
        'location': _locationController.text.trim().isEmpty
            ? 'غير محدد'
            : _locationController.text.trim(),
        'locationEn': _locationEnController.text.trim().isEmpty
            ? _locationController.text.trim()
            : _locationEnController.text.trim(),
        'governorate': _selectedGovernorateNotifier.value,
        'description': _descriptionController.text.trim(),
        'descriptionEn': _descriptionEnController.text.trim().isEmpty
            ? _descriptionController.text.trim()
            : _descriptionEnController.text.trim(),
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
        'nearbyPlaces': _selectedNearbyPlacesNotifier.value,
        'bedsCount': _roomsNotifier.value.fold<int>(
          0,
          (total, room) => total + (room['beds'] as int? ?? 0),
        ),
        'roomsCount': _roomsNotifier.value.length,
        'singleRoomsCount': 0,
        'doubleRoomsCount': 0,
        'singleBedsCount': 0,
        'doubleBedsCount': 0,
        'bathroomsCount': int.tryParse(_bathroomsController.text.trim()) ?? 1,
        'rooms': _roomsNotifier.value,
        'bookingMode': _bookingModeNotifier.value,
        'isFullApartmentBooking': _isFullApartmentNotifier.value,
        'totalBeds': int.tryParse(_totalBedsController.text.trim()) ?? 0,
        'apartmentRoomsCount':
            int.tryParse(_apartmentRoomsCountController.text.trim()) ?? 0,
        'bedPrice': (_bookingModeNotifier.value == 'bed')
            ? (double.tryParse(_discountPriceController.text.trim()) ??
                  double.tryParse(_priceController.text.trim()) ??
                  0.0)
            : 0.0,
        'generalRoomType': _roomTypeController.text.trim(),
        'bookingEnabled': _bookingEnabledNotifier.value,
      };

      if (widget.propertyToEdit != null) {
        await FirebaseFirestore.instance
            .collection('properties')
            .doc(widget.propertyToEdit!.id)
            .update(propertyData);
      } else {
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.propertyToEdit != null
              ? 'تعديل بيانات العقار'
              : context.loc.addProperty,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).appBarTheme.iconTheme?.color,
          ),
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
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: Theme.of(context).brightness == Brightness.dark
                      ? []
                      : [
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
                            readOnly: widget.propertyToEdit != null,
                            style: TextStyle(
                              color: widget.propertyToEdit != null
                                  ? Colors.grey
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
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
                                  ? Theme.of(
                                      context,
                                    ).dividerColor.withOpacity(0.1)
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
                    ValueListenableBuilder<String?>(
                      valueListenable: _idErrorNotifier,
                      builder: (context, error, _) {
                        return ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _adminNumberController,
                          builder: (context, val, _) {
                            if (val.text.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            final previewId = 'T${val.text}Z';
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
              ImagesPickerSection(
                imagesNotifier: _imagesNotifier,
                videoNotifier: _videoUrlNotifier,
                picker: _picker,
                adminNumberController: _adminNumberController,
                idErrorNotifier: _idErrorNotifier,
              ),
              const SizedBox(height: 25),

              // --- Main Info Card ---
              MainInfoCard(
                titleController: _titleController,
                titleEnController: _titleEnController,
                priceController: _priceController,
                discountPriceController: _discountPriceController,
                locationController: _locationController,
                locationEnController: _locationEnController,
                governorateNotifier: _selectedGovernorateNotifier,
                universitiesNotifier: _selectedUniversitiesNotifier,
                nearbyPlacesNotifier: _selectedNearbyPlacesNotifier, // NEW
                customNearbyPlaceController:
                    _customNearbyPlaceController, // NEW
                customNearbyPlaceEnController:
                    _customNearbyPlaceEnController, // NEW
                depositController: _depositController,
                bookingEnabledNotifier: _bookingEnabledNotifier,
              ),
              const SizedBox(height: 20),

              // --- Available Units Card ---
              AvailableUnitsCard(
                roomsNotifier: _roomsNotifier,
                bathroomsController: _bathroomsController,
                priceController: _priceController,
                discountPriceController: _discountPriceController,
                bookingModeNotifier: _bookingModeNotifier,
                isFullApartmentNotifier: _isFullApartmentNotifier,
                totalBedsController: _totalBedsController,
                bedPriceController: _bedPriceController,
                apartmentRoomsCountController: _apartmentRoomsCountController,
                roomTypeController: _roomTypeController,
              ),
              const SizedBox(height: 20),

              // --- Description Card ---
              DescriptionCard(
                descriptionController: _descriptionController,
                descriptionEnController: _descriptionEnController,
              ),
              const SizedBox(height: 20),

              // --- Audience & Payment Card ---
              AudiencePaymentCard(
                genderNotifier: _selectedGenderNotifier,
                paymentMethodsNotifier: _paymentMethodsNotifier,
              ),
              const SizedBox(height: 20),

              // --- Amenities & Rules Card ---
              AmenitiesRulesCard(
                amenitiesNotifier: _amenitiesNotifier,
                rulesNotifier: _rulesNotifier,
                customAmenityController: _customAmenityController,
                customAmenityEnController: _customAmenityEnController,
                customRuleController: _customRuleController,
                customRuleEnController: _customRuleEnController,
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
                                        : context.loc.save,
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
