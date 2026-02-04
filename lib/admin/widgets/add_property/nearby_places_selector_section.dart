import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_property_helpers.dart';

class NearbyPlacesSelectorSection extends StatelessWidget {
  final ValueNotifier<List<Map<String, dynamic>>> selectedPlacesNotifier;
  final TextEditingController customPlaceController;
  final TextEditingController customPlaceEnController;

  const NearbyPlacesSelectorSection({
    super.key,
    required this.selectedPlacesNotifier,
    required this.customPlaceController,
    required this.customPlaceEnController,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: selectedPlacesNotifier,
      builder: (context, selected, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('الأماكن المجاورة', fontSize: 14),
            const SizedBox(height: 10),
            if (selected.isEmpty)
              Text(
                'لم يتم إضافة أماكن مجاورة بعد',
                style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selected.map((place) {
                  return Chip(
                    label: Text(
                      "${place['ar']} | ${place['en']}",
                      style: GoogleFonts.cairo(fontSize: 11),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      final list = List<Map<String, dynamic>>.from(selected);
                      list.remove(place);
                      selectedPlacesNotifier.value = list;
                    },
                    backgroundColor: Colors.white,
                    shape: StadiumBorder(
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 15),
            BilingualAddField(
              arController: customPlaceController,
              enController: customPlaceEnController,
              arHint: 'اسم المكان بالعربي (مثال: محطة القطار)',
              enHint: 'Place name in English',
              onAdd: (ar, en) {
                final trimmedAr = ar.trim();
                final trimmedEn = en.trim().isEmpty ? ar.trim() : en.trim();

                if (trimmedAr.isNotEmpty) {
                  final list = List<Map<String, dynamic>>.from(selected);
                  if (!list.any((p) => p['ar'] == trimmedAr)) {
                    list.add({'ar': trimmedAr, 'en': trimmedEn});
                    selectedPlacesNotifier.value = list;
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
