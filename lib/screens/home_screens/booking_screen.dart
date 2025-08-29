import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tb_web/screens/home_screens/turf_bookings_detail_screen.dart';
import '../../riverpod_providers/turf_bookings_provider.dart';

class UIConfig {
  // Responsive scaling factor
  static double scaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return 0.70;  // Small phones
    if (width < 400) return 0.8;  // Medium phones
    if (width < 600) return 1.0;   // Large phones
    return 1.1;                    // Tablets
  }

  // Responsive padding
  static double padding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return 12.0;
    if (width < 400) return 16.0;
    return 20.0;
  }

  // Card border radius
  static double cardBorderRadius(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < 400 ? 12.0 : 16.0;
  }

  // Text Styles
  static TextStyle headlineLarge(BuildContext context) => GoogleFonts.poppins(
    fontSize: 20 * scaleFactor(context),
    fontWeight: FontWeight.w700,
    color: Colors.black,
  );

  static TextStyle headlineMedium(BuildContext context) => GoogleFonts.poppins(
    fontSize: 16 * scaleFactor(context),
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  static TextStyle titleLarge(BuildContext context) => GoogleFonts.poppins(
    fontSize: 14 * scaleFactor(context),
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  static TextStyle titleMedium(BuildContext context) => GoogleFonts.poppins(
    fontSize: 11 * scaleFactor(context),
    fontWeight: FontWeight.w500,
    color: Colors.black,
  );

  static TextStyle bodyLarge(BuildContext context) => GoogleFonts.poppins(
    fontSize: 12 * scaleFactor(context),
    fontWeight: FontWeight.w400,
    color: Colors.black,
  );

  static TextStyle bodyMedium(BuildContext context) => GoogleFonts.poppins(
    fontSize: 10 * scaleFactor(context),
    fontWeight: FontWeight.w400,
    color: Colors.black,
  );

  static TextStyle bodySmall(BuildContext context) => GoogleFonts.poppins(
    fontSize: 9 * scaleFactor(context),
    fontWeight: FontWeight.w400,
    color: Colors.black.withOpacity(0.7),
  );

  static TextStyle buttonText(BuildContext context) => GoogleFonts.poppins(
    fontSize: 12 * scaleFactor(context),
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 350;
    final isMediumScreen = MediaQuery.of(context).size.width < 400;
    final bookingsAsync = ref.watch(bookingProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(UIConfig.padding(context)),
              child: _buildFilterChips(context),
            ),
          ),
          bookingsAsync.when(
            data: (bookings) => _buildBookingList(context, bookings),
            loading: () => _buildShimmerLoading(context),
            error: (error, stack) => _buildErrorWidget(context, error),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 350;
    final isMediumScreen = MediaQuery.of(context).size.width < 400;

    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: isSmallScreen ? 180 : isMediumScreen ? 200 : 220,
      floating: false,
      pinned: true,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(
          left: UIConfig.padding(context),
          bottom: isSmallScreen ? 12 : 16,
        ),
        title: Text(
          'My Bookings',
          style: UIConfig.headlineMedium(context).copyWith(
            color: Colors.white,
            shadows: [const Shadow(color: Colors.black45, blurRadius: 4)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/logo/booking_logo.jpg',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.refresh,
            color: Colors.white,
            size: isSmallScreen ? 22 : 24,
          ),
          onPressed: () => ref.refresh(bookingProvider),
        ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 350;
    final filters = ['all', 'confirmed', 'cancelled', 'previous'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) => Padding(
          padding: EdgeInsets.only(right: isSmallScreen ? 6.0 : 8.0),
          child: FilterChip(
            label: Text(
              filter.capitalize(),
              style: UIConfig.bodyMedium(context).copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            selected: selectedFilter == filter,
            onSelected: (selected) {
              setState(() {
                selectedFilter = filter;
                _controller.forward(from: 0);
              });
            },
            selectedColor: Colors.blue.shade200,
            checkmarkColor: Colors.blue.shade900,
            backgroundColor: Colors.grey.shade200,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 2,
          ),
        )).toList(),
      ),
    );
  }

  SliverList _buildBookingList(BuildContext context, List<Booking> bookings) {
    final isSmallScreen = MediaQuery.of(context).size.width < 350;
    final filteredBookings = selectedFilter == 'all'
        ? bookings
        : bookings.where((booking) => booking.status == selectedFilter).toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final booking = filteredBookings[index];
          return FadeTransition(
            opacity: _controller,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
                  .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
              child: _buildBookingCard(context, booking),
            ),
          );
        },
        childCount: filteredBookings.length,
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking) {
    final isSmallScreen = MediaQuery.of(context).size.width < 350;
    final isMediumScreen = MediaQuery.of(context).size.width < 400;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TurfBookingDetailsScreen(booking: booking),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(
          horizontal: UIConfig.padding(context),
          vertical: isSmallScreen ? 6 : 8,
        ),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConfig.cardBorderRadius(context)),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(UIConfig.cardBorderRadius(context)),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: booking.turfImage,
                    width: isSmallScreen ? 90 : isMediumScreen ? 100 : 110,
                    height: isSmallScreen ? 90 : isMediumScreen ? 100 : 110,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        color: Colors.grey[300],
                        width: isSmallScreen ? 90 : isMediumScreen ? 100 : 110,
                        height: isSmallScreen ? 90 : isMediumScreen ? 100 : 110,
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.error,
                      size: isSmallScreen ? 30 : 40,
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.address,
                        style: UIConfig.titleMedium(context).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 6),
                      Text(
                        '${booking.daySlot}, ${booking.timeSlot} - ${booking.monthSlot}',
                        style: UIConfig.bodySmall(context).copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 6),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: isSmallScreen ? 14 : 16,
                            color: Colors.amber,
                          ),
                          SizedBox(width: isSmallScreen ? 2 : 4),
                          Text(
                            '${booking.rating}',
                            style: UIConfig.bodySmall(context).copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 6),
                      Text(
                        '₹${booking.price}',
                        style: UIConfig.titleMedium(context).copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 6),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 8 : 10,
                              vertical: isSmallScreen ? 2 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(booking.status),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              booking.status.capitalize(),
                              style: UIConfig.bodySmall(context).copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 4 : 8),
                          Expanded(
                            child: Text(
                              'Txn: ${booking.transactionId}',
                              style: UIConfig.bodySmall(context).copyWith(
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverList _buildShimmerLoading(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 350;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
          padding: EdgeInsets.symmetric(
            horizontal: UIConfig.padding(context),
            vertical: isSmallScreen ? 6 : 8,
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UIConfig.cardBorderRadius(context)),
              ),
              child: SizedBox(
                height: isSmallScreen ? 110 : 130,
                width: double.infinity,
              ),
            ),
          ),
        ),
        childCount: 5,
      ),
    );
  }

  SliverFillRemaining _buildErrorWidget(BuildContext context, Object error) {
    final isSmallScreen = MediaQuery.of(context).size.width < 350;

    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(UIConfig.padding(context)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: isSmallScreen ? 50 : 60,
                color: Colors.redAccent,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Text(
                'Oops! Something went wrong',
                style: UIConfig.titleLarge(context).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              Text(
                'Error: $error',
                style: UIConfig.bodyMedium(context).copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 20 : 24,
                    vertical: isSmallScreen ? 10 : 12,
                  ),
                ),
                onPressed: () => ref.refresh(bookingProvider),
                child: Text(
                  'Retry',
                  style: UIConfig.buttonText(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green.shade600;
      case 'cancelled':
        return Colors.red.shade600;
      case 'previous':
        return Colors.grey.shade600;
      default:
        return Colors.blue.shade600;
    }
  }
}

extension StringExtension on String {
  String capitalize() => "${this[0].toUpperCase()}${substring(1)}";
}