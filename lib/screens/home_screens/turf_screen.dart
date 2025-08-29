import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tb_web/screens/home_screens/profile_screen.dart';
import '../../turf_timeslots_booking_provider.dart';

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

  // Responsive scaling factor
  static double scaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return 0.85; // Small phones
    if (width < 400) return 0.95; // Medium phones
    return 1.0; // Large phones/tablets
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
        fontSize: 14 * scaleFactor(context),
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

class Turfscreen extends ConsumerStatefulWidget {
  const Turfscreen({super.key, required this.documentSnapshot});
  final DocumentSnapshot documentSnapshot;

  @override
  ConsumerState<Turfscreen> createState() => _TurfscreenState();
}

class _TurfscreenState extends ConsumerState<Turfscreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  late Razorpay _razorpay;
  DateTime today = DateTime.now();
  DateTime selectedDate = DateTime.now();
  String? selectedTimeSlot;
  final openingTime = const TimeOfDay(hour: 8, minute: 0);
  final closingTime = const TimeOfDay(hour: 18, minute: 0);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    tabController = TabController(length: 3, vsync: this);
    getUserData();
    tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (mounted) {
      setState(() {});
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    tabController.removeListener(_handleTabChange);
    tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String? _userEmail;
  String? _userMobile;

  Future<void> getUserData() async {
    final userUID = FirebaseAuth.instance.currentUser?.uid;
    if (userUID != null) {
      try {
        final userInfo = await ref.read(userInfoProvider(userUID).future);
        if (mounted) {
          setState(() {
            _userEmail = userInfo!['email'] as String?;
            _userMobile = userInfo['mobile'] as String?;
          });
        }
      } catch (e) {
        debugPrint("Error fetching user data: $e");
      }
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final totalAmount = widget.documentSnapshot['price'] as num;
      final commission = totalAmount * 0.05;
      final ownerAmount = totalAmount - commission;

      final args = {
        'document': widget.documentSnapshot,
        'timeSlot': selectedTimeSlot,
        'daySlot': DateFormat.EEEE().format(selectedDate),
        'monthSlot':
            "${DateFormat.d().format(selectedDate)} ${DateFormat.MMM().format(selectedDate)}",
        'transactionId': response.paymentId,
        'price': totalAmount,
        'commission': commission,
        'payout': ownerAmount,
        'status': 'Confirmed',
        'bookingDate': Timestamp.now(),
      };

      await ref.read(bookProvider(args).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking Successful',
              style: UIConfig.bodyMedium(context).copyWith(color: Colors.white),
            ),
            backgroundColor: UIConfig.successColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        debugPrint('Booking Failed: ${error.toString()}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking Failed: ${error.toString()}',
              style: UIConfig.bodyMedium(context).copyWith(color: Colors.white),
            ),
            backgroundColor: UIConfig.errorColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment Failed: ${response.message ?? 'Unknown error'}',
            style: UIConfig.bodyMedium(context).copyWith(color: Colors.white),
          ),
          backgroundColor: UIConfig.errorColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void openCheckout() {
    if (selectedTimeSlot == null || selectedTimeSlot!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a time slot',
            style: UIConfig.bodyMedium(context).copyWith(color: Colors.white),
          ),
          backgroundColor: UIConfig.warningColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final turfPrice =
        (widget.documentSnapshot['price'] as num?)?.toDouble() ?? 0.0;
    final platformFee = turfPrice * 0.015;
    final totalPrice = turfPrice + platformFee;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title:
              Text('Confirm Booking', style: UIConfig.headlineMedium(context)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Turf Price: ₹${turfPrice.toStringAsFixed(2)}',
                  style: UIConfig.bodyMedium(context)),
              const SizedBox(height: 8),
              Text('Platform Fee (1.5%): ₹${platformFee.toStringAsFixed(2)}',
                  style: UIConfig.bodyMedium(context)),
              const Divider(height: 24, thickness: 1),
              Text('Total Price: ₹${totalPrice.toStringAsFixed(2)}',
                  style: UIConfig.titleMedium(context)
                      .copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel',
                  style: UIConfig.buttonText(context)
                      .copyWith(color: UIConfig.primaryColor)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: UIConfig.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Confirm', style: UIConfig.buttonText(context)),
              onPressed: () {
                getUserData(); // Ensure user data is fetched
                Navigator.of(context).pop(); // Close the dialog
                var options = {
                  'key': 'rzp_live_2sz1yggylNC959',
                  'amount': (totalPrice * 100).toInt(), // Amount in paise
                  'name': 'Turf Buddie',
                  'description': '${widget.documentSnapshot['name']}',
                  'prefill': {
                    'contact': _userMobile ?? '',
                    'email': _userEmail ?? ''
                  },
                  'external': {
                    'wallets': ['paytm', 'phonepe']
                  },
                  'theme': {
                    'color': UIConfig.primaryColor.value.toRadixString(16)
                  },
                };
                debugPrint("mobile: $_userMobile, email: $_userEmail");

                try {
                  _razorpay.open(options);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error opening payment: ${e.toString()}',
                          style: UIConfig.bodyMedium(context)
                              .copyWith(color: Colors.white),
                        ),
                        backgroundColor: UIConfig.errorColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // void _initiatePayment(double totalAmount) {
  //   var options = {
  //     'key': 'rzp_test_1DP5mmOlF5G5ag', // Replace with your Key ID
  //     'amount': (totalAmount * 100).toInt(), // Amount in paise
  //     'name': 'Turf Buddie',
  //     'description': '${widget.documentSnapshot['name']}',
  //     'prefill': {'contact': '9876543210', 'email': 'test@example.com'}, // Prefill user details if available
  //     'external': {
  //       'wallets': ['paytm', 'phonepe'] // Enable specific wallets
  //     },
  //     'theme': {
  //       'color': UIConfig.primaryColor.value.toRadixString(16) // Theme color
  //     }
  //   };
  //
  //   try {
  //     _razorpay.open(options);
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(
  //             'Error opening payment: ${e.toString()}',
  //             style: UIConfig.bodyMedium(context).copyWith(color: Colors.white),
  //           ),
  //           backgroundColor: UIConfig.errorColor,
  //           behavior: SnackBarBehavior.floating,
  //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //           duration: const Duration(seconds: 3),
  //         ),
  //       );
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final availabilityAsync =
        ref.watch(turfAvailabilityProvider(widget.documentSnapshot.id));
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 350;
    final isMediumScreen = size.width < 400;

    return Scaffold(
      backgroundColor: UIConfig.lightColor,
      body: NestedScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: isSmallScreen
                ? 200
                : isMediumScreen
                    ? 230
                    : 250,
            floating: false,
            pinned: true,
            snap: false,
            stretch: true,
            elevation: 4,
            backgroundColor: UIConfig.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.blurBackground,
                StretchMode.fadeTitle
              ],
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildTurfImage(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.1),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
              titlePadding: EdgeInsets.only(
                left: isSmallScreen ? 12 : 16,
                bottom: isSmallScreen ? 12 : 16,
              ),
              title: Text(
                widget.documentSnapshot['name'] ?? 'Turf Buddie',
                style: UIConfig.headlineMedium(context).copyWith(
                  color: Colors.white,
                  shadows: [
                    const Shadow(
                      color: Colors.black45,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        body: Padding(
          padding: EdgeInsets.all(UIConfig.padding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTurfInfo(context),
              SizedBox(height: UIConfig.padding(context)),
              _buildTabBar(context, size, availabilityAsync),
            ],
          ).animate().fadeIn(duration: 500.ms),
        ),
      ),
      bottomNavigationBar:
          tabController.index == 0 ? _buildBookButton(context) : null,
    );
  }

  Widget _buildTurfImage() {
    return Hero(
      tag: 'turf-image-${widget.documentSnapshot.id}',
      child: CachedNetworkImage(
        imageUrl: widget.documentSnapshot['imageurl'] ??
            'https://via.placeholder.com/150',
        fit: BoxFit.cover,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: UIConfig.shimmerBaseColor,
          highlightColor: UIConfig.shimmerHighlightColor,
          child: Container(color: Colors.white),
        ),
        errorWidget: (context, url, error) => Center(
          child: Icon(
            Icons.image_not_supported,
            color: Colors.grey[400],
            size: 50,
          ),
        ),
      ),
    );
  }

  Widget _buildTurfInfo(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 350;

    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.documentSnapshot['name'] ?? 'Unnamed Turf',
                    style: UIConfig.titleLarge(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 12,
                    vertical: isSmallScreen ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: UIConfig.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '₹${widget.documentSnapshot['price']?.toString() ?? 'N/A'} / hr',
                    style: UIConfig.titleMedium(context).copyWith(
                      color: UIConfig.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: isSmallScreen ? 16 : 18,
                  color: UIConfig.primaryColor,
                ),
                SizedBox(width: isSmallScreen ? 4 : 6),
                Expanded(
                  child: Text(
                    widget.documentSnapshot['address'] ?? 'Unknown Location',
                    style: UIConfig.bodyMedium(context),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Row(
              children: [
                RatingBar.builder(
                  ignoreGestures: true,
                  itemSize: isSmallScreen ? 18 : 20,
                  allowHalfRating: true,
                  initialRating:
                      (widget.documentSnapshot['rating'] as num?)?.toDouble() ??
                          0.0,
                  itemCount: 5,
                  itemBuilder: (context, _) =>
                      const Icon(Icons.star, color: UIConfig.accentColor),
                  onRatingUpdate: (rating) {},
                ),
                SizedBox(width: isSmallScreen ? 4 : 8),
                Text(
                  '(${(widget.documentSnapshot['rating'] as num?)?.toStringAsFixed(1) ?? '0.0'})',
                  style: UIConfig.bodySmall(context),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildTabBar(BuildContext context, Size size,
      AsyncValue<List<dynamic>> availabilityAsync) {
    final isSmallScreen = size.width < 350;

    return Expanded(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: tabController,
              labelColor: UIConfig.primaryColor,
              unselectedLabelColor: Colors.grey[600],
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: UIConfig.primaryColor.withOpacity(0.1),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: GoogleFonts.poppins(
                fontSize: 14 * UIConfig.scaleFactor(context),
                fontWeight: FontWeight.w600,
              ),
              dividerHeight: 0,
              tabs: const [
                Tab(text: 'Book Slot'),
                Tab(text: 'Location'),
                Tab(text: 'Reviews'),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Expanded(
            child: TabBarView(
              controller: tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                availabilityAsync.when(
                  data: (availability) => _buildBookingTab(availability, size),
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: UIConfig.primaryColor,
                    ),
                  ),
                  error: (error, _) => _buildErrorWidget(error.toString()),
                ),
                _buildLocationTab(size),
                _buildReviewsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingTab(List<dynamic> availability, Size size) {
    final isSmallScreen = size.width < 350;
    String day = DateFormat.EEEE().format(selectedDate);
    String dateMonth =
        "${DateFormat.d().format(selectedDate)} ${DateFormat.MMM().format(selectedDate)}";

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Date',
            style: UIConfig.titleLarge(context),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          SizedBox(
            height: isSmallScreen ? 100 : 110,
            child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: 8,
              itemBuilder: (context, index) {
                DateTime currentDate = today.add(Duration(days: index));
                bool isSelected = selectedDate.day == currentDate.day &&
                    selectedDate.month == currentDate.month &&
                    selectedDate.year == currentDate.year;
                return _buildDateCard(currentDate, isSelected);
              },
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            'Available Time Slots',
            style: UIConfig.titleLarge(context),
          ),
          SizedBox(height: isSmallScreen ? 4 : 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount:
                getAvailableTimeSlots(availability, day, dateMonth).length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: isSmallScreen ? 2.5 : 3,
              mainAxisSpacing: isSmallScreen ? 8 : 12,
              crossAxisSpacing: isSmallScreen ? 8 : 12,
            ),
            itemBuilder: (context, index) {
              String slot =
                  getAvailableTimeSlots(availability, day, dateMonth)[index];
              bool isSelected = selectedTimeSlot == slot;
              return _buildTimeSlotCard(slot, isSelected);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard(DateTime currentDate, bool isSelected) {
    final isSmallScreen = MediaQuery.of(context).size.width < 350;

    return GestureDetector(
      onTap: () {
        if (mounted) {
          setState(() {
            selectedDate = currentDate;
            selectedTimeSlot = null;
          });
        }
      },
      child: Container(
        width: isSmallScreen ? 70 : 80,
        height: isSmallScreen ? 90 : 100,
        margin: EdgeInsets.only(right: isSmallScreen ? 8 : 12),
        decoration: BoxDecoration(
          color: isSelected ? UIConfig.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat.E().format(currentDate),
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 10 : 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : UIConfig.darkColor,
              ),
            ),
            SizedBox(height: isSmallScreen ? 2 : 4),
            Text(
              DateFormat.d().format(currentDate),
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 18 : 22,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : UIConfig.darkColor,
              ),
            ),
            Text(
              DateFormat.MMM().format(currentDate),
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 9 : 11,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : UIConfig.darkColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotCard(String slot, bool isSelected) {
    final isSmallScreen = MediaQuery.of(context).size.width < 350;

    return GestureDetector(
      onTap: () {
        if (mounted) {
          setState(() => selectedTimeSlot = slot);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? UIConfig.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.1 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
          border: isSelected
              ? Border.all(
                  color: UIConfig.primaryColor.withOpacity(0.3), width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            slot,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 11 : 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : UIConfig.darkColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationTab(Size size) {
    final location = widget.documentSnapshot['location'] as GeoPoint?;
    if (location == null) {
      return _buildErrorWidget('Location data unavailable');
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Turf Location',
            style: UIConfig.titleLarge(context),
          ),
          SizedBox(height: UIConfig.padding(context)),
          Container(
            height: size.height * 0.28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(location.latitude, location.longitude),
                  initialZoom: 15.0,
                  interactionOptions: const InteractionOptions(
                    flags: ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.turfbuddie.tb_app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 50.0,
                        height: 50.0,
                        point: LatLng(location.latitude, location.longitude),
                        child: Icon(
                          Icons.location_on,
                          color: Colors.redAccent,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: UIConfig.padding(context)),
          Text(
            'Address',
            style: UIConfig.titleLarge(context),
          ),
          SizedBox(height: UIConfig.padding(context) / 2),
          Text(
            widget.documentSnapshot['address'] ?? 'Address not available',
            style: UIConfig.bodyMedium(context),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Column(
      children: [
        Text(
          'Customer Reviews',
          style: UIConfig.titleLarge(context),
        ),
        SizedBox(height: UIConfig.padding(context)),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.reviews_outlined,
                  size: 50,
                  color: Colors.grey[400],
                ),
                SizedBox(height: UIConfig.padding(context)),
                Text(
                  'No reviews yet',
                  style: UIConfig.titleMedium(context),
                ),
                SizedBox(height: UIConfig.padding(context) / 2),
                Text(
                  'Be the first to review this turf!',
                  style: UIConfig.bodySmall(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookButton(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 350;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: UIConfig.padding(context),
          vertical: isSmallScreen ? 8 : 12,
        ),
        child: ElevatedButton(
          onPressed: openCheckout,
          style: ElevatedButton.styleFrom(
            backgroundColor: UIConfig.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: Size.fromHeight(isSmallScreen ? 45 : 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: isSmallScreen ? 18 : 20),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Text(
                'Book Now',
                style: UIConfig.buttonText(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: UIConfig.errorColor, size: 50),
          SizedBox(height: UIConfig.padding(context)),
          Text(
            'Something went wrong',
            style: UIConfig.titleLarge(context),
          ),
          SizedBox(height: UIConfig.padding(context) / 2),
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: UIConfig.padding(context)),
            child: Text(
              message,
              style: UIConfig.bodyMedium(context),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: UIConfig.padding(context)),
          ElevatedButton(
            onPressed: () {
              if (mounted) {
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: UIConfig.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Try Again',
              style: UIConfig.buttonText(context),
            ),
          ),
        ],
      ),
    );
  }

  List<String> getAvailableTimeSlots(
      List<dynamic> availability, String day, String dateMonth) {
    List<String> timeSlots = [];
    TimeOfDay currentTime = TimeOfDay.now();

    for (int hour = openingTime.hour; hour < closingTime.hour; hour++) {
      TimeOfDay startTime = TimeOfDay(hour: hour, minute: 0);
      TimeOfDay endTime = TimeOfDay(hour: hour + 1, minute: 0);
      String formattedSlot =
          "${formatTimeOfDay(startTime)} - ${formatTimeOfDay(endTime)}";

      // Skip past time slots for today
      if (selectedDate.day == today.day &&
          selectedDate.month == today.month &&
          selectedDate.year == today.year) {
        if (hour < currentTime.hour ||
            (hour == currentTime.hour && currentTime.minute > 0)) {
          continue;
        }
      }

      // Check if slot is already booked
      bool isBooked = availability.any((booking) =>
          booking['timeSlot'] == formattedSlot &&
          booking['daySlot'] == day &&
          booking['monthSlot'] == dateMonth &&
          (booking['status'] == 'confirmed' ||
              booking['status'] == 'pending' ||
              booking['status'] == 'booked_offline'));

      if (!isBooked) {
        timeSlots.add(formattedSlot);
      }
    }
    return timeSlots;
  }

  String formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
    final period = timeOfDay.period == DayPeriod.am ? "AM" : "PM";
    return "$hour $period";
  }

  bool isTurfOpen() {
    if (selectedDate.day == today.day &&
        selectedDate.month == today.month &&
        selectedDate.year == today.year) {
      TimeOfDay currentTime = TimeOfDay.now();
      return currentTime.hour >= openingTime.hour &&
          currentTime.hour < closingTime.hour;
    }
    return true;
  }
}
