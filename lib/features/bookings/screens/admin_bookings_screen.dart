import 'package:admin_motareb/core/theme/admin_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';

import '../models/booking_model.dart';
import 'admin_booking_details_screen.dart';

class AdminBookingsScreen extends StatelessWidget {
  const AdminBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Bookings Management",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No bookings found"));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final booking = BookingModel.fromFirestore(docs[index]);
              return FadeInUp(
                delay: Duration(milliseconds: index * 50),
                child: _BookingCard(booking: booking),
              );
            },
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    // Dynamic status text & color
    Color statusColor = Colors.grey;
    String statusText = booking.status.toUpperCase();

    if (booking.isFullyPaid) {
      statusColor = AdminTheme.brandPrimary;
      statusText = "COMPLETED";
    } else if (booking.isDepositPaid) {
      statusColor = Colors.orange;
      statusText = "DEPOSIT PAID";
    } else if (booking.status == 'pending') {
      statusColor = Colors.blueGrey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminBookingDetailsScreen(booking: booking),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: ID and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('yyyy/MM/dd HH:mm').format(booking.createdAt),
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Property (Using StreamBuilder to fetch title)
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('properties')
                    .doc(booking.propertyId)
                    .get(),
                builder: (context, snapshot) {
                  String propertyTitle = "Loading Property...";
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    propertyTitle = data['title'] ?? "Unknown Property";
                  } else if (snapshot.connectionState == ConnectionState.done) {
                    propertyTitle = "Property Not Found";
                  }

                  return Text(
                    propertyTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),

              // User Info
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${booking.firstName ?? 'Unknown'} ${booking.lastName ?? ''}",
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  // Price
                  Text(
                    "${NumberFormat('#,###').format(booking.totalAmount)} EGP",
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.brandSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // 2 Stages Visual Indicator
              Row(
                children: [
                  _StageIndicator(
                    label: "Deposit",
                    isCompleted: booking.isDepositPaid,
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: booking.isDepositPaid
                          ? Colors.green
                          : Colors.grey[300],
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                  _StageIndicator(
                    label: "Remaining",
                    isCompleted: booking.isFullyPaid,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageIndicator extends StatelessWidget {
  final String label;
  final bool isCompleted;

  const _StageIndicator({required this.label, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isCompleted ? Colors.green : Colors.grey,
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: isCompleted ? Colors.green : Colors.grey,
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
