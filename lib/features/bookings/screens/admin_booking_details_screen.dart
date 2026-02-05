import 'package:admin_motareb/core/theme/admin_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:admin_motareb/core/utils/loc_extension.dart';

import '../models/booking_model.dart';

class AdminBookingDetailsScreen extends StatelessWidget {
  final BookingModel booking;

  const AdminBookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('properties')
          .doc(booking.propertyId)
          .get(),
      builder: (context, snapshot) {
        final propertyData = snapshot.data?.data() as Map<String, dynamic>?;
        final roomList = propertyData?['rooms'] as List<dynamic>? ?? [];

        return Scaffold(
          appBar: AppBar(
            title: Text(
              context.loc.bookingDetails,
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // 1. Metadata/Selections (Now at the top and more prominent)
                      if (booking.metadata.containsKey('selections'))
                        _buildSelectionsCard(context, roomList),
                      if (booking.metadata.containsKey('selections'))
                        const SizedBox(height: 20),

                      // 1. Property Header Card
                      _buildPropertyHeader(context, propertyData),
                      const SizedBox(height: 20),

                      // 2. Status & Timeline
                      _buildStatusCard(context),
                      const SizedBox(height: 20),

                      // 3. User Info
                      _buildUserCard(context),
                      const SizedBox(height: 20),

                      // 4. Payment Details
                      _buildPaymentInfoCard(context),
                      const SizedBox(height: 20),

                      // 6. ID Card Images
                      _buildIDVerificationCard(context),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildPropertyHeader(
    BuildContext context,
    Map<String, dynamic>? data,
  ) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final title = isArabic
        ? (data?['title'] ?? 'Unknown Property')
        : (data?['titleEn'] ?? data?['title'] ?? 'Unknown Property');
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
                  "${context.loc.propertyId}: ${booking.propertyId}",
                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.loc.bookingStatus,
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
                  context,
                  context.loc.reserved,
                  context.loc.depositPaid,
                  booking.isDepositPaid,
                  isFirst: true,
                ),
                _buildTimelineLine(booking.isFullyPaid),
                _buildTimelineStep(
                  context,
                  context.loc.completed,
                  context.loc.totalAmount,
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
                    "${context.loc.currentStatus}: ${booking.status}",
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
    BuildContext context,
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
              context.loc.customerInfo,
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
                "${context.loc.userId}: ${booking.userId}",
                style: const TextStyle(fontSize: 10),
              ),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone, color: Colors.green),
              title: Text(booking.phoneNumber ?? context.loc.other),
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

  Widget _buildPaymentInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.loc.financialDetails,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFinancialRow(
              context,
              context.loc.depositPaid,
              booking.depositPaid,
              isBold: true,
              color: Colors.green,
            ),
            const Divider(),
            _buildFinancialRow(
              context,
              context.loc.remainingAmount,
              booking.remainingAmount,
              color: Colors.orange,
            ),
            const Divider(),
            _buildFinancialRow(
              context,
              context.loc.totalAmount,
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
    BuildContext context,
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
            "${NumberFormat('#,###').format(amount)} ${context.loc.currency}",
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

  Widget _buildSelectionsCard(BuildContext context, List<dynamic> roomList) {
    final selections = booking.metadata['selections'] as List<dynamic>?;
    if (selections == null || selections.isEmpty) return const SizedBox();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF39BB5E), Color(0xFF008695)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF008695).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.stars, color: Colors.white, size: 28),
                const SizedBox(width: 10),
                Text(
                  context.loc.selectedItems,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: selections.map((s) {
                final displayName = _getSelectionDisplayName(
                  context,
                  s.toString(),
                  roomList,
                );
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    displayName,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.brandPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _getSelectionDisplayName(
    BuildContext context,
    String id,
    List<dynamic> roomList,
  ) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    // 1. Handle index-based keys (e.g., "r0" or "r0_b1")
    if (id.startsWith('r')) {
      try {
        final parts = id.split('_');
        final roomIdx = int.parse(parts[0].substring(1));
        if (roomIdx >= 0 && roomIdx < roomList.length) {
          final roomData = roomList[roomIdx] as Map<String, dynamic>;
          final roomName = isAr
              ? (roomData['name'] ?? roomData['title'] ?? "غرفة ${roomIdx + 1}")
              : (roomData['nameEn'] ??
                    roomData['titleEn'] ??
                    roomData['name'] ??
                    roomData['title'] ??
                    "Room ${roomIdx + 1}");

          if (parts.length > 1 && parts[1].startsWith('b')) {
            final bedIdx = int.parse(parts[1].substring(1));
            final beds = roomData['beds'];
            if (beds is List && bedIdx >= 0 && bedIdx < beds.length) {
              final bedData = beds[bedIdx];
              if (bedData is Map<String, dynamic>) {
                final bedName = isAr
                    ? (bedData['name'] ??
                          bedData['title'] ??
                          "سرير ${bedIdx + 1}")
                    : (bedData['nameEn'] ??
                          bedData['titleEn'] ??
                          bedData['name'] ??
                          bedData['title'] ??
                          "Bed ${bedIdx + 1}");
                return "$roomName - $bedName";
              }
            }
            return isAr
                ? "$roomName - سرير ${bedIdx + 1}"
                : "$roomName - Bed ${bedIdx + 1}";
          }
          return roomName;
        }
      } catch (e) {
        // Fallback to ID matching if parsing fails
      }
    }

    // 2. Original ID-based matching logic
    for (var room in roomList) {
      if (room is! Map<String, dynamic>) continue;
      final roomData = room;
      if (roomData['id']?.toString() == id) {
        return isAr
            ? (roomData['name'] ?? roomData['title'] ?? id)
            : (roomData['nameEn'] ??
                  roomData['titleEn'] ??
                  roomData['name'] ??
                  roomData['title'] ??
                  id);
      }
      final beds = roomData['beds'];
      if (beds is List) {
        for (var bed in beds) {
          if (bed is! Map<String, dynamic>) continue;
          final bedData = bed;
          if (bedData['id']?.toString() == id) {
            final roomName = isAr
                ? (roomData['name'] ?? roomData['title'] ?? "")
                : (roomData['nameEn'] ??
                      roomData['titleEn'] ??
                      roomData['name'] ??
                      roomData['title'] ??
                      "");

            final bedName = isAr
                ? (bedData['name'] ?? bedData['title'] ?? "سرير")
                : (bedData['nameEn'] ??
                      bedData['titleEn'] ??
                      bedData['name'] ??
                      bedData['title'] ??
                      "Bed");
            return "$roomName - $bedName";
          }
        }
      }
    }
    return id; // Fallback to ID if not found
  }

  Widget _buildIDVerificationCard(BuildContext context) {
    final userInfo = booking.metadata['userInfo'] as Map<String, dynamic>?;
    final idFrontUrl = userInfo?['idFrontUrl'] as String?;
    final idBackUrl = userInfo?['idBackUrl'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.loc.idVerification,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildIdImage(
                    context,
                    context.loc.idFront,
                    idFrontUrl,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildIdImage(context, context.loc.idBack, idBackUrl),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdImage(BuildContext context, String title, String? url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: url != null
              ? () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Image.network(url, fit: BoxFit.contain),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              shadows: [Shadow(blurRadius: 10)],
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              : null,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: url != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.error),
                    ),
                  )
                : Center(
                    child: Text(
                      context.loc.noIdProvided,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
