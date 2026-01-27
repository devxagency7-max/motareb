import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_property_helpers.dart';
import 'universities_selector_section.dart';
import '../../services/translation_service.dart';

class MainInfoCard extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController titleEnController;
  final TextEditingController priceController;
  final TextEditingController discountPriceController;
  final TextEditingController locationController;
  final TextEditingController locationEnController;
  final TextEditingController featuredLabelController;
  final TextEditingController featuredLabelEnController;
  final ValueNotifier<String> governorateNotifier;
  final ValueNotifier<List<Map<String, dynamic>>> universitiesNotifier;
  final TextEditingController customUniversityController;
  final TextEditingController customUniversityEnController;

  const MainInfoCard({
    super.key,
    required this.titleController,
    required this.titleEnController,
    required this.priceController,
    required this.discountPriceController,
    required this.locationController,
    required this.locationEnController,
    required this.featuredLabelController,
    required this.featuredLabelEnController,
    required this.governorateNotifier,
    required this.universitiesNotifier,
    required this.customUniversityController,
    required this.customUniversityEnController,
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
    return GlassCard(
      children: [
        const SectionLabel('بيانات العقار الأساسية 🏠'),
        const SizedBox(height: 15),
        CustomTextField(
          label: 'عنوان الإعلان المميز (بالعربي) *',
          hint: 'مثال: ستوديو فاخر بجوار الجامعة',
          controller: titleController,
          icon: Icons.title,
          maxLines: null,
          minLines: 1,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          label: 'Property Title (English)',
          hint: 'e.g. Luxury Studio near University',
          controller: titleEnController,
          icon: Icons.title,
          textDirection: TextDirection.ltr,
          maxLines: null,
          minLines: 1,
          suffix: IconButton(
            icon: const Icon(Icons.translate, color: Color(0xFF39BB5E)),
            onPressed: () async {
              final text = titleController.text.trim();
              if (text.isNotEmpty) {
                final translation = await TranslationService().translate(text);
                if (translation != null) {
                  titleEnController.text = translation;
                }
              }
            },
          ),
        ),
        const SizedBox(height: 15),
        CustomTextField(
          label: 'السعر (ج.م) (الزامي) *',
          hint: '0.0',
          controller: priceController,
          keyboardType: TextInputType.number,
          icon: Icons.monetization_on_outlined,
        ),
        const SizedBox(height: 15),
        CustomTextField(
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
                labelStyle: GoogleFonts.cairo(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E2329)
                    : Colors.grey.shade50,
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
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2F3640)
                        : Colors.grey.shade200,
                  ),
                ),
              ),
              dropdownColor: Theme.of(context).cardTheme.color,
              items: _governorates.map((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(
                    val,
                    style: GoogleFonts.cairo(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) governorateNotifier.value = val;
              },
            );
          },
        ),
        const SizedBox(height: 15),
        CustomTextField(
          label: 'الموقع التفصيلي (بالعربي)',
          hint: 'الشارع، الحي، علامة مميزة...',
          controller: locationController,
          icon: Icons.location_on_outlined,
          maxLines: null,
          minLines: 2,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          label: 'Detailed Location (English)',
          hint: 'Street, District, Landmark...',
          controller: locationEnController,
          icon: Icons.location_on_outlined,
          maxLines: null,
          minLines: 2,
          textDirection: TextDirection.ltr,
          suffix: IconButton(
            icon: const Icon(Icons.translate, color: Color(0xFF39BB5E)),
            onPressed: () async {
              final text = locationController.text.trim();
              if (text.isNotEmpty) {
                final translation = await TranslationService().translate(text);
                if (translation != null) {
                  locationEnController.text = translation;
                }
              }
            },
          ),
        ),
        const SizedBox(height: 15),
        UniversitiesSelectorSection(
          selectedUniversitiesNotifier: universitiesNotifier,
          customUniversityController: customUniversityController,
          customUniversityEnController: customUniversityEnController,
        ),
        const SizedBox(height: 15),
        CustomTextField(
          label: 'كلمة مميزة - بادج (بالعربي)',
          hint: 'مثال: خصم خاص، فرصة، قريب جداً',
          controller: featuredLabelController,
          icon: Icons.stars_rounded,
          maxLines: null,
          minLines: 1,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          label: 'Featured Label (English)',
          hint: 'e.g. Special Offer, Close to Uni',
          controller: featuredLabelEnController,
          icon: Icons.stars_rounded,
          textDirection: TextDirection.ltr,
          maxLines: null,
          minLines: 1,
        ),
      ],
    );
  }
}
