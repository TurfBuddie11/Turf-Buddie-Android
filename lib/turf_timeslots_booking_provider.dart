import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Booking {
  final String turfId;
  final String timeSlot;
  final String daySlot;
  final String monthSlot;
  final String userUid;
  final String transactionId;
  final String status;
  final int price;
  final double commision;
  final double payout;
  final Timestamp bookingDate;
  final String paid;
  final double platformFees;

  Booking({
    required this.turfId,
    required this.timeSlot,
    required this.daySlot,
    required this.monthSlot,
    required this.userUid,
    required this.transactionId,
    required this.status,
    required this.price,
    required this.commision,
    required this.payout,
    required this.bookingDate,
    required this.paid,
    required this.platformFees,
  });

  Map<String, dynamic> toMap() {
    return {
      'timeSlot': timeSlot,
      'daySlot': daySlot,
      'monthSlot': monthSlot,
      'userUid': userUid,
      'transactionId': transactionId,
      'status': status,
      'bookingDate': bookingDate,
      'price': price,
      'commision': commision,
      'payout': payout,
      'paid': 'Not Paid to Owner',
      'platformFees': platformFees,
    };
  }
}

final turfAvailabilityProvider =
    StreamProvider.family<List<dynamic>, String>((ref, turfId) {
  return FirebaseFirestore.instance
      .collection('Turfs')
      .doc(turfId)
      .snapshots()
      .map((snapshot) {
    // If timeSlots exists and is a list, return it; otherwise, return an empty list
    final timeSlots = snapshot.data()?['timeSlots'];
    return timeSlots is List<dynamic> ? timeSlots : [];
  });
});

final bookProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, args) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('User not logged in');

  final booking = Booking(
      turfId: args['document'].id,
      timeSlot: args['timeSlot'],
      daySlot: args['daySlot'],
      monthSlot: args['monthSlot'],
      userUid: user.uid,
      transactionId: args['transactionId'] ?? 'pending',
      status: 'confirmed',
      price: args['price'],
      commision: (args['commission'] as num).toDouble(),
      // Ensure payout is a double if it's coming as a num
      payout: (args['payout'] as num).toDouble(),
      bookingDate: args['bookingDate'] as Timestamp,
      paid: 'Not Paid to Owner',
    platformFees: args['price'] * 0.015
  ); // Ensure bookingDate is a Timestamp

  await FirebaseFirestore.instance
      .collection('Turfs')
      .doc(args['document'].id)
      .update({
    'timeSlots': FieldValue.arrayUnion([booking.toMap()])
  });
});
