import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  final double fontSize;

  const SectionLabel(this.text, {super.key, this.fontSize = 16});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
        color: const Color(0xFF008695),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final List<Widget> children;
  const GlassCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int? maxLines;
  final int? minLines;
  final IconData? icon;
  final Function(String)? onChanged;
  final TextDirection? textDirection;
  final Widget? suffix;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines,
    this.icon,
    this.onChanged,
    this.textDirection,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onChanged: onChanged,
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      textDirection: textDirection,
      style: GoogleFonts.cairo(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
        labelStyle: GoogleFonts.cairo(color: Colors.grey.shade600),
        prefixIcon: icon != null
            ? Icon(icon, color: const Color(0xFF008695), size: 20)
            : null,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.grey.shade50,
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
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF39BB5E), width: 1.5),
        ),
      ),
    );
  }
}

class SelectableChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectableChip({
    super.key,
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: isSelected
            ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF008695).withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              )
            : BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300),
              ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class GradientSelectionCard extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const GradientSelectionCard({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: isSelected
            ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF008695).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              )
            : BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200, width: 2),
              ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

class DynamicAddField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Function(String) onAdd;

  const DynamicAddField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: GoogleFonts.cairo(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 10,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (val) {
              if (val.trim().isNotEmpty) {
                onAdd(val.trim());
                controller.clear();
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              onAdd(controller.text.trim());
              controller.clear();
            }
          },
          icon: const Icon(
            Icons.add_circle,
            color: Color(0xFF008695),
            size: 30,
          ),
        ),
      ],
    );
  }
}

class BilingualAddField extends StatelessWidget {
  final TextEditingController arController;
  final TextEditingController enController;
  final String arHint;
  final String enHint;
  final Function(String ar, String en) onAdd;

  const BilingualAddField({
    super.key,
    required this.arController,
    required this.enController,
    required this.arHint,
    required this.enHint,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  TextField(
                    controller: arController,
                    style: GoogleFonts.cairo(fontSize: 14),
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: arHint,
                      hintStyle: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: enController,
                    style: GoogleFonts.cairo(fontSize: 14),
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      hintText: enHint,
                      hintStyle: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                if (arController.text.trim().isNotEmpty &&
                    enController.text.trim().isNotEmpty) {
                  onAdd(arController.text.trim(), enController.text.trim());
                  arController.clear();
                  enController.clear();
                }
              },
              icon: const Icon(
                Icons.add_circle,
                color: Color(0xFF008695),
                size: 35,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
