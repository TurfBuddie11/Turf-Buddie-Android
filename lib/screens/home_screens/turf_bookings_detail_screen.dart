import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../riverpod_providers/turf_bookings_provider.dart';
import 'home_screen.dart' as ui;

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

  // Responsive scaling factor
  static double scaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return 0.85; // Small phones
    if (width < 400) return 0.95; // Medium phones
    return 1.0; // Large phones/tablets
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
        color: darkColor.withValues(alpha: 0.7),
      );
}

class TurfBookingDetailsScreen extends ConsumerWidget {
  final Booking booking;

  const TurfBookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turfLocation =
        LatLng(booking.location.latitude, booking.location.longitude);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: UIConfig.lightColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(ui.UIConfig.defaultPadding(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTurfImage(size, context),
                  SizedBox(height: ui.UIConfig.defaultPadding(context)),
                  _buildTurfInfo(context),
                  SizedBox(height: ui.UIConfig.defaultPadding(context) * 1.5),
                  _buildBookingDetails(context),
                  SizedBox(height: ui.UIConfig.defaultPadding(context) * 1.5),
                  _buildLocationMap(turfLocation, size, context),
                  SizedBox(height: ui.UIConfig.defaultPadding(context) * 1.5),
                  if (booking.status == 'confirmed')
                    _buildActionButtons(context, ref),
                  SizedBox(height: size.height * 0.05),
                ],
              ).animate().fadeIn(duration: 500.ms),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 180,
      floating: true,
      pinned: true,
      elevation: ui.UIConfig.cardElevation,
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
        titlePadding: EdgeInsets.only(
            left: ui.UIConfig.defaultPadding(context), bottom: 16),
        title: Text(
          booking.turfName,
          style: ui.UIConfig.titleStyle(context).copyWith(color: Colors.white),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildTurfImage(Size size, BuildContext context) {
    return Hero(
      tag: 'turf-image-${booking.id}',
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(ui.UIConfig.cardBorderRadius(context)),
        child: SizedBox(
          width: double.infinity,
          height: size.height * 0.25,
          child: CachedNetworkImage(
            imageUrl: booking.turfImage,
            fit: BoxFit.cover,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: ui.UIConfig.shimmerBaseColor,
              highlightColor: ui.UIConfig.shimmerHighlightColor,
              child: Container(color: Colors.white),
            ),
            errorWidget: (context, url, error) => Center(
              child: Icon(Icons.image_not_supported,
                  color: Colors.grey[400], size: 50),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildTurfInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(ui.UIConfig.cardBorderRadius(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  booking.turfName,
                  style: ui.UIConfig.titleStyle(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(booking.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking.status.toUpperCase(),
                  style: ui.UIConfig.buttonStyle(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 18, color: UIConfig.primaryColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  booking.address,
                  style: ui.UIConfig.subtitleStyle(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.star, size: 18, color: UIConfig.accentColor),
              const SizedBox(width: 4),
              Text(
                booking.rating.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: UIConfig.darkColor,
                ),
              ),
              const SizedBox(width: 20),
              Icon(Icons.currency_rupee,
                  size: 18, color: UIConfig.primaryColor),
              const SizedBox(width: 4),
              Text(
                booking.price.toStringAsFixed(0),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: UIConfig.darkColor,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 100.ms);
  }

  Widget _buildBookingDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(ui.UIConfig.cardBorderRadius(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Details',
            style: ui.UIConfig.titleStyle(context),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: 'Date',
            value: '${booking.daySlot}, ${booking.monthSlot}',
          ),
          _buildDetailRow(
            icon: Icons.access_time,
            label: 'Time Slot',
            value: booking.timeSlot,
          ),
          _buildDetailRow(
            icon: Icons.receipt,
            label: 'Transaction ID',
            value: booking.transactionId,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms);
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: UIConfig.primaryColor),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: UIConfig.darkColor.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: UIConfig.darkColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMap(LatLng location, Size size, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: ui.UIConfig.titleStyle(context),
        ),
        const SizedBox(height: 12),
        Container(
          height: size.height * 0.3,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(ui.UIConfig.cardBorderRadius(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(ui.UIConfig.cardBorderRadius(context)),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: location,
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags: ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  maxZoom: 19,
                  userAgentPackageName: 'com.turfbuddie.app',
                  additionalOptions: const {
                    'attribution': '© OpenStreetMap contributors © CARTO',
                  },
                  fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  // Error handling for failed tiles
                  errorImage: const NetworkImage(
                      'https://via.placeholder.com/256x256.png?text=Map+Error'),
                ),
                // Alternative: Use Stamen Terrain (also free)
                // TileLayer(
                //   urlTemplate: 'https://stamen-tiles-{s}.a.ssl.fastly.net/terrain/{z}/{x}/{y}.png',
                //   subdomains: const ['a', 'b', 'c', 'd'],
                //   maxZoom: 18,
                //   userAgentPackageName: 'com.turfbuddie.app',
                // ),

                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40.0,
                      height: 40.0,
                      point: location,
                      child: Icon(
                        Icons.location_on_rounded,
                        color: Colors.red[600]!,
                        size: 23.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.directions, size: 20),
            label:
                Text('Open in Maps', style: ui.UIConfig.buttonStyle(context)),
            style: ElevatedButton.styleFrom(
              backgroundColor: UIConfig.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: ui.UIConfig.cardElevation,
            ),
            onPressed: () => _launchMaps(location, context),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 300.ms);
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: ui.UIConfig.cardElevation,
            ),
            onPressed: () =>
                _showCancelConfirmationDialog(context, ref, booking),
            child: Text(
              'Cancel Booking',
              style: ui.UIConfig.buttonStyle(context),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: UIConfig.primaryColor.withValues(alpha: 0.1),
              foregroundColor: UIConfig.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: UIConfig.primaryColor, width: 1.5),
              ),
              elevation: 0,
            ),
            onPressed: () {
              // Implement contact support functionality
            },
            child: Text(
              'Contact Support',
              style: ui.UIConfig.buttonStyle(context).copyWith(
                color: UIConfig.primaryColor,
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 400.ms);
  }

  Future<void> _showCancelConfirmationDialog(
      BuildContext context, WidgetRef ref, Booking booking) async {
    final refundDetails = await _calculateRefundDetails(booking);

    if (!context.mounted) return;
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final scale = UIConfig.scaleFactor(context);

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20 * scale),
          ),
          child: Container(
            padding: EdgeInsets.all(20 * scale),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade700,
                        size: 28 * scale,
                      ),
                      SizedBox(width: 10 * scale),
                      Flexible(
                        child: Text(
                          'Cancel Booking Confirmation',
                          style: UIConfig.titleLarge(context),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20 * scale),

                  // Booking Details
                  _buildInfoRow(
                    context,
                    icon: Icons.location_on,
                    label: 'Turf:',
                    value: booking.turfName,
                  ),
                  _buildInfoRow(
                    context,
                    icon: Icons.access_time,
                    label: 'Time Slot:',
                    value: booking.timeSlot,
                  ),
                  _buildInfoRow(
                    context,
                    icon: Icons.calendar_today,
                    label: 'Date:',
                    value: '${booking.daySlot}, ${booking.monthSlot}',
                  ),

                  Divider(height: 30 * scale, thickness: 1),

                  // Refund Details
                  _buildAmountRow(
                    context,
                    label: 'Original Amount:',
                    value: '₹${refundDetails['originalAmount']}',
                  ),
                  _buildAmountRow(
                    context,
                    label:
                        'Deducted Amount (${refundDetails['deductionPercentage']}%):',
                    value: '-₹${refundDetails['deductedAmount']}',
                    color: Colors.red.shade600,
                  ),
                  _buildAmountRow(
                    context,
                    label: 'Refund Amount:',
                    value: '₹${refundDetails['refundAmount']}',
                    color: Colors.green.shade600,
                  ),

                  Divider(height: 30 * scale, thickness: 1),

                  // Policy Info
                  Text(
                    'Refund Policy:',
                    style: UIConfig.titleMedium(context),
                  ),
                  SizedBox(height: 5 * scale),
                  Text(
                    '• 24 hrs before: 100% refund\n'
                    '• 6 hrs before: 50% refund\n'
                    '• Less than 6 hrs: No Refund',
                    style: UIConfig.bodySmall(context),
                  ),

                  SizedBox(height: 20 * scale),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          padding: EdgeInsets.symmetric(
                            horizontal: 20 * scale,
                            vertical: 10 * scale,
                          ),
                        ),
                        child: Text(
                          'Go Back',
                          style: UIConfig.bodyMedium(context).copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 10 * scale),
                      ElevatedButton(
                        onPressed: () async {
                          await _cancelBooking(ref, context);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 20 * scale,
                            vertical: 10 * scale,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10 * scale),
                          ),
                        ),
                        child: Text(
                          'Confirm Cancel',
                          style: UIConfig.bodyMedium(context).copyWith(
                            fontWeight: FontWeight.w500,
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
      },
    );
  }

  // Helper widget for info rows
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final scale = UIConfig.scaleFactor(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20 * scale,
            color: Colors.grey.shade600,
          ),
          SizedBox(width: 10 * scale),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: UIConfig.bodyMedium(context).copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2 * scale),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: Text(
                  value,
                  style: UIConfig.bodyMedium(context),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper widget for amount rows
  Widget _buildAmountRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? color,
  }) {
    final scale = UIConfig.scaleFactor(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6 * scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: UIConfig.bodyMedium(context),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: UIConfig.bodyMedium(context).copyWith(
              color: color ?? UIConfig.darkColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to calculate refund details
  Future<Map<String, dynamic>> _calculateRefundDetails(Booking booking) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('Turfs')
          .doc(booking.turfId)
          .get();

      if (!snapshot.exists) throw Exception("Turf not found");

      Map<String, dynamic> turfData = snapshot.data() as Map<String, dynamic>;
      List<Map<String, dynamic>> timeSlots =
          List<Map<String, dynamic>>.from(turfData['timeSlots'] ?? []);

      for (var slot in timeSlots) {
        if (slot['transactionId'] == booking.transactionId) {
          String timeSlotString = slot['timeSlot'] ?? '';
          String startTimeString = timeSlotString.split('-')[0].trim();
          DateTime bookingDateTime = _parseBookingDateTime(
              booking.monthSlot, booking.daySlot, startTimeString);
          Duration difference = bookingDateTime.difference(DateTime.now());
          double totalAmount = booking.price;
          double refundAmount = 0;
          String deductionPercentage = '0';

          if (difference.inHours >= 24) {
            refundAmount = totalAmount; // 100% refund
            deductionPercentage = '0';
          } else if (difference.inHours >= 6) {
            refundAmount = totalAmount * 0.5;
            deductionPercentage = '50';
          } // else no refund, deductionPercentage remains '0' and refundAmount remains 0

          return {
            'originalAmount': totalAmount.toStringAsFixed(2),
            'refundAmount': refundAmount.toStringAsFixed(2),
            'deductedAmount': (totalAmount - refundAmount).toStringAsFixed(2),
            'deductionPercentage': deductionPercentage,
          };
        }
      }
      throw Exception("Booking not found");
    } catch (e) {
      return {
        'originalAmount': booking.price.toStringAsFixed(2),
        'refundAmount': '0.00',
        'deductedAmount': booking.price.toStringAsFixed(2),
        'deductionPercentage': '100',
      };
    }
  }

  Future<void> _cancelBooking(WidgetRef ref, BuildContext context) async {
    try {
      DocumentReference turfRef =
          FirebaseFirestore.instance.collection('Turfs').doc(booking.turfId);
      DocumentSnapshot snapshot = await turfRef.get();

      if (!snapshot.exists) {
        throw Exception("Turf not found");
      }

      Map<String, dynamic> turfData = snapshot.data() as Map<String, dynamic>;
      List<Map<String, dynamic>> timeSlots =
          List<Map<String, dynamic>>.from(turfData['timeSlots'] ?? []);

      bool updated = false;
      double refundAmount = 0;
      String refundStatus = 'no refund';

      for (int i = 0; i < timeSlots.length; i++) {
        if (timeSlots[i]['transactionId'] == booking.transactionId) {
          String timeSlotString = timeSlots[i]['timeSlot'] ?? '';
          String daySlot = timeSlots[i]['daySlot'] ?? '';
          String monthSlot = timeSlots[i]['monthSlot'] ?? '';

          if (timeSlotString.isEmpty || daySlot.isEmpty || monthSlot.isEmpty) {
            throw Exception("Booking details incomplete");
          }

          // Parse the start time from timeSlot (e.g., "1 PM" from "1 PM - 2 PM")
          String startTimeString = timeSlotString.split('-')[0].trim();

          // Create the booking DateTime by combining monthSlot, daySlot and timeSlot
          DateTime bookingDateTime =
              _parseBookingDateTime(monthSlot, daySlot, startTimeString);
          DateTime now = DateTime.now();

          // Calculate difference between now and booking time
          Duration difference = bookingDateTime.difference(now);
          double totalAmount = booking.price;

          if (difference.inHours >= 24) {
            refundAmount = totalAmount;
            refundStatus = '100% refund (0% deduction)';
          } else if (difference.inHours >= 6 && difference.inHours < 24) {
            refundAmount = totalAmount * 0.5;
            refundStatus = '50% refund';
          } else {
            refundAmount = 0;
            refundStatus =
                'no refund (cancelled within 6 hours or booking time passed)';
          }

          timeSlots[i] = {
            ...timeSlots[i],
            'status': 'cancelled',
            'cancelledAt': Timestamp.now(),
            'refundStatus': refundStatus,
            'payout': refundAmount * 0.15,
            'originalAmount': totalAmount,
            'refundAmount': refundAmount,
            'deductedAmount': totalAmount - refundAmount,
            'paid': 'Not Paid to Owner'
          };
          updated = true;
          break;
        }
      }

      if (!updated) {
        throw Exception("Booking not found in timeSlots");
      }

      await turfRef.update({
        'timeSlots': timeSlots,
      });

      ref.invalidate(bookingProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking cancelled successfully. $refundStatus',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: UIConfig.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        debugPrint(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error cancelling booking: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // Helper function to parse monthSlot, daySlot and timeSlot into DateTime
  DateTime _parseBookingDateTime(
      String monthSlot, String daySlot, String timeString) {
    try {
      // Parse month and day (e.g., "1 Apr" -> day = 1, month = 4)
      List<String> monthParts = monthSlot.split(' ');
      int day = int.tryParse(monthParts[0]) ?? 1;
      int month = _monthToNumber(monthParts.length > 1 ? monthParts[1] : '');

      // Parse time (e.g., "1 PM" -> hour = 13)
      bool isPM = timeString.toLowerCase().contains('pm');
      String hourString = timeString.replaceAll(RegExp(r'[^0-9]'), '');
      int hour = int.tryParse(hourString) ?? 0;

      // Convert to 24-hour format
      if (isPM && hour < 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;

      // Get current year (assuming booking is for current year)
      int year = DateTime.now().year;

      // Validate day of week matches
      DateTime tentativeDate = DateTime(year, month, day);
      if (_dayToFullString(tentativeDate.weekday) != daySlot.toLowerCase()) {
        throw Exception("Day of week doesn't match date");
      }

      return DateTime(year, month, day, hour, 0);
    } catch (e) {
      throw Exception("Failed to parse booking date: ${e.toString()}");
    }
  }

  int _monthToNumber(String month) {
    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12
    };
    return months[month.toLowerCase().substring(0, 3)] ?? 1;
  }

  String _dayToFullString(int weekday) {
    const days = [
      'sunday',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday'
    ];
    return days[weekday % 7];
  }

  Future<void> _launchMaps(LatLng location, BuildContext context) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        throw 'Could not launch maps';
      }
    } catch (e) {
      debugPrint('Error launching maps: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to open maps: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return UIConfig.primaryColor;
      case 'cancelled':
        return Colors.red[600]!;
      case 'previous':
        return Colors.grey[600]!;
      default:
        return UIConfig.secondaryColor;
    }
  }
}
