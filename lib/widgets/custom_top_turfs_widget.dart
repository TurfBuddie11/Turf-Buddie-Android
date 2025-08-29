import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tb_web/riverpod_providers/top_turfs_provider.dart';
import '../riverpod_providers/current_locatioin_provider.dart';

class CustomTopTurfsWidget extends ConsumerStatefulWidget {
  const CustomTopTurfsWidget({super.key});

  @override
  ConsumerState<CustomTopTurfsWidget> createState() =>
      _CustomTopTurfsWidgetState();
}

class _CustomTopTurfsWidgetState extends ConsumerState<CustomTopTurfsWidget> {
  late PageController _pageController;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _timer = Timer.periodic(Duration(seconds: 4), (Timer timer) {
      if (_pageController.hasClients && _pageController.page!.toInt() < 4) {
        _pageController.nextPage(
            duration: Duration(milliseconds: 800), curve: Curves.easeInOut);
      } else if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
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
    final currentLocationProvider = ref.watch(locationProvider);
    final size = MediaQuery.of(context).size;
    return currentLocationProvider.when(
        data: (location) {
          if (location == null) {
            return Text('Location not available');
          }
          final topTurfsProvider = ref.watch(topTurfProvider(location));
          return topTurfsProvider.when(
              data: (turfs) {
                return PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.horizontal,
                  itemCount: turfs.length,
                  clipBehavior: Clip.hardEdge,
                  itemBuilder: (context, index) {
                    return Container(
                      width: size.width * 0.9,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            clipBehavior: Clip.hardEdge,
                            decoration: _buildContainerDecoration(),
                            child: Stack(
                              children: [
                                Image.network(
                                  turfs[index]['imageurl'],
                                  width: size.width * 0.9,
                                  height: size.height * 0.2,
                                  fit: BoxFit.fill,
                                ),
                                Positioned(
                                    bottom: 0,
                                    child: Container(
                                      height: size.height * 0.05,
                                      width: size.width * 0.9,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(20),
                                          bottomRight: Radius.circular(20),
                                        ),
                                      ),
                                    )
                                ),
                                Positioned(
                                  bottom: size.height * 0.01,
                                  left: size.width * 0.02,
                                  child: SizedBox(
                                    width: size.width * 0.9,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 20.0),
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            turfs[index]['name'],
                                            style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 20, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            "₹${turfs[index]['price'].toString()}",
                                            style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 20, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                    right: size.width * 0.02,
                                    top: size.height * 0.01,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            FaIcon(FontAwesomeIcons.rankingStar,
                                              color: Colors.yellow, size: 20,),
                                            const SizedBox(width: 5),
                                            Text(turfs[index]['rating'].toString(),
                                                style: GoogleFonts.poppins(
                                                    color: Colors.white, fontSize: 19.5, fontWeight: FontWeight.bold, height: 0)),
                                          ],
                                        ),
                                      ),
                                    )
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              error: (error, stackTrace) => _buildErrorWidget(error),
              loading: () => _buildShimmerLoading(size));
        },
        error: (error, stackTrace) => _buildErrorWidget(error),
        loading: () => _buildShimmerLoading(size));
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

  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      color: Colors.black.withOpacity(0.5),
      borderRadius: BorderRadius.circular(20),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Text('Error: $error');
  }
}