import 'package:cloud_firestore/cloud_firestore.dart';

class FileNumberService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String> getNextFileNumber() async {
    final currentYear = DateTime.now().year;
    final yearSuffix = (currentYear % 100).toString().padLeft(2, '0');

    // Get the counter document for this year
    final counterRef = _firestore
        .collection('counters')
        .doc('file_numbers_$yearSuffix');

    final counterDoc = await counterRef.get();
    int currentCount = 0;
    if (counterDoc.exists) {
      currentCount = counterDoc.data()?['count'] ?? 0;
    }

    // Return what the NEXT file number would be (without incrementing)
    int nextNumber = currentCount + 1;
    return '$yearSuffix-$nextNumber';
  }

  static Future<String> reserveFileNumber() async {
    final currentYear = DateTime.now().year;
    final yearSuffix = (currentYear % 100).toString().padLeft(2, '0');

    // Get the counter document for this year
    final counterRef = _firestore
        .collection('counters')
        .doc('file_numbers_$yearSuffix');

    return await _firestore.runTransaction((transaction) async {
      final counterDoc = await transaction.get(counterRef);

      int nextNumber = 1;
      if (counterDoc.exists) {
        nextNumber = (counterDoc.data()?['count'] ?? 0) + 1;
      }

      // Update counter (this reserves the number)
      transaction.set(counterRef, {
        'count': nextNumber,
      }, SetOptions(merge: true));

      // Return formatted file number
      return '$yearSuffix-$nextNumber';
    });
  }
}
