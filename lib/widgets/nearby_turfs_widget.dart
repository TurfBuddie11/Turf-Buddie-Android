import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tb_web/riverpod_providers/current_locatioin_provider.dart';
import 'package:tb_web/riverpod_providers/nearby_turfs_provider.dart';
import 'package:tb_web/screens/home_screens/turf_screen.dart';

class NearbyTurfsWidget extends ConsumerStatefulWidget {
  const NearbyTurfsWidget({super.key});

  @override
  ConsumerState<NearbyTurfsWidget> createState() => _NearbyTurfsWidgetState();
}

class _NearbyTurfsWidgetState extends ConsumerState<NearbyTurfsWidget> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final currentLocationProvider = ref.watch(locationProvider);
    return currentLocationProvider.when(
      data: (location) {
        if (location == null) {
          return Center(child: Text('Location not available'));
        }
        final nearbyTurfs = ref.watch(nearbyTurfsProvider(location));
        return nearbyTurfs.when(
          data: (turfs) {
            return ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              scrollDirection: Axis.vertical,
              itemCount: turfs.length,
              shrinkWrap: true,
              clipBehavior: Clip.hardEdge,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              Turfscreen(documentSnapshot: turfs[index]),
                        ),
                      );
                    },
                    child: Container(
                      width: size.width * 0.9,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                            child: Image.network(
                              turfs[index]['imageurl'],
                              width: size.width * 0.9,
                              height: size.height * 0.2,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      turfs[index]['name'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        FaIcon(
                                          FontAwesomeIcons.rankingStar,
                                          color: Colors.yellow,
                                          size: 16,
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                          turfs[index]['rating'].toString(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  turfs[index]['address'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "₹${turfs[index]['price'].toString()}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => _buildShimmerLoading(size),
          error: (error, _) => _buildErrorWidget(error),
        );
      },
      error: (error, _) => _buildErrorWidget(error),
      loading: () => _buildShimmerLoading(size),
    );
  }

  Widget _buildShimmerLoading(Size size) {
    return SizedBox(
      height: size.height * 0.2,
      width: size.width * 0.9,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: size.height * 0.2,
          width: size.width * 0.9,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Text('Error: $error');
  }
}