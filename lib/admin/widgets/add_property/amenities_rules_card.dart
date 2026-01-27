import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_motareb/core/utils/loc_extension.dart';
import 'add_property_helpers.dart';

class AmenitiesRulesCard extends StatelessWidget {
  final ValueNotifier<List<Map<String, dynamic>>> amenitiesNotifier;
  final ValueNotifier<List<Map<String, dynamic>>> rulesNotifier;
  final TextEditingController customAmenityController;
  final TextEditingController customAmenityEnController;
  final TextEditingController customRuleController;
  final TextEditingController customRuleEnController;

  const AmenitiesRulesCard({
    super.key,
    required this.amenitiesNotifier,
    required this.rulesNotifier,
    required this.customAmenityController,
    required this.customAmenityEnController,
    required this.customRuleController,
    required this.customRuleEnController,
  });

  static const List<Map<String, String>> _suggestedAmenities = [
    {'ar': 'واي فاي', 'en': 'Wi-Fi'},
    {'ar': 'تكييف', 'en': 'Air Conditioning'},
    {'ar': 'بلكونة', 'en': 'Balcony'},
    {'ar': 'مطبخ', 'en': 'Kitchen'},
    {'ar': 'مفروش', 'en': 'Furnished'},
    {'ar': 'أسانسير', 'en': 'Elevator'},
    {'ar': 'أمن', 'en': 'Security'},
    {'ar': 'جراج', 'en': 'Garage'},
    {'ar': 'قريب من المواصلات', 'en': 'Near Transport'},
  ];

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      children: [
        SectionLabel(context.loc.amenitiesAndExtras),
        const SizedBox(height: 10),
        ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: amenitiesNotifier,
          builder: (context, amenities, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestedAmenities.map((suggested) {
                    final isSelected = amenities.any(
                      (a) => a['ar'] == suggested['ar'],
                    );
                    return GestureDetector(
                      onTap: () {
                        final list = List<Map<String, dynamic>>.from(amenities);
                        if (isSelected) {
                          list.removeWhere((a) => a['ar'] == suggested['ar']);
                        } else {
                          list.add(suggested);
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
                          suggested['ar']!,
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
                if (amenities.any(
                  (a) => !_suggestedAmenities.any((s) => s['ar'] == a['ar']),
                ))
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: amenities
                          .where(
                            (a) => !_suggestedAmenities.any(
                              (s) => s['ar'] == a['ar'],
                            ),
                          )
                          .map((a) {
                            return Chip(
                              label: Text(
                                '${a['ar']} | ${a['en']}',
                                style: GoogleFonts.cairo(fontSize: 11),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                final list = List<Map<String, dynamic>>.from(
                                  amenities,
                                );
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
          padding: const EdgeInsets.only(top: 20),
          child: BilingualAddField(
            arController: customAmenityController,
            enController: customAmenityEnController,
            arHint: 'اسم الميزة بالعربي',
            enHint: 'Amenity name in English',
            onAdd: (ar, en) {
              final list = List<Map<String, dynamic>>.from(
                amenitiesNotifier.value,
              );
              list.add({'ar': ar, 'en': en});
              amenitiesNotifier.value = list;
            },
          ),
        ),
        const Divider(height: 40),
        SectionLabel(context.loc.rulesAndConditions),
        const SizedBox(height: 10),
        BilingualAddField(
          arController: customRuleController,
          enController: customRuleEnController,
          arHint: 'القاعدة بالعربي (مثال: ممنوع التدخين)',
          enHint: 'Rule in English (e.g. No smoking)',
          onAdd: (ar, en) {
            final list = List<Map<String, dynamic>>.from(rulesNotifier.value);
            list.add({'ar': ar, 'en': en});
            rulesNotifier.value = list;
          },
        ),
        const SizedBox(height: 15),
        ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: rulesNotifier,
          builder: (context, rules, child) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rules.map((rule) {
                return Chip(
                  label: Text(
                    '${rule['ar']} | ${rule['en']}',
                    style: GoogleFonts.cairo(fontSize: 11),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    final list = List<Map<String, dynamic>>.from(
                      rulesNotifier.value,
                    );
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
