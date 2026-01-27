import 'package:admin_motareb/admin/admin_add_properties_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'admin_pending_properties_screen.dart';
import 'admin_all_properties_screen.dart';
// import 'admin_add_property_screen.dart';
import '../features/chat/screens/admin_chat_list_screen.dart';
import 'admin_users_screen.dart';
import 'admin_reservations_screen.dart';
import 'admin_universities_screen.dart';
import 'admin_verification_screen.dart';
import 'admin_contact_numbers_screen.dart';
import 'package:admin_motareb/core/utils/loc_extension.dart';
import 'package:admin_motareb/core/providers/locale_provider.dart';
import 'package:admin_motareb/core/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.loc.appTitle,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        actions: [
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, child) {
              final isArabic = localeProvider.locale?.languageCode != 'en';
              return IconButton(
                icon: Text(
                  isArabic ? 'EN' : 'AR',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF008695),
                  ),
                ),
                onPressed: () {
                  localeProvider.setLocale(
                    isArabic ? const Locale('en') : const Locale('ar'),
                  );
                },
              );
            },
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  color: const Color(0xFF008695),
                ),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Welcome Banner
            FadeInDown(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF39BB5E).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.loc.welcomeAdmin,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      context.loc.adminSubHeader,
                      style: GoogleFonts.cairo(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Grid Options
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildDashboardCard(
                    context,
                    title: context.loc.reservations,
                    subtitle: context.loc.manageReservations,
                    icon: Icons.calendar_today_outlined,
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminReservationsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: context.loc.chats,
                    subtitle: context.loc.technicalSupport,
                    icon: Icons.chat_bubble_outline,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminChatListScreen(),
                        ),
                      );
                    },
                  ),
                  // 1. ADD PROPERTY (NEW)
                  _buildDashboardCard(
                    context,
                    title: context.loc.addProperty,
                    subtitle: context.loc.newPropertyPublish,
                    icon: Icons.add_home_work,
                    color: const Color(0xFF39BB5E),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminAddPropertyScreen(),
                        ),
                      );
                    },
                  ),

                  _buildDashboardCard(
                    context,
                    title: context.loc.publicationRequests,
                    subtitle: context.loc.reviewAcceptProperties,
                    icon: Icons.assignment_late_outlined,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AdminPendingPropertiesScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: context.loc.allApartments,
                    subtitle: context.loc.manageEditAll,
                    icon: Icons.apartment,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AdminAllPropertiesScreen(),
                        ),
                      );
                    },
                  ),

                  _buildDashboardCard(
                    context,
                    title: context.loc.users,
                    subtitle: context.loc.manageAccounts,
                    icon: Icons.people_outline,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminUsersScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: context.loc.universities,
                    subtitle: context.loc.manageUniversities,
                    icon: Icons.school,
                    color: Colors.blueGrey,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminUniversitiesScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: context.loc.settings,
                    subtitle: context.loc.generalSettings,
                    icon: Icons.settings_outlined,
                    color: Colors.grey,
                    onTap: () {},
                  ),
                  _buildDashboardCard(
                    context,
                    title: context.loc.verification,
                    subtitle: context.loc.identityRequests,
                    icon: Icons.verified_user_outlined,
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminVerificationScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: context.loc.numbers,
                    subtitle: context.loc.manageContactNumbers,
                    icon: Icons.phone_android,
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AdminContactNumbersScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: context.loc.ads,
                    subtitle: context.loc.manageAds,
                    icon: Icons.campaign_rounded,
                    color: Colors.amber,
                    onTap: () {
                      // TODO: Implement Ads management screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.loc.ads + " - Coming Soon / قريباً",
                            style: GoogleFonts.cairo(),
                          ),
                          backgroundColor: const Color(0xFF008695),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return FadeInUp(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: Theme.of(context).brightness == Brightness.dark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2F3640)
                  : Colors.transparent,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(height: 15),
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
