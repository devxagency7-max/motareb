// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';

// import '../../../admin/admin_dashboard.dart';
// import '../../../core/models/property_model.dart';
// import '../../../screens/filter_screen.dart';
// import '../../../screens/property_details_screen.dart';
// import '../../auth/providers/auth_provider.dart';
// import '../providers/home_provider.dart';
// import 'property_card.dart';

// class HomeContent extends StatelessWidget {
//   HomeContent({super.key});

//   final List<String> _categories = ['الكل', 'جامعة', 'محافظه', 'غرفة', 'سرير'];

//   // Dummy Data

//   @override
//   Widget build(BuildContext context) {
//     // Access providers
//     final authProvider = context.watch<AuthProvider>();

//     return SingleChildScrollView(
//       padding: EdgeInsets.only(
//         top: MediaQuery.of(context).padding.top + 20,
//         left: 20,
//         right: 20,
//         bottom: 20,
//       ),
//       child: Column(
//         children: [
//           _buildHeader(context, authProvider),
//           const SizedBox(height: 20),
//           _buildSearchBar(context),
//           const SizedBox(height: 20),
//           _buildCategories(context),
//           const SizedBox(height: 20),
//           StreamBuilder<List<Property>>(
//             stream: context.read<HomeProvider>().propertiesStream,
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }
//               if (snapshot.hasError) {
//                 return Center(child: Text('حدث خطأ: ${snapshot.error}'));
//               }

//               final properties = snapshot.data ?? [];
//               if (properties.isEmpty) {
//                 return const Center(
//                   child: Text('لا توجد عقارات مضافة حتى الآن'),
//                 );
//               }

//               // Simple logic: Featured are high rated, Recent are all (sorted by date in service)
//               // You can refine this logic
//               final featuredProperties = properties
//                   .where((p) => p.rating >= 4.5)
//                   .toList();
//               // If no high rated, just take first 5
//               final displayFeatured = featuredProperties.isNotEmpty
//                   ? featuredProperties
//                   : properties.take(5).toList();

//               return Column(
//                 children: [
//                   _buildSectionTitle('مميزة لك ✨', 'عرض الكل'),
//                   const SizedBox(height: 15),
//                   _buildFeaturedList(context, displayFeatured),
//                   const SizedBox(height: 25),
//                   _buildSectionTitle('أضيف حديثاً 🆕', ''),
//                   const SizedBox(height: 15),
//                   _buildRecentlyAddedList(context, properties),
//                   const SizedBox(height: 20),
//                 ],
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeader(BuildContext context, AuthProvider authProvider) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         // Greeting
//         Row(
//           children: [
//             const CircleAvatar(
//               radius: 22,
//               backgroundImage: AssetImage('assets/images/logo.png'),
//             ),
//             const SizedBox(width: 10),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'صباح الخير',
//                   style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
//                 ),
//                 Text(
//                   'أهلاً ${authProvider.userData?['name'] ?? 'زائر'}',
//                   style: GoogleFonts.cairo(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         // Actions Row
//         Row(
//           children: [
//             if (authProvider.isAdmin)
//               GestureDetector(
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const AdminDashboard(),
//                     ),
//                   );
//                 },
//                 child: Container(
//                   margin: const EdgeInsets.only(left: 10),
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 8,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.redAccent.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(
//                       color: Colors.redAccent.withOpacity(0.5),
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       const Icon(
//                         Icons.admin_panel_settings,
//                         size: 18,
//                         color: Colors.redAccent,
//                       ),
//                       const SizedBox(width: 5),
//                       Text(
//                         'لوحة التحكم',
//                         style: GoogleFonts.cairo(
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.redAccent,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             // Notification
//             Container(
//               padding: const EdgeInsets.all(10),
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 shape: BoxShape.circle,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black12,
//                     blurRadius: 10,
//                     offset: Offset(0, 5),
//                   ),
//                 ],
//               ),
//               child: const Icon(Icons.notifications_outlined, size: 22),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildSearchBar(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 15),
//             height: 50,
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(15),
//               boxShadow: const [
//                 BoxShadow(
//                   color: Colors.black12,
//                   blurRadius: 10,
//                   offset: Offset(0, 5),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 const Icon(Icons.search, color: Colors.grey),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: TextField(
//                     textAlign: TextAlign.right,
//                     decoration: InputDecoration(
//                       hintText: 'وين حاب تسكن؟',
//                       hintStyle: GoogleFonts.cairo(color: Colors.grey),
//                       border: InputBorder.none,
//                     ),
//                     onSubmitted: (value) {
//                       // Switch to search tab on submit
//                       context.read<HomeProvider>().setIndex(1);
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         const SizedBox(width: 10),
//         GestureDetector(
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (c) => FilterScreen()),
//             );
//           },
//           child: Container(
//             height: 50,
//             width: 50,
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(
//                 colors: [Color(0xFF39BB5E), Color(0xFF008695)],
//                 begin: Alignment.centerRight,
//                 end: Alignment.centerLeft,
//               ),
//               borderRadius: BorderRadius.circular(15),
//               boxShadow: [
//                 BoxShadow(
//                   color: const Color(0xFF008695).withOpacity(0.3),
//                   blurRadius: 10,
//                   offset: const Offset(0, 5),
//                 ),
//               ],
//             ),
//             child: const Icon(Icons.tune, color: Colors.white),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCategories(BuildContext context) {
//     return SizedBox(
//       height: 40,
//       child: ListView.separated(
//         scrollDirection: Axis.horizontal,
//         itemCount: _categories.length,
//         separatorBuilder: (_, __) => const SizedBox(width: 10),
//         itemBuilder: (context, index) {
//           final selectedIndex = context
//               .watch<HomeProvider>()
//               .selectedCategoryIndex;
//           final isSelected = index == selectedIndex;
//           return GestureDetector(
//             onTap: () => context.read<HomeProvider>().setCategoryIndex(index),
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//               decoration: BoxDecoration(
//                 gradient: isSelected
//                     ? const LinearGradient(
//                         colors: [Color(0xFF39BB5E), Color(0xFF008695)],
//                         begin: Alignment.centerRight,
//                         end: Alignment.centerLeft,
//                       )
//                     : null,
//                 color: isSelected ? null : Colors.white,
//                 borderRadius: BorderRadius.circular(20),
//                 border: isSelected
//                     ? null
//                     : Border.all(color: Colors.grey.shade200),
//               ),
//               child: Text(
//                 _categories[index],
//                 style: GoogleFonts.cairo(
//                   color: isSelected ? Colors.white : Colors.black,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title, String action) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           title,
//           style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         if (action.isNotEmpty)
//           Text(
//             action,
//             style: GoogleFonts.cairo(
//               color: Colors.teal,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildFeaturedList(BuildContext context, List<Property> properties) {
//     return SizedBox(
//       height: 280,
//       child: ListView.separated(
//         scrollDirection: Axis.horizontal,
//         itemCount: properties.length,
//         separatorBuilder: (_, __) => const SizedBox(width: 15),
//         itemBuilder: (context, index) {
//           // Use PropertyCard for cleaner code
//           return PropertyCard(property: properties[index]);
//         },
//       ),
//     );
//   }

//   Widget _buildRecentlyAddedList(
//     BuildContext context,
//     List<Property> properties,
//   ) {
//     return ListView.separated(
//       physics: const NeverScrollableScrollPhysics(),
//       shrinkWrap: true,
//       itemCount: properties.length,
//       separatorBuilder: (_, __) => const SizedBox(height: 15),
//       itemBuilder: (context, index) {
//         // Reuse PropertyCard here or keep custom list item.
//         // For visual consistency with the design shown in user requests (horizontal cards),
//         // we might want to keep the custom horizontal layout for "Recently Added"
//         // OR adapt PropertyCard to support horizontal mode.
//         // For now, I'll update it to use Property data but keep the horizontal layout code
//         // to match the specific "Recently Added" list tile design.
//         final property = properties[index];
//         return GestureDetector(
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => PropertyDetailsScreen(property: property),
//               ),
//             );
//           },
//           child: Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(20),
//               boxShadow: const [
//                 BoxShadow(
//                   color: Colors.black12,
//                   blurRadius: 5,
//                   offset: Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 // Image
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(15),
//                   child: Image.network(
//                     property.imageUrl,
//                     height: 80,
//                     width: 80,
//                     fit: BoxFit.cover,
//                     errorBuilder: (context, error, stackTrace) => Container(
//                       height: 80,
//                       width: 80,
//                       color: Colors.grey.shade200,
//                       child: const Icon(Icons.bed, color: Colors.grey),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 15),
//                 // Details
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       if (property.isNew)
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 6,
//                             vertical: 2,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.green.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                           child: Text(
//                             'جديد',
//                             style: GoogleFonts.cairo(
//                               color: Colors.green,
//                               fontSize: 10,
//                             ),
//                           ),
//                         ),
//                       Text(
//                         property.title,
//                         style: GoogleFonts.cairo(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 14,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       Text(
//                         '${property.location} ${property.amenities.isNotEmpty ? "• ${property.amenities.first}" : ""}',
//                         style: GoogleFonts.cairo(
//                           fontSize: 10,
//                           color: Colors.grey,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 5),
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.star,
//                             size: 14,
//                             color: Colors.amber.shade600,
//                           ),
//                           const SizedBox(width: 2),
//                           Text(
//                             property.rating.toString(),
//                             style: GoogleFonts.cairo(
//                               fontSize: 11,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 Text(
//                   '${property.price.toInt()} ج.م',
//                   style: GoogleFonts.cairo(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                     color: const Color(0xFF008695),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
