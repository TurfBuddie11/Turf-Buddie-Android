import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sizer/sizer.dart';
import 'package:tb_web/riverpod_providers/current_city_provider.dart';
import 'package:tb_web/riverpod_providers/nearby_turfs_provider.dart';
import 'package:tb_web/riverpod_providers/top_turfs_provider.dart';
import 'package:tb_web/screens/home_screens/turf_screen.dart';
import '../../riverpod_providers/current_locatioin_provider.dart';

class UIConfig {
  static const Color primaryColor = Color(0xFF00A859);
  static const Color secondaryColor = Color(0xFF00C853);
  static const Color accentColor = Color(0xFFFFD600);
  static const Color darkColor = Color(0xFF263238);
  static const Color lightColor = Color(0xFFECEFF1);
  static const Color shimmerBaseColor = Color(0xFFE0E0E0);
  static const Color shimmerHighlightColor = Color(0xFFFAFAFA);

  static double defaultPadding(BuildContext context) => 4.w;

  static double cardBorderRadius(BuildContext context) => 4.w;

  static const double cardElevation = 6.0;

  static TextStyle titleStyle(BuildContext context) => GoogleFonts.poppins(
        fontSize: 17.sp,
        fontWeight: FontWeight.w700,
        color: darkColor,
      );

  static TextStyle subtitleStyle(BuildContext context) => GoogleFonts.poppins(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: darkColor.withValues(alpha: 0.7),
      );

  static TextStyle buttonStyle(BuildContext context) => GoogleFonts.poppins(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _logger = Logger();

  Future<void> _refreshData() async {
    try {
      // Invalidate all providers to trigger a refresh
      ref.invalidate(currentCityProvider);
      ref.invalidate(locationProvider);
      ref.invalidate(topTurfProvider);
      ref.invalidate(nearbyTurfsProvider);

      // Wait for currentCityProvider and locationProvider to resolve
      final locationResult = await ref.read(locationProvider.future);
      final cityResult = await ref.read(currentCityProvider.future);

      // Use the resolved location to access topTurfProvider and nearbyTurfsProvider
      if (locationResult != null) {
        await Future.wait([
          Future.value(cityResult), // Already resolved, wrapped for Future.wait
          Future.value(
              locationResult), // Already resolved, wrapped for Future.wait
          ref.read(topTurfProvider(locationResult).future),
          ref.read(nearbyTurfsProvider(locationResult).future),
        ]);
      } else {
        _logger.w('Location is null, skipping turf providers refresh');
      }
    } catch (e, stackTrace) {
      _logger.e('Error refreshing data', error: e, stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIConfig.lightColor,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: UIConfig.primaryColor,
        displacement: 4.h,
        edgeOffset: UIConfig.defaultPadding(context),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 2.h),
                  _buildSearchBar(context),
                  SizedBox(height: 1.h),
                  _buildSectionTitle(context, 'Top Rated Turfs'),
                  _buildTopTurfsSection(context),
                  SizedBox(height: 1.h),
                  _buildSectionTitle(context, 'Turfs Near You'),
                  _buildNearbyTurfsSection(context),
                  SizedBox(height: 5.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    final currentCityAsync = ref.watch(currentCityProvider);

    return SliverAppBar(
      expandedHeight: 20.h,
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
        titlePadding: EdgeInsets.only(left: 4.w, bottom: 2.h),
        title: Align(
          alignment: Alignment.bottomLeft,
          child: currentCityAsync.when(
            data: (city) => _buildLocationHeader(context, city),
            loading: () => _buildShimmerLocationHeader(context),
            error: (error, _) {
              _logger.e('Error loading city', error: error);
              return _buildErrorWidget(context, 'Failed to load location',
                  onRetry: () => ref.refresh(currentCityProvider));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLocationHeader(BuildContext context, String city) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Location',
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 0.2.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(Icons.location_on, color: Colors.white, size: 14.sp),
            SizedBox(width: 1.w),
            Text(
              city,
              style: GoogleFonts.poppins(
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildShimmerLocationHeader(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.3),
      highlightColor: Colors.white.withValues(alpha: 0.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20.w,
            height: 10.sp,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Container(
                width: 14.sp,
                height: 14.sp,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                width: 30.w,
                height: 12.sp,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search for turfs, locations...',
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 14.sp,
            ),
            prefixIcon:
                Icon(Icons.search, color: UIConfig.primaryColor, size: 17.sp),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4.w),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4.w),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4.w),
              borderSide: BorderSide(color: UIConfig.primaryColor, width: 1.5),
            ),
            contentPadding:
                EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
          ),
        ),
      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: UIConfig.darkColor,
            ),
          ),
          Text(
            'View all',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: UIConfig.primaryColor,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }

  Widget _buildTopTurfsSection(BuildContext context) {
    final locationAsync = ref.watch(locationProvider);

    return locationAsync.when(
      data: (location) => location == null
          ? const SizedBox.shrink()
          : _buildTopTurfsContent(context, location),
      loading: () => ShimmerContainer(height: 28.h, isHorizontal: true),
      error: (error, _) {
        _logger.e('Error loading top turfs', error: error);
        return _buildErrorWidget(context, 'Failed to load turfs',
            onRetry: _refreshData);
      },
    );
  }

  Widget _buildTopTurfsContent(BuildContext context, dynamic location) {
    final topTurfsAsync = ref.watch(topTurfProvider(location));

    return topTurfsAsync.when(
      data: (turfs) => turfs.isEmpty
          ? _buildEmptyState(context, 'No top turfs available')
          : SizedBox(height: 32.h, child: TopTurfsCarousel(turfs: turfs)),
      loading: () => ShimmerContainer(height: 28.h, isHorizontal: true),
      error: (error, _) {
        _logger.e('Error loading top turfs content', error: error);
        return _buildErrorWidget(context, 'Failed to load turfs',
            onRetry: _refreshData);
      },
    );
  }

  Widget _buildNearbyTurfsSection(BuildContext context) {
    final locationAsync = ref.watch(locationProvider);

    return locationAsync.when(
      data: (location) => location == null
          ? const SizedBox.shrink()
          : _buildNearbyTurfsContent(context, location),
      loading: () => ShimmerContainer(height: 25.h, isHorizontal: false),
      error: (error, _) {
        _logger.e('Error loading nearby turfs', error: error);
        return _buildErrorWidget(context, 'Failed to load turfs',
            onRetry: _refreshData);
      },
    );
  }

  Widget _buildNearbyTurfsContent(BuildContext context, dynamic location) {
    final nearbyTurfsAsync = ref.watch(nearbyTurfsProvider(location));

    return nearbyTurfsAsync.when(
      data: (turfs) => turfs.isEmpty
          ? _buildEmptyState(context, 'No nearby turfs found')
          : NearbyTurfsList(turfs: turfs),
      loading: () => ShimmerContainer(height: 25.h, isHorizontal: false),
      error: (error, _) {
        _logger.e('Error loading nearby turfs content', error: error);
        return _buildErrorWidget(context, 'Failed to load turfs',
            onRetry: _refreshData);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Container(
      height: 15.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UIConfig.cardBorderRadius(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 30.sp, color: Colors.grey[400]),
            SizedBox(height: 2.h),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String message,
      {required VoidCallback onRetry}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(3.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UIConfig.cardBorderRadius(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 30.sp),
          SizedBox(height: 2.h),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: UIConfig.darkColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: UIConfig.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3.w)),
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              elevation: 2,
            ),
            child: Text(
              'Try Again',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class ShimmerContainer extends StatelessWidget {
  final double? width;
  final double height;
  final bool isHorizontal;

  const ShimmerContainer({
    super.key,
    this.width,
    required this.height,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: Shimmer.fromColors(
        baseColor: UIConfig.shimmerBaseColor,
        highlightColor: UIConfig.shimmerHighlightColor,
        child: ListView.builder(
          scrollDirection: isHorizontal ? Axis.horizontal : Axis.vertical,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          padding: EdgeInsets.symmetric(horizontal: isHorizontal ? 4.w : 0),
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsets.only(
              right: isHorizontal ? 4.w : 0,
              bottom: isHorizontal ? 0 : 3.h,
              left: isHorizontal ? 0 : 4.w,
            ),
            child: Container(
              width: isHorizontal ? 80.w : double.infinity,
              height: isHorizontal ? height : height * 0.8,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(UIConfig.cardBorderRadius(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TopTurfsCarousel extends StatefulWidget {
  final List<DocumentSnapshot> turfs;
  const TopTurfsCarousel({super.key, required this.turfs});

  @override
  State<TopTurfsCarousel> createState() => _TopTurfsCarouselState();
}

class _TopTurfsCarouselState extends State<TopTurfsCarousel> {
  late PageController _pageController;
  late Timer _timer;
  int _currentPage = 0;
  final _logger = Logger();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _startAutoCarousel();
  }

  void _startAutoCarousel() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      try {
        if (_pageController.hasClients) {
          if (_currentPage < widget.turfs.length - 1) {
            _currentPage++;
          } else {
            _currentPage = 0;
          }
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutQuint,
          );
        }
      } catch (e, stackTrace) {
        _logger.e('Error in carousel', error: e, stackTrace: stackTrace);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 28.h,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.turfs.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final turf = widget.turfs[index].data() as Map<String, dynamic>;
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = (_pageController.page ?? 0) - index;
                    value = (1 - (value.abs() * 0.2)).clamp(0.8, 1.0);
                  }
                  return Transform.scale(scale: value, child: child);
                },
                child: _buildTurfCard(context, turf, index),
              );
            },
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.turfs.length,
            (index) => AnimatedContainer(
              duration: 300.ms,
              width: _currentPage == index ? 5.w : 2.w,
              height: 2.w,
              margin: EdgeInsets.symmetric(horizontal: 1.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1.w),
                color: _currentPage == index
                    ? UIConfig.primaryColor
                    : Colors.grey[300],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTurfCard(
      BuildContext context, Map<String, dynamic> turf, int index) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              Turfscreen(documentSnapshot: widget.turfs[index]),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        child: Container(
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(UIConfig.cardBorderRadius(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(UIConfig.cardBorderRadius(context)),
            child: Stack(
              children: [
                _buildTurfImage(context, turf),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8)
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          turf['name'] ?? 'Unnamed Turf',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.2.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    color: Colors.white70, size: 14.sp),
                                SizedBox(width: 1.w),
                                Text(
                                  turf['address']
                                          ?.split(',')
                                          .take(2)
                                          .join(',') ??
                                      'Unknown',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 11.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 3.w, vertical: 1.h),
                              decoration: BoxDecoration(
                                color: UIConfig.accentColor,
                                borderRadius: BorderRadius.circular(5.w),
                              ),
                              child: Row(
                                children: [
                                  FaIcon(FontAwesomeIcons.star,
                                      color: Colors.white, size: 14.sp),
                                  SizedBox(width: 1.w),
                                  Text(
                                    turf['rating']?.toStringAsFixed(1) ?? '0.0',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 3.w,
                  right: 3.w,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5.w),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      "₹${turf['price']?.toString() ?? 'N/A'}",
                      style: GoogleFonts.poppins(
                        color: UIConfig.primaryColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 600.ms, delay: (index * 150).ms),
      ),
    );
  }

  Widget _buildTurfImage(BuildContext context, Map<String, dynamic> turf) {
    return Image.network(
      turf['imageurl'] ?? 'https://via.placeholder.com/400x250',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Shimmer.fromColors(
          baseColor: UIConfig.shimmerBaseColor,
          highlightColor: UIConfig.shimmerHighlightColor,
          child: Container(color: Colors.white),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        _logger.e('Error loading image', error: error, stackTrace: stackTrace);
        return Container(
          color: Colors.grey[200],
          child: Center(
              child: Icon(Icons.image_not_supported,
                  color: Colors.grey[400], size: 30.sp)),
        );
      },
    );
  }
}

class NearbyTurfsList extends StatelessWidget {
  final List<DocumentSnapshot> turfs;
  const NearbyTurfsList({super.key, required this.turfs});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemCount: turfs.length,
      itemBuilder: (context, index) {
        final turf = turfs[index].data() as Map<String, dynamic>;
        return _buildNearbyTurfCard(context, turf, index);
      },
    );
  }

  Widget _buildNearbyTurfCard(
      BuildContext context, Map<String, dynamic> turf, int index) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Turfscreen(documentSnapshot: turfs[index]),
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 3.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(UIConfig.cardBorderRadius(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(UIConfig.cardBorderRadius(context)),
                  bottomLeft:
                      Radius.circular(UIConfig.cardBorderRadius(context)),
                ),
                child: Container(
                  width: 30.w,
                  height: 10.h,
                  color: Colors.grey[200],
                  child: Image.network(
                    turf['imageurl'] ?? 'https://via.placeholder.com/150',
                    width: 30.w,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Shimmer.fromColors(
                        baseColor: UIConfig.shimmerBaseColor,
                        highlightColor: UIConfig.shimmerHighlightColor,
                        child: Container(color: Colors.white),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(Icons.image_not_supported,
                          color: Colors.grey[400], size: 20.sp),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(2.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              turf['name'] ?? 'Unnamed Turf',
                              style: GoogleFonts.poppins(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: UIConfig.darkColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 2.w, vertical: 1.h),
                            decoration: BoxDecoration(
                              color:
                                  UIConfig.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(3.w),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FaIcon(FontAwesomeIcons.star,
                                    color: UIConfig.accentColor, size: 13.sp),
                                SizedBox(width: 1.w),
                                Text(
                                  turf['rating']?.toStringAsFixed(1) ?? '0.0',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: UIConfig.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.1.h),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 11.sp, color: Colors.grey[600]),
                          SizedBox(width: 1.w),
                          Expanded(
                            child: Text(
                              turf['address'] ?? 'Unknown Location',
                              style: GoogleFonts.poppins(
                                fontSize: 11.sp,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "₹${turf['price']?.toString() ?? 'N/A'} / hour",
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: UIConfig.primaryColor,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 3.w, vertical: 1.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                UIConfig.primaryColor,
                                UIConfig.secondaryColor
                              ]),
                              borderRadius: BorderRadius.circular(3.w),
                            ),
                            child: Text(
                              'Book Now',
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 500.ms, delay: (index * 100).ms)
          .slideY(begin: 0.2, end: 0),
    );
  }
}
