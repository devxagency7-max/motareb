import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_property_helpers.dart';

class AmenitiesRulesCard extends StatelessWidget {
  final ValueNotifier<List<String>> amenitiesNotifier;
  final ValueNotifier<List<String>> rulesNotifier;
  final TextEditingController customAmenityController;
  final TextEditingController customRuleController;

  const AmenitiesRulesCard({
    super.key,
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
    return GlassCard(
      children: [
        const SectionLabel('المميزات والإضافات ✨'),
        const SizedBox(height: 10),
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
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: DynamicAddField(
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
        const SectionLabel('القواعد والشروط ⚠️'),
        const SizedBox(height: 10),
        DynamicAddField(
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
