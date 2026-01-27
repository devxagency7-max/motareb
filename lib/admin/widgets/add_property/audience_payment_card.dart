import 'package:flutter/material.dart';
import 'add_property_helpers.dart';

class AudiencePaymentCard extends StatelessWidget {
  final ValueNotifier<String> genderNotifier;
  final ValueNotifier<List<String>> paymentMethodsNotifier;

  const AudiencePaymentCard({
    super.key,
    required this.genderNotifier,
    required this.paymentMethodsNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      children: [
        const SectionLabel('الفئة المستهدفة ونظام الدفع 🎯'),
        const SizedBox(height: 15),
        ValueListenableBuilder<String>(
          valueListenable: genderNotifier,
          builder: (context, gender, child) {
            return Row(
              children: [
                Expanded(
                  child: GradientSelectionCard(
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
                  child: GradientSelectionCard(
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
        const SectionLabel('نظام الدفع', fontSize: 14),
        const SizedBox(height: 8),
        ValueListenableBuilder<List<String>>(
          valueListenable: paymentMethodsNotifier,
          builder: (context, selected, child) {
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SelectableChip(
                  label: 'شهري',
                  value: 'monthly',
                  isSelected: selected.contains('monthly'),
                  onTap: () => _togglePayment('monthly', selected),
                ),
                SelectableChip(
                  label: 'بالترم',
                  value: 'term',
                  isSelected: selected.contains('term'),
                  onTap: () => _togglePayment('term', selected),
                ),
                SelectableChip(
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
