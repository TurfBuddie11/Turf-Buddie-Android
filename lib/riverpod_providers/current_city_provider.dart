// current_city_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

final currentCityProvider = FutureProvider<String>((ref) async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ));
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        debugPrint('Location Data: ${placemarks.toString()}');
        Placemark place = placemarks.first;
        final city = place.subAdministrativeArea?.isNotEmpty == true
            ? place.subAdministrativeArea
            : place.locality?.isNotEmpty == true
                ? place.locality
                : place.administrativeArea;
        if (city != null && city.isNotEmpty) {
          return city;
        } else {
          return Future.error('City name not found');
        }
      } else {
        return Future.error('Unable to get city');
      }
    } else {
      return Future.error('Permission denied');
    }
  } catch (error) {
    return Future.error('Error in fetching location: $error');
  }
});
