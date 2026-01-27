import 'package:flutter/material.dart';
import 'add_property_helpers.dart';

class DescriptionCard extends StatelessWidget {
  final TextEditingController descriptionController;
  final TextEditingController descriptionEnController;

  const DescriptionCard({
    super.key,
    required this.descriptionController,
    required this.descriptionEnController,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      children: [
        const SectionLabel('وصف المكان 📝'),
        const SizedBox(height: 15),
        CustomTextField(
          label: 'وصف كامل للعقار (بالعربي) *',
          hint: 'اكتب كل التفاصيل اللي تميز مكانك...',
          controller: descriptionController,
          maxLines: 4,
        ),
        const SizedBox(height: 15),
        CustomTextField(
          label: 'Full Property Description (English)',
          hint: 'Write all details that characterize your place...',
          controller: descriptionEnController,
          maxLines: 4,
          textDirection: TextDirection.ltr,
        ),
      ],
    );
  }
}
