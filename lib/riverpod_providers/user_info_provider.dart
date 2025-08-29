//code for user info provider in riverpod
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final usersInfoProvider =
    FutureProvider.family<DocumentSnapshot, String>((ref, userId) async {
  DocumentSnapshot snapshot =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
  return snapshot;
});
