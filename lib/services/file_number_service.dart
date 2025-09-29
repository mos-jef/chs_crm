// lib/services/file_number_service.dart - UPDATED FOR UNLIMITED FILES
import 'package:cloud_firestore/cloud_firestore.dart';

class FileNumberService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🎯 OPTION 1: UNLIMITED NUMERIC (6-digits) - 25-000001, 25-000002, etc.
  static Future<String> getNextFileNumber() async {
    final currentYear = DateTime.now().year;
    final yearSuffix = (currentYear % 100).toString().padLeft(2, '0');

    final counterRef =
        _firestore.collection('counters').doc('file_numbers_$yearSuffix');

    final counterDoc = await counterRef.get();
    int currentCount = 0;
    if (counterDoc.exists) {
      currentCount = counterDoc.data()?['count'] ?? 0;
    }

    int nextNumber = currentCount + 1;
    // 6-digit padding allows for 999,999 files per year
    return '$yearSuffix-${nextNumber.toString().padLeft(6, '0')}';
  }

  static Future<String> reserveFileNumber() async {
    final currentYear = DateTime.now().year;
    final yearSuffix = (currentYear % 100).toString().padLeft(2, '0');

    final counterRef =
        _firestore.collection('counters').doc('file_numbers_$yearSuffix');

    return await _firestore.runTransaction((transaction) async {
      final counterDoc = await transaction.get(counterRef);

      int nextNumber = 1;
      if (counterDoc.exists) {
        nextNumber = (counterDoc.data()?['count'] ?? 0) + 1;
      }

      transaction.set(
          counterRef,
          {
            'count': nextNumber,
          },
          SetOptions(merge: true));

      // 6-digit padding for unlimited files
      return '$yearSuffix-${nextNumber.toString().padLeft(6, '0')}';
    });
  }

  // 🎯 OPTION 2: ALPHANUMERIC SYSTEM - 25-AAAA, 25-AAAB, 25-AAAC, etc.
  static Future<String> getNextAlphanumericFileNumber() async {
    final currentYear = DateTime.now().year;
    final yearSuffix = (currentYear % 100).toString().padLeft(2, '0');

    final counterRef =
        _firestore.collection('counters').doc('file_numbers_alpha_$yearSuffix');

    final counterDoc = await counterRef.get();
    int currentCount = 0;
    if (counterDoc.exists) {
      currentCount = counterDoc.data()?['count'] ?? 0;
    }

    int nextNumber = currentCount + 1;
    String alphaCode = _numberToAlphaCode(nextNumber);
    return '$yearSuffix-$alphaCode';
  }

  static Future<String> reserveAlphanumericFileNumber() async {
    final currentYear = DateTime.now().year;
    final yearSuffix = (currentYear % 100).toString().padLeft(2, '0');

    final counterRef =
        _firestore.collection('counters').doc('file_numbers_alpha_$yearSuffix');

    return await _firestore.runTransaction((transaction) async {
      final counterDoc = await transaction.get(counterRef);

      int nextNumber = 1;
      if (counterDoc.exists) {
        nextNumber = (counterDoc.data()?['count'] ?? 0) + 1;
      }

      transaction.set(
          counterRef,
          {
            'count': nextNumber,
          },
          SetOptions(merge: true));

      String alphaCode = _numberToAlphaCode(nextNumber);
      return '$yearSuffix-$alphaCode';
    });
  }

  // 🎯 HELPER: Convert number to alpha code (1=AAAA, 2=AAAB, etc.)
  static String _numberToAlphaCode(int number) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const base = 26;
    const length = 4; // 4 characters = 456,976 combinations per year

    String result = '';
    int num = number - 1; // Convert to 0-based

    for (int i = 0; i < length; i++) {
      result = letters[num % base] + result;
      num ~/= base;
    }

    return result.padLeft(length, 'A');
  }

  // 🎯 OPTION 3: MIXED SYSTEM - 25-A0001, 25-A0002, ... 25-Z9999, 25-AA001, etc.
  static Future<String> getNextMixedFileNumber() async {
    final currentYear = DateTime.now().year;
    final yearSuffix = (currentYear % 100).toString().padLeft(2, '0');

    final counterRef =
        _firestore.collection('counters').doc('file_numbers_mixed_$yearSuffix');

    final counterDoc = await counterRef.get();
    int currentCount = 0;
    if (counterDoc.exists) {
      currentCount = counterDoc.data()?['count'] ?? 0;
    }

    int nextNumber = currentCount + 1;
    String mixedCode = _numberToMixedCode(nextNumber);
    return '$yearSuffix-$mixedCode';
  }

  static Future<String> reserveMixedFileNumber() async {
    final currentYear = DateTime.now().year;
    final yearSuffix = (currentYear % 100).toString().padLeft(2, '0');

    final counterRef =
        _firestore.collection('counters').doc('file_numbers_mixed_$yearSuffix');

    return await _firestore.runTransaction((transaction) async {
      final counterDoc = await transaction.get(counterRef);

      int nextNumber = 1;
      if (counterDoc.exists) {
        nextNumber = (counterDoc.data()?['count'] ?? 0) + 1;
      }

      transaction.set(
          counterRef,
          {
            'count': nextNumber,
          },
          SetOptions(merge: true));

      String mixedCode = _numberToMixedCode(nextNumber);
      return '$yearSuffix-$mixedCode';
    });
  }

  // 🎯 HELPER: Convert number to mixed code (A0001, A0002, ..., Z9999, AA001, etc.)
  static String _numberToMixedCode(int number) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    // Each letter covers 9999 numbers (0001-9999)
    int letterIndex = ((number - 1) ~/ 9999) % 26;
    int numPart = ((number - 1) % 9999) + 1;

    String letter = letters[letterIndex];

    // If we exceed single letters, add another letter
    if ((number - 1) ~/ 9999 >= 26) {
      int firstLetterIndex = ((number - 1) ~/ (9999 * 26)) % 26;
      letter = letters[firstLetterIndex] + letter;
    }

    return '$letter${numPart.toString().padLeft(4, '0')}';
  }

  // 🎯 SWITCH BETWEEN SYSTEMS - Update your existing calls
  // Replace existing methods to use your preferred system:

  // For UNLIMITED NUMERIC (recommended):
  // static Future<String> getNextFileNumber() => getNextFileNumber(); // Already updated above

  // For ALPHANUMERIC:
  // static Future<String> getNextFileNumber() => getNextAlphanumericFileNumber();
  // static Future<String> reserveFileNumber() => reserveAlphanumericFileNumber();

  // For MIXED:
  // static Future<String> getNextFileNumber() => getNextMixedFileNumber();
  // static Future<String> reserveFileNumber() => reserveMixedFileNumber();
}
