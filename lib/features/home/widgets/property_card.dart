// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import '../../../core/models/property_model.dart';
// import '../../../screens/property_details_screen.dart';

// class PropertyCard extends StatelessWidget {
//   final Property property;

//   const PropertyCard({super.key, required this.property});

//   @override
//   Widget build(BuildContext context) {
//     // Favorites functionality removed for Admin App

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
//         width: 200,
//         margin: const EdgeInsets.only(right: 15),
//         padding: const EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: const [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 10,
//               offset: Offset(0, 5),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Image
//             Expanded(
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(15),
//                 child: Stack(
//                   children: [
//                     Hero(
//                       tag: 'property_image_${property.id}',
//                       child:
//                           property.imageUrl.startsWith('http') ||
//                               property.imageUrl.startsWith('assets')
//                           ? (property.imageUrl.startsWith('assets')
//                                 ? Image.asset(
//                                     property.imageUrl,
//                                     width: double.infinity,
//                                     height: double.infinity,
//                                     fit: BoxFit.cover,
//                                   )
//                                 : Image.network(
//                                     property.imageUrl,
//                                     width: double.infinity,
//                                     height: double.infinity,
//                                     fit: BoxFit.cover,
//                                     errorBuilder:
//                                         (context, error, stackTrace) =>
//                                             Container(
//                                               color: Colors.grey.shade200,
//                                               child: const Center(
//                                                 child: Icon(
//                                                   Icons.image_not_supported,
//                                                 ),
//                                               ),
//                                             ),
//                                   ))
//                           : Image.memory(
//                               base64Decode(property.imageUrl), // Decode Base64
//                               width: double.infinity,
//                               height: double.infinity,
//                               fit: BoxFit.cover,
//                               errorBuilder: (context, error, stackTrace) =>
//                                   Container(
//                                     color: Colors.grey.shade200,
//                                     child: const Center(
//                                       child: Icon(Icons.broken_image),
//                                     ),
//                                   ),
//                             ),
//                     ),

//                     // Removed Favorites Button for Admin App
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               property.title,
//               style: GoogleFonts.cairo(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 13,
//               ),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//             Text(
//               property.location,
//               style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
//             ),
//             const SizedBox(height: 5),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   '${property.price.toInt()} ج.م',
//                   style: GoogleFonts.cairo(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 11,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 5),
//             // "Book Now" Button Style
//             Container(
//               width: double.infinity,
//               height: 30,
//               decoration: BoxDecoration(
//                 gradient: const LinearGradient(
//                   colors: [Color(0xFF39BB5E), Color(0xFF008695)],
//                   begin: Alignment.centerRight,
//                   end: Alignment.centerLeft,
//                 ),
//                 borderRadius: BorderRadius.circular(8),
//                 boxShadow: [
//                   BoxShadow(
//                     color: const Color(0xFF008695).withOpacity(0.3),
//                     blurRadius: 5,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Center(
//                 child: Text(
//                   'احجز الآن',
//                   style: GoogleFonts.cairo(color: Colors.white, fontSize: 11),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
