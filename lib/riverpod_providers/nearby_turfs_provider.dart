import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final nearbyTurfsProvider =
    FutureProvider.family<List<DocumentSnapshot>, Position>(
        (ref, position) async {
  QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('Turfs').get();

  List<DocumentSnapshot> nearbyTurfs = [];
  for (var doc in snapshot.docs) {
    GeoPoint turfLocation = doc['location'];
    double distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      turfLocation.latitude,
      turfLocation.longitude,
    );

    if (distanceInMeters / 1000 <= 10.0) {
      nearbyTurfs.add(doc);
    }
  }

  return nearbyTurfs;
});
