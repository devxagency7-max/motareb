import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_motareb/core/utils/loc_extension.dart';
import 'add_property_helpers.dart';

class UniversitiesSelectorSection extends StatelessWidget {
  final ValueNotifier<List<Map<String, dynamic>>> selectedUniversitiesNotifier;
  const UniversitiesSelectorSection({
    super.key,
    required this.selectedUniversitiesNotifier,
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
        final globalUniversities = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'ar': data['name'] ?? '',
            'en': data['nameEn'] ?? data['name'] ?? '',
          };
        }).toList();

        return ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: selectedUniversitiesNotifier,
          builder: (context, selected, child) {
            // Merge global and selected (by Arabic name to avoid duplicates if possible)
            final allUniversities = List<Map<String, dynamic>>.from(
              globalUniversities,
            );
            for (var sel in selected) {
              if (!allUniversities.any((uni) => uni['ar'] == sel['ar'])) {
                allUniversities.add(sel);
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(context.loc.nearbyUniversities, fontSize: 14),
                const SizedBox(height: 10),
                if (allUniversities.isEmpty)
                  Text(
                    context
                        .loc
                        .noRoomsAdded, // Reusing noRoomsAdded for simplicity if applicable, or add specific key
                    style: GoogleFonts.cairo(color: Colors.grey),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allUniversities.map((uni) {
                      final isSelected = selected.any(
                        (s) => s['ar'] == uni['ar'],
                      );
                      return SelectableChip(
                        label: "${uni['ar']} | ${uni['en']}",
                        value: uni['ar'],
                        isSelected: isSelected,
                        onTap: () {
                          final list = List<Map<String, dynamic>>.from(
                            selected,
                          );
                          if (isSelected) {
                            list.removeWhere((s) => s['ar'] == uni['ar']);
                          } else {
                            list.add(uni);
                          }
                          selectedUniversitiesNotifier.value = list;
                        },
                      );
                    }).toList(),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
