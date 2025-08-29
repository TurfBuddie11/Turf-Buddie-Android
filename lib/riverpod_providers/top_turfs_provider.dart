import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

final topTurfProvider = FutureProvider.family<List<DocumentSnapshot>, Position>((ref, position) async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('Turfs').get();

  List<DocumentSnapshot> nearbyTurfs = [];
  List<Placemark> placeMarks = await placemarkFromCoordinates(position.latitude, position.longitude);
  String currentCity = placeMarks.first.subAdministrativeArea ?? '';

  for (var doc in snapshot.docs) {
    bool isTopTurf = doc['isTopTurf'] ?? false;
    GeoPoint turfLocation = doc['location'];
    List<Placemark> turfPlacemarks = await placemarkFromCoordinates(turfLocation.latitude, turfLocation.longitude);
    String turfCity = turfPlacemarks.first.subAdministrativeArea ?? '';
    if (turfCity == currentCity && isTopTurf) {
      nearbyTurfs.add(doc);
    }
  }
  debugPrint(nearbyTurfs.toString());
  return nearbyTurfs;
});