import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tb_web/riverpod_providers/current_locatioin_provider.dart';
import 'package:tb_web/riverpod_providers/turfs_provider.dart';
import 'package:tb_web/screens/home_screens/turf_screen.dart';

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

  // Responsive scaling
  static double scaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return 0.85;  // Small phones
    if (width < 400) return 0.95;  // Medium phones
    if (width < 600) return 1.0;   // Large phones
    return 1.1;                    // Tablets
  }

  // Responsive padding
  static double padding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return 12.0;
    if (width < 400) return 14.0;
    return 20.0;
  }

  // Card border radius
  static double cardBorderRadius(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < 400 ? 12.0 : 16.0;
  }

  // Text Styles
  static TextStyle headlineLarge(BuildContext context) => GoogleFonts.poppins(
    fontSize: 24 * scaleFactor(context),
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
    fontSize: 12 * scaleFactor(context),
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
    fontSize: 9 * scaleFactor(context),
    fontWeight: FontWeight.w400,
    color: darkColor.withOpacity(0.7),
  );

  static TextStyle buttonText(BuildContext context) => GoogleFonts.poppins(
    fontSize: 14 * scaleFactor(context),
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

class TurfsListScreen extends ConsumerStatefulWidget {
  const TurfsListScreen({super.key});

  @override
  ConsumerState<TurfsListScreen> createState() => _TurfsListScreenState();
}

class _TurfsListScreenState extends ConsumerState<TurfsListScreen> {
  final double _minPrice = 0;
  final double _maxPrice = 5000;
  double _selectedMinPrice = 0;
  double _selectedMaxPrice = 5000;

  final double _minDistance = 0;
  final double _maxDistance = 50;
  double _selectedMaxDistance = 50;

  double _minRating = 0;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  Future<void> _refreshData() async {
    ref.invalidate(turfsProvider);
    ref.invalidate(locationProvider);
    await ref.read(turfsProvider.future);
    await ref.read(locationProvider.future);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 350;
    final isMediumScreen = size.width < 400;
    final turfsAsync = ref.watch(turfsProvider);
    final locationAsync = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: UIConfig.lightColor,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: UIConfig.primaryColor,
        displacement: 40,
        edgeOffset: UIConfig.padding(context),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildSearchBar(context),
                  _buildFilterPanel(context),
                  SizedBox(height: isSmallScreen ? 4 : 8),
                ],
              ),
            ),
            _buildTurfListSection(turfsAsync, locationAsync, size),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 350;
    final isMediumScreen = MediaQuery.of(context).size.width < 400;

    return SliverAppBar(
      expandedHeight: isSmallScreen ? 160 : isMediumScreen ? 180 : 200,
      floating: true,
      pinned: true,
      elevation: 4,
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
          left: UIConfig.padding(context),
          bottom: isSmallScreen ? 12 : 16,
        ),
        title: Text(
          'Find Turfs Near You',
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
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 350;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: UIConfig.padding(context),
        vertical: isSmallScreen ? 12 : UIConfig.padding(context),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search turfs by name...',
            hintStyle: UIConfig.bodyMedium(context).copyWith(
              color: Colors.grey[600],
            ),
            prefixIcon: Icon(
              Icons.search,
              color: UIConfig.primaryColor,
              size: isSmallScreen ? 20 : 24,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 15),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: isSmallScreen ? 14 : 16,
              horizontal: isSmallScreen ? 12 : 16,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear, color: Colors.grey[600], size: isSmallScreen ? 18 : 20),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            )
                : null,
          ),
        ),
      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
    );
  }

  Widget _buildFilterPanel(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 350;

    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: UIConfig.padding(context)),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConfig.cardBorderRadius(context)),
      ),
      child: ExpansionTile(
        title: Text(
          'Filter Turfs',
          style: UIConfig.titleMedium(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Icon(Icons.filter_alt, color: UIConfig.primaryColor, size: isSmallScreen ? 20 : 24),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 4 : 8,
            ),
            child: Column(
              children: [
                _buildPriceFilter(context),
                SizedBox(height: isSmallScreen ? 8 : 12),
                _buildDistanceFilter(context),
                SizedBox(height: isSmallScreen ? 8 : 12),
                _buildRatingFilter(context),
                SizedBox(height: isSmallScreen ? 4 : 8),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildPriceFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range (₹${_selectedMinPrice.round()} - ₹${_selectedMaxPrice.round()})',
          style: UIConfig.bodyMedium(context).copyWith(
            color: UIConfig.darkColor.withOpacity(0.8),
          ),
        ),
        SizedBox(height: UIConfig.padding(context) / 2),
        RangeSlider(
          values: RangeValues(_selectedMinPrice, _selectedMaxPrice),
          min: _minPrice,
          max: _maxPrice,
          divisions: 20,
          labels: RangeLabels(
            '₹${_selectedMinPrice.round()}',
            '₹${_selectedMaxPrice.round()}',
          ),
          activeColor: UIConfig.primaryColor,
          inactiveColor: Colors.grey[300],
          onChanged: (values) => setState(() {
            _selectedMinPrice = values.start;
            _selectedMaxPrice = values.end;
          }),
        ),
      ],
    );
  }

  Widget _buildDistanceFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Maximum Distance (${_selectedMaxDistance.round()} km)',
          style: UIConfig.bodyMedium(context).copyWith(
            color: UIConfig.darkColor.withOpacity(0.8),
          ),
        ),
        SizedBox(height: UIConfig.padding(context) / 2),
        Slider(
          value: _selectedMaxDistance,
          min: _minDistance,
          max: _maxDistance,
          divisions: 10,
          label: '${_selectedMaxDistance.round()} km',
          activeColor: UIConfig.primaryColor,
          inactiveColor: Colors.grey[300],
          onChanged: (value) => setState(() => _selectedMaxDistance = value),
        ),
      ],
    );
  }

  Widget _buildRatingFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minimum Rating (${_minRating.toStringAsFixed(1)} ★)',
          style: UIConfig.bodyMedium(context).copyWith(
            color: UIConfig.darkColor.withOpacity(0.8),
          ),
        ),
        SizedBox(height: UIConfig.padding(context) / 2),
        Slider(
          value: _minRating,
          min: 0,
          max: 5,
          divisions: 10,
          label: '${_minRating.toStringAsFixed(1)} ★',
          activeColor: UIConfig.primaryColor,
          inactiveColor: Colors.grey[300],
          onChanged: (value) => setState(() => _minRating = value),
        ),
      ],
    );
  }

  Widget _buildTurfListSection(
      AsyncValue<List<DocumentSnapshot>> turfsAsync,
      AsyncValue<Position?> locationAsync,
      Size size,
      ) {
    return locationAsync.when(
      data: (location) => turfsAsync.when(
        data: (turfs) => _buildTurfList(turfs, location, size),
        loading: () => SliverToBoxAdapter(
          child: ShimmerContainer(
            height: size.height * (size.width < 350 ? 0.2 : 0.25),
            isHorizontal: false,
          ),
        ),
        error: (error, _) => SliverToBoxAdapter(
          child: _buildErrorWidget(context, error),
        ),
      ),
      loading: () => SliverToBoxAdapter(
        child: ShimmerContainer(
          height: size.height * (size.width < 350 ? 0.2 : 0.25),
          isHorizontal: false,
        ),
      ),
      error: (error, _) => SliverToBoxAdapter(
        child: _buildErrorWidget(context, error),
      ),
    );
  }

  Widget _buildTurfList(List<DocumentSnapshot> turfs, Position? location, Size size) {
    if (location == null) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(context, 'Location services disabled', size),
      );
    }

    final filteredTurfs = turfs.where((turf) {
      final data = turf.data() as Map<String, dynamic>? ?? {};
      final price = (data['price'] as num?)?.toDouble() ?? 0;
      final rating = (data['rating'] as num?)?.toDouble() ?? 0;
      final geoPoint = data['location'] as GeoPoint?;

      if (geoPoint == null) return false;

      final distance = Geolocator.distanceBetween(
        geoPoint.latitude,
        geoPoint.longitude,
        location.latitude,
        location.longitude,
      ) / 1000;

      final nameMatch = data['name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;

      return price >= _selectedMinPrice &&
          price <= _selectedMaxPrice &&
          distance <= _selectedMaxDistance &&
          rating >= _minRating &&
          nameMatch;
    }).toList();

    if (filteredTurfs.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(context, 'No turfs match your filters', size),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) => _buildTurfCard(context, filteredTurfs[index], location, index),
        childCount: filteredTurfs.length,
      ),
    );
  }

  Widget _buildTurfCard(BuildContext context, DocumentSnapshot turf, Position location, int index) {
    final isSmallScreen = MediaQuery.of(context).size.width < 350;
    final isMediumScreen = MediaQuery.of(context).size.width < 400;
    final data = turf.data() as Map<String, dynamic>? ?? {};
    final geoPoint = data['location'] as GeoPoint?;
    final distance = geoPoint != null
        ? Geolocator.distanceBetween(
      geoPoint.latitude,
      geoPoint.longitude,
      location.latitude,
      location.longitude,
    ) / 1000
        : double.infinity;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: UIConfig.padding(context),
        vertical: isSmallScreen ? 6 : 8,
      ),
      child: Card(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConfig.cardBorderRadius(context)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(UIConfig.cardBorderRadius(context)),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Turfscreen(documentSnapshot: turf),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Turf Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    data['imageurl'] ?? 'https://via.placeholder.com/150',
                    width: isSmallScreen ? 100 : 120,
                    height: isSmallScreen ? 100 : 120,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Shimmer.fromColors(
                        baseColor: UIConfig.shimmerBaseColor,
                        highlightColor: UIConfig.shimmerHighlightColor,
                        child: Container(
                          width: isSmallScreen ? 100 : 120,
                          height: isSmallScreen ? 100 : 120,
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: isSmallScreen ? 100 : 120,
                      height: isSmallScreen ? 100 : 120,
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[400],
                          size: isSmallScreen ? 30 : 40,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                // Turf Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Unnamed Turf',
                        style: UIConfig.titleMedium(context).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isSmallScreen ? 6 : 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: isSmallScreen ? 14 : 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: isSmallScreen ? 4 : 6),
                          Expanded(
                            child: Text(
                              data['address']?.split(',').take(2).join(',') ?? 'Unknown location',
                              style: UIConfig.bodySmall(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 6 : 8),
                      Row(
                        children: [
                          Icon(
                            Icons.directions_walk,
                            size: isSmallScreen ? 14 : 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: isSmallScreen ? 4 : 6),
                          Text(
                            distance.isFinite
                                ? '${distance.toStringAsFixed(1)} km'
                                : 'Distance N/A',
                            style: UIConfig.bodySmall(context).copyWith(
                              color: UIConfig.primaryColor,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.star,
                            size: isSmallScreen ? 14 : 16,
                            color: UIConfig.accentColor,
                          ),
                          SizedBox(width: isSmallScreen ? 4 : 6),
                          Text(
                            data['rating']?.toStringAsFixed(1) ?? '0.0',
                            style: UIConfig.bodySmall(context).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 6 : 8),
                      Row(
                        children: [
                          Text(
                            '₹${data['price']?.toString() ?? 'N/A'} / hour',
                            style: UIConfig.titleMedium(context).copyWith(
                              color: UIConfig.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 10 : 12,
                              vertical: isSmallScreen ? 4 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: UIConfig.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Book Now',
                              style: UIConfig.bodySmall(context).copyWith(
                                fontWeight: FontWeight.bold,
                                color: UIConfig.primaryColor,
                              ),
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
      ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.2, end: 0),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message, Size size) {
    final isSmallScreen = size.width < 350;

    return Container(
      height: size.height * (isSmallScreen ? 0.25 : 0.3),
      margin: EdgeInsets.symmetric(horizontal: UIConfig.padding(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UIConfig.cardBorderRadius(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: isSmallScreen ? 40 : 50,
              color: Colors.grey[400],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              message,
              style: UIConfig.bodyLarge(context).copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: UIConfig.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 24,
                  vertical: isSmallScreen ? 10 : 12,
                ),
              ),
              child: Text(
                'Refresh',
                style: UIConfig.bodyMedium(context).copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildErrorWidget(BuildContext context, Object error) {
    final isSmallScreen = MediaQuery.of(context).size.width < 350;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: UIConfig.padding(context)),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UIConfig.cardBorderRadius(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[400],
            size: isSmallScreen ? 36 : 40,
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            'Something went wrong',
            style: UIConfig.titleLarge(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            error.toString(),
            style: UIConfig.bodyMedium(context).copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          ElevatedButton(
            onPressed: _refreshData,
            style: ElevatedButton.styleFrom(
              backgroundColor: UIConfig.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 24,
                vertical: isSmallScreen ? 10 : 12,
              ),
            ),
            child: Text(
              'Try Again',
              style: UIConfig.bodyMedium(context).copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
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
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 350;

    return SizedBox(
      height: height,
      child: Shimmer.fromColors(
        baseColor: UIConfig.shimmerBaseColor,
        highlightColor: UIConfig.shimmerHighlightColor,
        child: ListView.builder(
          scrollDirection: isHorizontal ? Axis.horizontal : Axis.vertical,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: isSmallScreen ? 2 : 3,
          padding: EdgeInsets.symmetric(
              horizontal: isHorizontal ? UIConfig.padding(context) : 0),
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsets.only(
              right: isHorizontal ? (isSmallScreen ? 12 : 16) : 0,
              bottom: isHorizontal ? 0 : (isSmallScreen ? 12 : 16),
              left: isHorizontal ? 0 : UIConfig.padding(context),
            ),
            child: Container(
              width: isHorizontal ? size.width * (isSmallScreen ? 0.85 : 0.8) : double.infinity,
              height: isHorizontal ? height : height * (isSmallScreen ? 0.7 : 0.8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(UIConfig.cardBorderRadius(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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