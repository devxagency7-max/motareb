import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_motareb/utils/custom_snackbar.dart';
import 'add_property_helpers.dart';

class UniversitiesSelectorSection extends StatelessWidget {
  final ValueNotifier<List<String>> selectedUniversitiesNotifier;
  final TextEditingController customUniversityController;

  const UniversitiesSelectorSection({
    super.key,
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
            final allUniversities = {
              ...globalUniversities,
              ...selected,
            }.toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('الجامعات المجاورة 🎓', fontSize: 14),
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
                      return SelectableChip(
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
                DynamicAddField(
                  controller: customUniversityController,
                  hint: 'أضف جامعة جديدة (خاصة بهذا العقار)...',
                  onAdd: (val) {
                    final trimmedVal = val.trim();
                    if (trimmedVal.isNotEmpty) {
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
