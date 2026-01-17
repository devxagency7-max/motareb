import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminReservationsScreen extends StatelessWidget {
  const AdminReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: Text(
          'الحجوزات',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
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
