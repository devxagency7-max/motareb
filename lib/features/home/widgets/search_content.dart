// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// import '../../../core/models/property_model.dart';
// import '../../../screens/filter_screen.dart';
// import '../../../screens/property_details_screen.dart';

// class SearchContent extends StatelessWidget {
//   const SearchContent({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // Dummy Data for Search Results
//     final List<Property> searchResults = [
//       Property(
//         id: 'search_1',
//         title: 'غرفة مفردة في حي النخيل',
//         location: 'الرياض - حي النخيل',
//         price: 1200.0,
//         imageUrl:
//             'https://images.unsplash.com/photo-1596276020587-8044fe049813?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80',
//         type: 'غرفة',
//         isVerified: true,
//         isNew: true,
//         amenities: ['1 شخص', 'ممنوع التدخين', 'ذكور فقط'],
//         createdAt: DateTime.now(),
//       ),
//       Property(
//         id: 'search_2',
//         title: 'شقة عائلية فاخرة',
//         location: 'جدة - حي الحمراء',
//         price: 3500.0,
//         imageUrl:
//             'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80',
//         type: 'شقة',
//         isVerified: true,
//         amenities: ['عائلات', 'موقف خاص'],
//         createdAt: DateTime.now(),
//       ),
//       Property(
//         id: 'search_3',
//         title: 'استوديو بالقرب من العمل',
//         location: 'الدمام - حي الشاطئ',
//         price: 1500.0,
//         imageUrl:
//             'https://images.unsplash.com/photo-1554995207-c18c203602cb?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80',
//         type: 'استوديو',
//         isVerified: false,
//         amenities: ['يسمح بالحيوانات'],
//         createdAt: DateTime.now(),
//       ),
//       Property(
//         id: 'search_4',
//         title: 'غرفة مشتركة للطلاب',
//         location: 'الخبر - الحزام الذهبي',
//         price: 600.0,
//         imageUrl:
//             'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80',
//         type: 'سرير',
//         isVerified: true,
//         amenities: ['طلاب فقط', 'إنترنت مجاني'],
//         governorate: 'الخبر',
//         createdAt: DateTime.now(),
//       ),
//     ];

//     return Column(
//       children: [
//         // Header - Fixed at top
//         Padding(
//           padding: EdgeInsets.only(
//             top: MediaQuery.of(context).padding.top + 20,
//             left: 20,
//             right: 20,
//             bottom: 20,
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'الشقاق المتاحة',
//                     style: GoogleFonts.cairo(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Text(
//                     '${searchResults.length} عقارات متاحة',
//                     style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
//                   ),
//                 ],
//               ),
//               GestureDetector(
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     PageRouteBuilder(
//                       pageBuilder: (context, animation, secondaryAnimation) =>
//                           FilterScreen(),
//                       transitionsBuilder:
//                           (context, animation, secondaryAnimation, child) {
//                             const begin = Offset(0.0, 1.0);
//                             const end = Offset.zero;
//                             const curve = Curves.easeInOut;

//                             var tween = Tween(
//                               begin: begin,
//                               end: end,
//                             ).chain(CurveTween(curve: curve));

//                             return SlideTransition(
//                               position: animation.drive(tween),
//                               child: child,
//                             );
//                           },
//                     ),
//                   );
//                 },
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 6,
//                   ),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF39BB5E).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Row(
//                     children: [
//                       const Icon(
//                         Icons.tune,
//                         size: 16,
//                         color: Color(0xFF39BB5E),
//                       ),
//                       const SizedBox(width: 5),
//                       Text(
//                         'تصفية',
//                         style: GoogleFonts.cairo(
//                           color: const Color(0xFF39BB5E),
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(width: 5),
//                       Container(
//                         padding: const EdgeInsets.all(4),
//                         decoration: const BoxDecoration(
//                           color: Color(0xFF39BB5E),
//                           shape: BoxShape.circle,
//                         ),
//                         child: Text(
//                           '3',
//                           style: GoogleFonts.cairo(
//                             color: Colors.white,
//                             fontSize: 10,
//                             height: 1,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),

//         // List
//         Expanded(
//           child: ListView.builder(
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             itemCount: searchResults.length,
//             itemBuilder: (context, index) {
//               return _buildLargeSearchCard(context, searchResults[index]);
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   // Keeping the specific design for Search cards but updating data mapping
//   // We can eventually replace this with PropertyCard if we want identical design,
//   // but the user requested "Favorites card... same design as application", implying
//   // we should use the standard card.
//   // However, the search list usually has a different, larger layout.
//   // For favorites, the user asked for "same design as card".
//   // The PropertyCard created is the "Featured" style (Standard vertical card).
//   // The Favorites screen uses GridView with PropertyCard.
//   // The Search screen uses a large list card.
//   // I will keep the custom large card for Search for now, but update it to use the Property model.

//   Widget _buildLargeSearchCard(BuildContext context, Property property) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => PropertyDetailsScreen(property: property),
//           ),
//         );
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 20),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.1),
//               blurRadius: 10,
//               offset: const Offset(0, 5),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Image + Badges
//             Stack(
//               children: [
//                 ClipRRect(
//                   borderRadius: const BorderRadius.vertical(
//                     top: Radius.circular(20),
//                   ),
//                   child: Image.network(
//                     property.imageUrl,
//                     height: 180,
//                     width: double.infinity,
//                     fit: BoxFit.cover,
//                     errorBuilder: (context, error, stackTrace) => Container(
//                       height: 180,
//                       width: double.infinity,
//                       color: Colors.grey.shade200,
//                       child: const Icon(
//                         Icons.image,
//                         size: 50,
//                         color: Colors.grey,
//                       ),
//                     ),
//                   ),
//                 ),
//                 if (property.isVerified)
//                   Positioned(
//                     top: 15,
//                     right: 15,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF008695),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Row(
//                         children: [
//                           const Icon(
//                             Icons.check_circle_outline,
//                             color: Colors.white,
//                             size: 14,
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             'موثق',
//                             style: GoogleFonts.cairo(
//                               color: Colors.white,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 // Use PropertyCard's favorite logic here or just display?
//                 // Since search has its own card, we should use FavoritesProvider here too.
//                 // I'll leave the heart icon visual for now, but ideally it should work.
//                 /*
//               Positioned(
//                 top: 15,
//                 left: 15,
//                 child: Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: const BoxDecoration(
//                     color: Colors.white,
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(Icons.favorite_border, size: 20),
//                 ),
//               ),
//               */
//                 if (property.isNew)
//                   Positioned(
//                     bottom: 15,
//                     left: 15,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF69F0AE),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Text(
//                         'متاح الآن',
//                         style: GoogleFonts.cairo(
//                           color: Colors.white,
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             ),

//             // Details
//             Padding(
//               padding: const EdgeInsets.all(15),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         '${property.price.toInt()} رس/شهر',
//                         style: GoogleFonts.cairo(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: const Color(0xFF008695),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 5),
//                   Text(
//                     property.type,
//                     style: GoogleFonts.cairo(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 5),
//                   Row(
//                     children: [
//                       const Icon(
//                         Icons.location_on_outlined,
//                         size: 16,
//                         color: Colors.grey,
//                       ),
//                       const SizedBox(width: 4),
//                       Text(
//                         property.location,
//                         style: GoogleFonts.cairo(color: Colors.grey),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                   // Tags
//                   if (property.amenities.isNotEmpty)
//                     Wrap(
//                       spacing: 8,
//                       children: property.amenities
//                           .map((tag) => _buildTag(Icons.check, tag))
//                           .toList(),
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTag(IconData icon, String label) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: const Color(0xFFE0F2F1),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 14, color: Colors.teal),
//           const SizedBox(width: 4),
//           Text(
//             label,
//             style: GoogleFonts.cairo(fontSize: 12, color: Colors.teal),
//           ),
//         ],
//       ),
//     );
//   }
// }
