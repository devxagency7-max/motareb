// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:animate_do/animate_do.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:provider/provider.dart';

// import '../../auth/providers/auth_provider.dart';
// import '../../../screens/verification_screen.dart';
// import '../../../screens/login_screen.dart';
// import '../../favorites/screens/favorites_screen.dart';

// class ProfileContent extends StatefulWidget {
//   const ProfileContent({super.key});

//   @override
//   State<ProfileContent> createState() => _ProfileContentState();
// }

// class _ProfileContentState extends State<ProfileContent> {
//   @override
//   Widget build(BuildContext context) {
//     final authProvider = context.watch<AuthProvider>();
//     bool isVerified = authProvider.user?.emailVerified ?? false;
//     String userName = authProvider.userData?['name'] ?? 'زائر';
//     String userEmail = authProvider.user?.email ?? 'سجل دخولك الآن';

//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           // 1. Expanded Header (Gradient Background)
//           Stack(
//             clipBehavior: Clip.none,
//             alignment: Alignment.center,
//             children: [
//               Container(
//                 height: 280,
//                 width: double.infinity,
//                 decoration: const BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [Color(0xFF39BB5E), Color(0xFF008695)],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.only(
//                     bottomLeft: Radius.circular(30),
//                     bottomRight: Radius.circular(30),
//                   ),
//                 ),
//                 child: SafeArea(
//                   child: Column(
//                     children: [
//                       const SizedBox(height: 20),
//                       Stack(
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(4),
//                             decoration: BoxDecoration(
//                               color: Colors.white.withOpacity(0.2),
//                               shape: BoxShape.circle,
//                             ),
//                             child: const CircleAvatar(
//                               radius: 45,
//                               backgroundColor: Colors.white,
//                               child: Icon(
//                                 Icons.person,
//                                 size: 50,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ),
//                           if (isVerified)
//                             Positioned(
//                               bottom: 0,
//                               right: 0,
//                               child: Container(
//                                 padding: const EdgeInsets.all(4),
//                                 decoration: const BoxDecoration(
//                                   color: Colors.white,
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: const Icon(
//                                   Icons.verified,
//                                   color: Colors.blue,
//                                   size: 20,
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ),
//                       const SizedBox(height: 15),
//                       Text(
//                         userName,
//                         style: GoogleFonts.cairo(
//                           color: Colors.white,
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Text(
//                         userEmail,
//                         style: GoogleFonts.cairo(
//                           color: Colors.white.withOpacity(0.9),
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               // 2. Floating Stats Card
//               Positioned(
//                 bottom: -40,
//                 left: 20,
//                 right: 20,
//                 child: FadeInUp(
//                   duration: const Duration(milliseconds: 500),
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       vertical: 20,
//                       horizontal: 15,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(20),
//                       boxShadow: [
//                         BoxShadow(
//                           color: const Color(0xFF008695).withOpacity(0.15),
//                           blurRadius: 20,
//                           offset: const Offset(0, 10),
//                         ),
//                       ],
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceAround,
//                       children: [
//                         _buildStatItem('المفضلة', '12'),
//                         Container(
//                           width: 1,
//                           height: 40,
//                           color: Colors.grey.shade200,
//                         ),
//                         _buildStatItem('المراجعات', '5'),
//                         Container(
//                           width: 1,
//                           height: 40,
//                           color: Colors.grey.shade200,
//                         ),
//                         _buildStatItem('الحجوزات', '3'),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 60),

//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             child: Column(
//               children: [
//                 // 3. Verification Alert
//                 if (!isVerified)
//                   FadeInUp(
//                     duration: const Duration(milliseconds: 600),
//                     child: GestureDetector(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => const VerificationScreen(),
//                           ),
//                         );
//                       },
//                       child: Container(
//                         margin: const EdgeInsets.only(bottom: 25),
//                         padding: const EdgeInsets.all(15),
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [
//                               const Color(0xFFFFC107).withOpacity(0.1),
//                               const Color(0xFFFF9800).withOpacity(0.1),
//                             ],
//                           ),
//                           borderRadius: BorderRadius.circular(20),
//                           border: Border.all(
//                             color: const Color(0xFFFFC107).withOpacity(0.5),
//                           ),
//                         ),
//                         child: Row(
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.all(10),
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFFFFF3CD),
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: const Icon(
//                                 Icons.verified_user_outlined,
//                                 color: Color(0xFF856404),
//                               ),
//                             ),
//                             const SizedBox(width: 15),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     'توثيق الحساب',
//                                     style: GoogleFonts.cairo(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 16,
//                                       color: const Color(0xFF856404),
//                                     ),
//                                   ),
//                                   Text(
//                                     'قم بتوثيق حسابك للاستفادة من كافة الميزات',
//                                     style: GoogleFonts.cairo(
//                                       fontSize: 12,
//                                       color: const Color(0xFF856404),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             const Icon(
//                               Icons.arrow_forward_ios,
//                               size: 16,
//                               color: Color(0xFF856404),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),

//                 // 4. Menu Items
//                 if (authProvider.user != null) ...[
//                   _buildProfileMenuItem(
//                     'المعلومات الشخصية',
//                     Icons.person_outline,
//                     delay: 100,
//                     onTap: () {},
//                   ),
//                   _buildProfileMenuItem(
//                     'حجوزاتي',
//                     Icons.calendar_today_outlined,
//                     delay: 200,
//                     onTap: () {},
//                   ),
//                   _buildProfileMenuItem(
//                     'المفضلة',
//                     Icons.favorite_border,
//                     delay: 300,
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const FavoritesScreen(),
//                         ),
//                       );
//                     },
//                   ),
//                   _buildProfileMenuItem(
//                     'الإعدادات',
//                     Icons.settings_outlined,
//                     delay: 400,
//                     onTap: () {},
//                   ),
//                   _buildProfileMenuItem(
//                     'تسجيل الخروج',
//                     Icons.logout,
//                     isDestructive: true,
//                     delay: 500,
//                     onTap: () async {
//                       await authProvider.signOut();
//                       if (mounted) {
//                         Navigator.of(context).pushAndRemoveUntil(
//                           MaterialPageRoute(
//                             builder: (context) => const LoginScreen(),
//                           ),
//                           (route) => false,
//                         );
//                       }
//                     },
//                   ),
//                 ] else ...[
//                   _buildProfileMenuItem(
//                     'تسجيل الدخول',
//                     Icons.login,
//                     delay: 100,
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const LoginScreen(),
//                         ),
//                       );
//                     },
//                   ),
//                   _buildProfileMenuItem(
//                     'الإعدادات',
//                     Icons.settings_outlined,
//                     delay: 200,
//                     onTap: () {},
//                   ),
//                 ],

//                 const SizedBox(height: 40),

//                 // 5. Large Footer Logo
//                 FadeInUp(
//                   duration: const Duration(milliseconds: 800),
//                   child: Column(
//                     children: [
//                       Text(
//                         'Powered By',
//                         style: GoogleFonts.cairo(
//                           color: Colors.grey,
//                           fontSize: 12,
//                           letterSpacing: 1,
//                         ),
//                       ),
//                       const SizedBox(height: 15),
//                       GestureDetector(
//                         onTap: () async {
//                           const url = 'https://dev-x-one.vercel.app/';
//                           if (await canLaunchUrl(Uri.parse(url))) {
//                             await launchUrl(Uri.parse(url));
//                           }
//                         },
//                         child: Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: Colors.white,
//                             boxShadow: [
//                               BoxShadow(
//                                 color: const Color(0xFF008695).withOpacity(0.2),
//                                 blurRadius: 25,
//                                 offset: const Offset(0, 10),
//                               ),
//                             ],
//                           ),
//                           child: const CircleAvatar(
//                             radius: 60,
//                             backgroundColor: Colors.transparent,
//                             backgroundImage: AssetImage(
//                               'assets/images/devx.png',
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 50),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatItem(String label, String count) {
//     return Column(
//       children: [
//         Text(
//           count,
//           style: GoogleFonts.cairo(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: const Color(0xFF008695),
//           ),
//         ),
//         Text(label, style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
//       ],
//     );
//   }

//   Widget _buildProfileMenuItem(
//     String title,
//     IconData icon, {
//     bool isDestructive = false,
//     int delay = 0,
//     VoidCallback? onTap,
//   }) {
//     return FadeInUp(
//       duration: const Duration(milliseconds: 500),
//       delay: Duration(milliseconds: delay),
//       child: GestureDetector(
//         onTap: onTap,
//         child: Container(
//           margin: const EdgeInsets.only(bottom: 15),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(15),
//             boxShadow: [
//               BoxShadow(
//                 color: const Color(0xFF008695).withOpacity(0.05),
//                 blurRadius: 10,
//                 offset: const Offset(0, 5),
//               ),
//             ],
//           ),
//           child: ListTile(
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 20,
//               vertical: 5,
//             ),
//             leading: Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 gradient: isDestructive
//                     ? LinearGradient(
//                         colors: [
//                           Colors.red.withOpacity(0.1),
//                           Colors.red.withOpacity(0.05),
//                         ],
//                       )
//                     : const LinearGradient(
//                         colors: [Color(0xFF39BB5E), Color(0xFF008695)],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                 shape: BoxShape.circle,
//                 boxShadow: !isDestructive
//                     ? [
//                         BoxShadow(
//                           color: const Color(0xFF39BB5E).withOpacity(0.3),
//                           blurRadius: 8,
//                           offset: const Offset(0, 3),
//                         ),
//                       ]
//                     : [],
//               ),
//               child: Icon(
//                 icon,
//                 color: isDestructive ? Colors.red : Colors.white,
//                 size: 22,
//               ),
//             ),
//             title: Text(
//               title,
//               style: GoogleFonts.cairo(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//                 color: isDestructive ? Colors.red : const Color(0xFF003D4D),
//               ),
//             ),
//             trailing: const Icon(
//               Icons.arrow_forward_ios,
//               size: 16,
//               color: Colors.grey,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
