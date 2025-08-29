import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final turfsProvider = FutureProvider<List<DocumentSnapshot<Object?>>>((ref) async {
  final firestore = FirebaseFirestore.instance;
  try {
    final querySnapshot = await firestore.collection('Turfs').get();
    return querySnapshot.docs;
  } catch (e) {
    debugPrint('Error fetching turfs: $e');
    rethrow;
  }
});