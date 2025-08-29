import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Booking {
  final String id;
  final String turfId;
  final String turfName;
  final String turfImage;
  final String address;
  final double price;
  final double rating;
  final GeoPoint location;
  final String status;
  final DateTime bookingDate;
  final String daySlot;
  final String timeSlot;
  final String monthSlot;
  final String userUid;
  final String transactionId;

  Booking({
    required this.id,
    required this.turfId,
    required this.turfName,
    required this.turfImage,
    required this.address,
    required this.price,
    required this.rating,
    required this.location,
    required this.status,
    required this.bookingDate,
    required this.daySlot,
    required this.timeSlot,
    required this.monthSlot,
    required this.userUid,
    required this.transactionId,
  });

  factory Booking.fromFirestore(
      String turfId,
      Map<String, dynamic> turfData,
      Map<String, dynamic> timeSlotMap,
      int slotIndex,
      ) {
    return Booking(
      id: '$turfId-$slotIndex',
      turfId: turfId,
      turfName: turfData['name'] as String? ?? 'Unknown Turf',
      turfImage: turfData['imageurl'] as String? ?? '',
      address: turfData['address'] as String? ?? '',
      price: (turfData['price'] as num?)?.toDouble() ?? 0.0,
      rating: (turfData['rating'] as num?)?.toDouble() ?? 0.0,
      location: turfData['location'] as GeoPoint? ?? const GeoPoint(0, 0),
      status: timeSlotMap['status'] as String? ?? 'confirmed',
      bookingDate: (timeSlotMap['bookingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      daySlot: timeSlotMap['daySlot'] as String? ?? '',
      timeSlot: timeSlotMap['timeSlot'] as String? ?? '',
      monthSlot: timeSlotMap['monthSlot'] as String? ?? '',
      userUid: timeSlotMap['userUid'] as String? ?? '',
      transactionId: timeSlotMap['transactionId'] as String? ?? '',
    );
  }
}

final bookingProvider = StreamProvider<List<Booking>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance.collection('Turfs').snapshots().map(
        (snapshot) {
      List<Booking> bookings = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timeSlots = (data['timeSlots'] as List<dynamic>?) ?? [];

        for (int i = 0; i < timeSlots.length; i++) {
          final slotMap = timeSlots[i] as Map<String, dynamic>;
          if (slotMap['userUid'] == user.uid) {
            bookings.add(Booking.fromFirestore(doc.id, data, slotMap, i));
          }
        }
      }

      // Sort bookings by date (newest first)
      bookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
      return bookings;
    },
  );
});

final currentUserProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});