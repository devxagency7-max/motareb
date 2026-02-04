import 'package:admin_motareb/core/theme/admin_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/booking_model.dart';

class AdminBookingDetailsScreen extends StatelessWidget {
  final BookingModel booking;

  const AdminBookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Booking Details",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. Property Header Card
            _buildPropertyHeader(),
            const SizedBox(height: 20),

            // 2. Status & Timeline
            _buildStatusCard(),
            const SizedBox(height: 20),

            // 3. User Info
            _buildUserCard(context),
            const SizedBox(height: 20),

            // 4. Payment Details
            _buildPaymentInfoCard(),
            const SizedBox(height: 20),

            // 5. Metadata/Selections
            if (booking.metadata.containsKey('selections'))
              _buildSelectionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyHeader() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('properties')
          .doc(booking.propertyId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final title = data?['title'] ?? 'Unknown Property';
        final image =
            (data != null &&
                data['images'] != null &&
                (data['images'] as List).isNotEmpty)
            ? (data['images'] as List)[0]
            : null;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (image != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    image,
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey[200], height: 150),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Property ID: ${booking.propertyId}",
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Booking Status",
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Timeline
            Row(
              children: [
                _buildTimelineStep(
                  "Reserved",
                  "Deposit Paid",
                  booking.isDepositPaid,
                  isFirst: true,
                ),
                _buildTimelineLine(booking.isFullyPaid),
                _buildTimelineStep(
                  "Completed",
                  "Fully Paid",
                  booking.isFullyPaid,
                  isLast: true,
                ),
              ],
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Current Status: ${booking.status}",
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(
    String title,
    String subtitle,
    bool isActive, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isActive ? AdminTheme.brandPrimary : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? Icons.check : Icons.circle,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.black : Colors.grey,
            ),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 4,
        color: isActive ? AdminTheme.brandPrimary : Colors.grey[300],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Customer Info",
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(
                "${booking.firstName ?? ''} ${booking.lastName ?? ''}",
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "User ID: ${booking.userId}",
                style: const TextStyle(fontSize: 10),
              ),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone, color: Colors.green),
              title: Text(booking.phoneNumber ?? "No Phone"),
              onTap: booking.phoneNumber != null
                  ? () {
                      launchUrl(Uri.parse("tel:${booking.phoneNumber}"));
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Financial Details",
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFinancialRow(
              "Deposit Paid",
              booking.depositPaid,
              isBold: true,
              color: Colors.green,
            ),
            const Divider(),
            _buildFinancialRow(
              "Remaining Amount",
              booking.remainingAmount,
              color: Colors.orange,
            ),
            const Divider(),
            _buildFinancialRow(
              "Total Amount",
              booking.totalAmount,
              isBold: true,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialRow(
    String label,
    double amount, {
    bool isBold = false,
    Color? color,
    double size = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.cairo(fontSize: 14)),
          Text(
            "${NumberFormat('#,###').format(amount)} EGP",
            style: GoogleFonts.cairo(
              fontSize: size,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionsCard() {
    final selections = booking.metadata['selections'] as List<dynamic>?;
    if (selections == null || selections.isEmpty) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Selected Items",
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selections
                  .map(
                    (s) => Chip(
                      label: Text(
                        s.toString(),
                        style: GoogleFonts.cairo(fontSize: 12),
                      ),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
