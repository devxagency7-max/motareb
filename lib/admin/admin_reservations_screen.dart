import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminReservationsScreen extends StatelessWidget {
  const AdminReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'الحجوزات',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
      ),
      body: Center(
        child: Text(
          'قائمة الحجوزات (قريباً)',
          style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}
