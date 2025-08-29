import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tb_web/screens/home_screens/profile_section_screens/account_screen.dart';
import 'package:tb_web/screens/home_screens/profile_section_screens/help_support_screen.dart';
import 'package:tb_web/screens/home_screens/profile_section_screens/privacy_policy_screen.dart';
import '../authentication_screens/login_screen.dart';
import 'booking_screen.dart';

// UI Configuration Class
class UIConfig {
  // Color Palette
  static const Color primaryColor = Color(0xFF00A859);
  static const Color secondaryColor = Color(0xFF00C853);
  static const Color accentColor = Color(0xFFFFD600);
  static const Color darkColor = Color(0xFF263238);
  static const Color lightColor = Color(0xFFF5F7FA);
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFFA000);
  static const Color successColor = Color(0xFF43A047);

  // Shimmer Colors
  static const Color shimmerBaseColor = Color(0xFFE0E0E0);
  static const Color shimmerHighlightColor = Color(0xFFFAFAFA);

  // Elevation
  static const double cardElevation = 4.0;

  // Responsive scaling factor
  static double scaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return 0.85;  // Small phones
    if (width < 400) return 0.95;  // Medium phones
    return 1.0;                    // Large phones/tablets
  }

  // Responsive padding
  static double padding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return 12.0;
    if (width < 400) return 16.0;
    return 20.0;
  }

  // Text Styles
  static TextStyle headlineLarge(BuildContext context) => GoogleFonts.poppins(
    fontSize: 22 * scaleFactor(context),
    fontWeight: FontWeight.w700,
    color: darkColor,
  );

  static TextStyle headlineMedium(BuildContext context) => GoogleFonts.poppins(
    fontSize: 18 * scaleFactor(context),
    fontWeight: FontWeight.w600,
    color: darkColor,
  );

  static TextStyle titleLarge(BuildContext context) => GoogleFonts.poppins(
    fontSize: 16 * scaleFactor(context),
    fontWeight: FontWeight.w600,
    color: darkColor,
  );

  static TextStyle titleMedium(BuildContext context) => GoogleFonts.poppins(
    fontSize: 14 * scaleFactor(context),
    fontWeight: FontWeight.w500,
    color: darkColor,
  );

  static TextStyle bodyLarge(BuildContext context) => GoogleFonts.poppins(
    fontSize: 14 * scaleFactor(context),
    fontWeight: FontWeight.w400,
    color: darkColor,
  );

  static TextStyle bodyMedium(BuildContext context) => GoogleFonts.poppins(
    fontSize: 12 * scaleFactor(context),
    fontWeight: FontWeight.w400,
    color: darkColor,
  );

  static TextStyle bodySmall(BuildContext context) => GoogleFonts.poppins(
    fontSize: 10 * scaleFactor(context),
    fontWeight: FontWeight.w400,
    color: darkColor.withOpacity(0.7),
  );

  static TextStyle buttonText(BuildContext context) => GoogleFonts.poppins(
    fontSize: 14 * scaleFactor(context),
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

// Main Profile Screen
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = FirebaseAuth.instance;
    final userUid = auth.currentUser?.uid;

    if (userUid == null) {
      return _buildUnauthorizedView(context);
    }

    // Replace this with your actual user info provider
    final userInfoAsync = ref.watch(userInfoProvider(userUid));

    return Scaffold(
      backgroundColor: UIConfig.lightColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(UIConfig.padding(context)),
              child: Column(
                children: [
                  SizedBox(height: 20 * UIConfig.scaleFactor(context)),
                  _buildUserProfileSection(context, userInfoAsync),
                  SizedBox(height: 20 * UIConfig.scaleFactor(context)),
                  _buildProfileMenuItems(context, auth),
                  SizedBox(height: 40 * UIConfig.scaleFactor(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthorizedView(BuildContext context) {
    return Scaffold(
      backgroundColor: UIConfig.lightColor,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(UIConfig.padding(context)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60 * UIConfig.scaleFactor(context),
                color: Colors.red[400],
              ),
              SizedBox(height: 20 * UIConfig.scaleFactor(context)),
              Text(
                'Not Authorized',
                style: UIConfig.titleLarge(context),
              ),
              SizedBox(height: 16 * UIConfig.scaleFactor(context)),
              Text(
                'Please login to view your profile',
                style: UIConfig.bodyMedium(context),
              ),
              SizedBox(height: 30 * UIConfig.scaleFactor(context)),
              ElevatedButton(
                onPressed: () => _handleUnauthorizedLoginRedirect(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: UIConfig.primaryColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: 32 * UIConfig.scaleFactor(context),
                    vertical: 16 * UIConfig.scaleFactor(context),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Go to Login',
                  style: UIConfig.buttonText(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUnauthorizedLoginRedirect(BuildContext context) async {
    try {
      final storage = const FlutterSecureStorage();
      await storage.write(key: 'login', value: 'false');
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error redirecting to login: ${e.toString()}',
              style: UIConfig.bodyMedium(context).copyWith(color: Colors.white),
            ),
            backgroundColor: UIConfig.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180 * UIConfig.scaleFactor(context),
      floating: true,
      pinned: true,
      elevation: UIConfig.cardElevation,
      backgroundColor: UIConfig.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [UIConfig.primaryColor, UIConfig.secondaryColor],
              stops: const [0.1, 0.9],
            ),
          ),
        ),
        title: Text(
          'My Profile',
          style: UIConfig.titleLarge(context).copyWith(
            color: Colors.white,
            fontSize: 22 * UIConfig.scaleFactor(context),
          ),
        ),
        centerTitle: true,
        titlePadding: EdgeInsets.only(
            bottom: 16 * UIConfig.scaleFactor(context)),
      ),
    );
  }

  Widget _buildUserProfileSection(
      BuildContext context, AsyncValue<DocumentSnapshot?> userInfoAsync) {
    return userInfoAsync.when(
      data: (userInfo) {
        if (userInfo == null || !userInfo.exists) {
          return _buildErrorCard(context, 'Profile data not found');
        }

        final data = userInfo.data() as Map<String, dynamic>? ?? {};
        return _buildProfileCard(context, data);
      },
      loading: () => _buildProfileShimmer(context),
      error: (error, _) => _buildErrorCard(context, error.toString()),
    );
  }

  Widget _buildProfileCard(BuildContext context, Map<String, dynamic> userData) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(
          horizontal: 16 * UIConfig.scaleFactor(context)),
      elevation: UIConfig.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(20 * UIConfig.scaleFactor(context)),
        child: Row(
          children: [
            Hero(
              tag: 'profile-avatar',
              child: Container(
                width: 80 * UIConfig.scaleFactor(context),
                height: 80 * UIConfig.scaleFactor(context),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: UIConfig.primaryColor,
                    width: 2,
                  ),
                  image: DecorationImage(
                    image: NetworkImage(
                      userData['photoUrl'] ??
                          'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(width: 20 * UIConfig.scaleFactor(context)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userData['name'] ?? 'No name provided',
                    style: UIConfig.titleLarge(context).copyWith(
                      fontSize: 18 * UIConfig.scaleFactor(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6 * UIConfig.scaleFactor(context)),
                  Text(
                    userData['email'] ?? 'No email provided',
                    style: UIConfig.bodyMedium(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8 * UIConfig.scaleFactor(context)),
                  if (userData['phone'] != null)
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 16 * UIConfig.scaleFactor(context),
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: 8 * UIConfig.scaleFactor(context)),
                        Text(
                          userData['phone'],
                          style: UIConfig.bodyMedium(context),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildProfileShimmer(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(
          horizontal: 16 * UIConfig.scaleFactor(context)),
      elevation: UIConfig.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(20 * UIConfig.scaleFactor(context)),
        child: Shimmer.fromColors(
          baseColor: UIConfig.shimmerBaseColor,
          highlightColor: UIConfig.shimmerHighlightColor,
          child: Row(
            children: [
              Container(
                width: 80 * UIConfig.scaleFactor(context),
                height: 80 * UIConfig.scaleFactor(context),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 20 * UIConfig.scaleFactor(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 150 * UIConfig.scaleFactor(context),
                      height: 20 * UIConfig.scaleFactor(context),
                      color: Colors.white,
                    ),
                    SizedBox(height: 10 * UIConfig.scaleFactor(context)),
                    Container(
                      width: 200 * UIConfig.scaleFactor(context),
                      height: 16 * UIConfig.scaleFactor(context),
                      color: Colors.white,
                    ),
                    SizedBox(height: 10 * UIConfig.scaleFactor(context)),
                    Container(
                      width: 120 * UIConfig.scaleFactor(context),
                      height: 16 * UIConfig.scaleFactor(context),
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String error) {
    return Card(
      margin: EdgeInsets.symmetric(
          horizontal: 16 * UIConfig.scaleFactor(context)),
      elevation: UIConfig.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(20 * UIConfig.scaleFactor(context)),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 40 * UIConfig.scaleFactor(context),
              color: Colors.red[400],
            ),
            SizedBox(height: 16 * UIConfig.scaleFactor(context)),
            Text(
              'Error loading profile',
              style: UIConfig.titleLarge(context),
            ),
            SizedBox(height: 8 * UIConfig.scaleFactor(context)),
            Text(
              error,
              style: UIConfig.bodyMedium(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuItems(BuildContext context, FirebaseAuth auth) {
    return Column(
      children: [
        _buildMenuItem(
          context,
          icon: Icons.account_circle,
          title: 'Account Settings',
          subtitle: 'Update your profile information',
          iconColor: UIConfig.primaryColor,
          onTap: () => _navigateTo(context, const AccountScreen()),
        ),
        _buildMenuItem(
          context,
          icon: Icons.calendar_today,
          title: 'Your Bookings',
          subtitle: 'View and manage your bookings',
          iconColor: Colors.blue.shade600,
          onTap: () => _navigateTo(context, const BookingScreen()),
        ),
        _buildMenuItem(
          context,
          icon: Icons.help_center,
          title: 'Help & Support',
          subtitle: 'Get help with any issues',
          iconColor: Colors.orange.shade600,
          onTap: () => _navigateTo(context, HelpSupportScreen()),
        ),
        _buildMenuItem(
          context,
          icon: Icons.privacy_tip,
          title: 'Privacy Policy',
          subtitle: 'Learn how we protect your data',
          iconColor: Colors.purple.shade600,
          onTap: () => _navigateTo(context, PrivacyPolicyScreen()),
        ),
        _buildMenuItem(
          context,
          icon: Icons.logout,
          title: 'Logout',
          subtitle: 'Sign out of your account',
          iconColor: Colors.red.shade600,
          onTap: () => _showLogoutConfirmation(context, auth),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color iconColor,
        required VoidCallback onTap,
      }) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(
        horizontal: 16 * UIConfig.scaleFactor(context),
        vertical: 8 * UIConfig.scaleFactor(context),
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16 * UIConfig.scaleFactor(context)),
          child: Row(
            children: [
              Container(
                width: 50 * UIConfig.scaleFactor(context),
                height: 50 * UIConfig.scaleFactor(context),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24 * UIConfig.scaleFactor(context),
                ),
              ),
              SizedBox(width: 16 * UIConfig.scaleFactor(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: UIConfig.titleMedium(context),
                    ),
                    SizedBox(height: 4 * UIConfig.scaleFactor(context)),
                    Text(
                      subtitle,
                      style: UIConfig.bodySmall(context),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
                size: 24 * UIConfig.scaleFactor(context),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.2);
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _showLogoutConfirmation(BuildContext context, FirebaseAuth auth) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: EdgeInsets.all(20 * UIConfig.scaleFactor(context)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.logout,
                size: 50 * UIConfig.scaleFactor(context),
                color: Colors.red.shade600,
              ),
              SizedBox(height: 20 * UIConfig.scaleFactor(context)),
              Text(
                'Logout Confirmation',
                style: UIConfig.titleLarge(context),
              ),
              SizedBox(height: 16 * UIConfig.scaleFactor(context)),
              Text(
                'Are you sure you want to logout?',
                textAlign: TextAlign.center,
                style: UIConfig.bodyMedium(context),
              ),
              SizedBox(height: 30 * UIConfig.scaleFactor(context)),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: UIConfig.darkColor,
                        padding: EdgeInsets.symmetric(
                            vertical: 16 * UIConfig.scaleFactor(context)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Cancel',
                        style: UIConfig.buttonText(context)
                            .copyWith(color: UIConfig.darkColor),
                      ),
                    ),
                  ),
                  SizedBox(width: 16 * UIConfig.scaleFactor(context)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _performLogout(context, auth),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            vertical: 16 * UIConfig.scaleFactor(context)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Logout',
                        style: UIConfig.buttonText(context),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performLogout(BuildContext context, FirebaseAuth auth) async {
    try {
      Navigator.pop(context);
      const storage = FlutterSecureStorage();
      await storage.write(key: 'login', value: 'false');
      await auth.signOut();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Logout failed: ${e.toString()}',
              style: UIConfig.bodyMedium(context),
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}


final userInfoProvider = FutureProvider.family<DocumentSnapshot?, String>((ref, userId) async {
  return FirebaseFirestore.instance.collection('users').doc(userId).get();
});