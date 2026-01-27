import 'package:flutter/material.dart';
import 'package:admin_motareb/core/utils/loc_extension.dart';
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
        SectionLabel(context.loc.audienceAndPayment),
        const SizedBox(height: 15),
        ValueListenableBuilder<String>(
          valueListenable: genderNotifier,
          builder: (context, gender, child) {
            return Row(
              children: [
                Expanded(
                  child: GradientSelectionCard(
                    title: context.loc.males,
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
                    title: context.loc.females,
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
        SectionLabel(context.loc.paymentSystem, fontSize: 14),
        const SizedBox(height: 8),
        ValueListenableBuilder<List<String>>(
          valueListenable: paymentMethodsNotifier,
          builder: (context, selected, child) {
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SelectableChip(
                  label: context.loc.monthly,
                  value: 'monthly',
                  isSelected: selected.contains('monthly'),
                  onTap: () => _togglePayment('monthly', selected),
                ),
                SelectableChip(
                  label: context.loc.termly,
                  value: 'term',
                  isSelected: selected.contains('term'),
                  onTap: () => _togglePayment('term', selected),
                ),
                SelectableChip(
                  label: context.loc.yearly,
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
