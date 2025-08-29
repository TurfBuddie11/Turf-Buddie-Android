import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../riverpod_providers/turf_bookings_provider.dart';

class BookingService {
  static Future<void> cancelBooking({
    required Booking booking,
    required String userId,
    required BuildContext context,
  }) async {
    try {
      final now = DateTime.now();
      final bookingDateTime = _parseBookingDateTime(
          booking.daySlot, booking.monthSlot, booking.timeSlot);
      final timeRemaining = bookingDateTime.difference(now);

      // Calculate refund based on cancellation time
      final refundDetails = _calculateRefund(booking.price, timeRemaining);

      // Get reference to the turf document
      final turfRef = FirebaseFirestore.instance
          .collection('Turfs')
          .doc(booking.turfId);

      // Run transaction to update the time slot
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final turfDoc = await transaction.get(turfRef);
        if (!turfDoc.exists) {
          throw Exception('Turf not found');
        }

        final timeSlots = List.from(turfDoc['timeSlots'] ?? []);
        bool slotFound = false;

        for (int i = 0; i < timeSlots.length; i++) {
          if (timeSlots[i]['transactionId'] == booking.transactionId) {
            slotFound = true;
            timeSlots[i] = {
              ...timeSlots[i],
              'status': 'cancelled',
              'cancelledAt': FieldValue.serverTimestamp(),
              'refundAmount': refundDetails.amount,
              'refundPercentage': refundDetails.percentage,
            };
            break;
          }
        }

        if (!slotFound) {
          throw Exception('Booking slot not found');
        }

        transaction.update(turfRef, {'timeSlots': timeSlots});
      });

      // Process refund if applicable
      if (refundDetails.amount > 0) {
        await _processRefund(booking.transactionId, refundDetails.amount);
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking cancelled successfully',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to cancel booking: ${e.toString()}',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  static RefundDetails _calculateRefund(double price, Duration timeRemaining) {
    if (timeRemaining.inHours >= 3) {
      return RefundDetails(amount: price * 0.9, percentage: 90);
    } else if (timeRemaining.inHours >= 1) {
      return RefundDetails(amount: price * 0.5, percentage: 50);
    }
    return RefundDetails(amount: 0, percentage: 0);
  }

  static Future<void> _processRefund(String transactionId, double amount) async {
    try {
      // Implement actual refund processing here
      debugPrint('Processing refund of $amount for transaction $transactionId');
    } catch (e) {
      debugPrint('Refund processing error: $e');
    }
  }

  static DateTime _parseBookingDateTime(
      String daySlot, String monthSlot, String timeSlot) {
    // Parse date (e.g., "Monday, 5 Mar")
    final dateStr = '$daySlot, $monthSlot';
    final date = DateFormat('EEEE, d MMM').parse(dateStr);

    // Parse time (e.g., "8 am - 9 am")
    final startTimeStr = timeSlot.split(' - ')[0];
    final timeParts = startTimeStr.split(' ');
    var hour = int.parse(timeParts[0]);
    final period = timeParts[1];

    if (period == 'pm' && hour != 12) hour += 12;
    if (period == 'am' && hour == 12) hour = 0;

    return DateTime(date.year, date.month, date.day, hour);
  }
}

class RefundDetails {
  final double amount;
  final int percentage;

  RefundDetails({required this.amount, required this.percentage});
}