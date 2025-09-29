import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DocumentService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Maximum file size (10MB)
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  static Future<PlatformFile?> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt'],
        withData: true,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Check file size
        if (file.size > maxFileSizeBytes) {
          throw Exception(
            'File too large. Maximum size is ${(maxFileSizeBytes / (1024 * 1024)).round()}MB. '
            'Selected file is ${(file.size / (1024 * 1024)).toStringAsFixed(1)}MB.',
          );
        }

        // Validate file data
        if (file.bytes == null || file.bytes!.isEmpty) {
          throw Exception(
            'File data is empty or corrupted. Please try selecting the file again.',
          );
        }

        return file;
      }

      return null;
    } catch (e) {
      print('Error picking file: $e');
      rethrow;
    }
  }

  static Future<String?> uploadDocument({
    required PlatformFile file,
    required String propertyId,
    required String documentType,
  }) async {
    try {
      if (file.bytes == null || file.bytes!.isEmpty) {
        throw Exception('File data is empty');
      }

      // Validate file size again
      if (file.size > maxFileSizeBytes) {
        throw Exception(
          'File too large: ${(file.size / (1024 * 1024)).toStringAsFixed(1)}MB',
        );
      }

      // Create unique filename with timestamp and sanitized name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedName = _sanitizeFileName(file.name);
      final fileName = '${timestamp}_$sanitizedName';
      final filePath = 'documents/$propertyId/$fileName';

      print('Uploading file: $fileName (${file.size} bytes)');
      print('Upload path: $filePath');

      // Test Firebase Storage connectivity first
      try {
        await _storage.ref().child('test').getDownloadURL();
      } catch (e) {
        print('Firebase Storage connectivity test failed: $e');
        // Continue anyway - the test might fail even if upload works
      }

      // Create reference
      Reference ref = _storage.ref().child(filePath);

      // Set minimal metadata to avoid issues
      SettableMetadata metadata = SettableMetadata(
        contentType: _getContentType(file.extension ?? ''),
        customMetadata: {
          'documentType': documentType,
          'originalName': file.name,
        },
      );

      // Configure upload task
      UploadTask uploadTask = ref.putData(file.bytes!, metadata);

      // Monitor progress with more frequent updates
      int lastProgress = -1;
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        int progress =
            ((snapshot.bytesTransferred / snapshot.totalBytes) * 100).round();
        if (progress != lastProgress && progress % 5 == 0) {
          print(
            'Upload progress: $progress% (${snapshot.bytesTransferred}/${snapshot.totalBytes} bytes)',
          );
          lastProgress = progress;
        }
      });

      // Use shorter timeout with manual checking
      TaskSnapshot? snapshot;
      int timeoutSeconds = 60; // Start with 1 minute timeout
      int checkIntervalSeconds = 5;
      int elapsedSeconds = 0;

      while (elapsedSeconds < timeoutSeconds) {
        try {
          snapshot = await uploadTask.timeout(
            Duration(seconds: checkIntervalSeconds),
          );
          break; // Upload completed
        } on TimeoutException {
          elapsedSeconds += checkIntervalSeconds;
          print('Upload still in progress... ${elapsedSeconds}s elapsed');

          // Check if task is still running
          TaskSnapshot currentSnapshot = await uploadTask.snapshot;
          if (currentSnapshot.state == TaskState.success) {
            snapshot = currentSnapshot;
            break;
          } else if (currentSnapshot.state == TaskState.error) {
            throw Exception('Upload failed during progress check');
          } else if (currentSnapshot.state == TaskState.canceled) {
            throw Exception('Upload was canceled');
          }

          // Continue waiting if still running or paused
          continue;
        }
      }

      // Final timeout check
      if (snapshot == null) {
        print('Upload timed out after ${timeoutSeconds}s, canceling...');
        await uploadTask.cancel();
        throw Exception('Upload timed out after ${timeoutSeconds} seconds');
      }

      // Verify upload completed successfully
      if (snapshot.state != TaskState.success) {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }

      print('Upload completed, getting download URL...');

      // Get download URL with timeout
      String downloadUrl = await ref.getDownloadURL().timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Timeout getting download URL'),
          );

      print('Upload completed successfully: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase error uploading document: ${e.code} - ${e.message}');
      print('Full Firebase error: $e');

      // Handle specific Firebase errors
      switch (e.code) {
        case 'storage/retry-limit-exceeded':
          throw Exception(
            'Network connection issues. Please check your internet and try again.',
          );
        case 'storage/unauthorized':
          throw Exception(
            'Permission denied. Please check Firebase Storage rules.',
          );
        case 'storage/canceled':
          throw Exception('Upload was canceled or interrupted.');
        case 'storage/invalid-format':
          throw Exception(
            'Invalid file format. Supported: PDF, DOC, DOCX, JPG, PNG, TXT',
          );
        case 'storage/quota-exceeded':
          throw Exception('Storage quota exceeded. Please contact support.');
        case 'storage/unauthenticated':
          throw Exception('Authentication required. Please log in again.');
        default:
          throw Exception(
            'Firebase error (${e.code}): ${e.message ?? 'Unknown error'}',
          );
      }
    } catch (e) {
      print('General error uploading document: $e');

      if (e.toString().contains('timeout') ||
          e.toString().contains('TimeoutException')) {
        throw Exception(
          'Connection timeout. Please check your internet connection and try again.',
        );
      }

      rethrow;
    }
  }

  static String _sanitizeFileName(String fileName) {
    // Remove or replace invalid characters for Firebase Storage
    return fileName
        .replaceAll(
          RegExp(r'[<>:"/\\|?*]'),
          '_',
        ) // Replace invalid chars with underscore
        .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with underscore
        .replaceAll(
          RegExp(r'_+'),
          '_',
        ) // Replace multiple underscores with single
        .toLowerCase();
  }

  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  static Future<void> deleteDocument(String url) async {
    try {
      Reference ref = _storage.refFromURL(url);
      await ref.delete();
      print('Document deleted successfully: $url');
    } on FirebaseException catch (e) {
      print('Firebase error deleting document: ${e.code} - ${e.message}');
      if (e.code != 'storage/object-not-found') {
        // Don't throw error if file doesn't exist
        rethrow;
      }
    } catch (e) {
      print('Error deleting document: $e');
      rethrow;
    }
  }

  // Helper method to check if a file extension is supported
  static bool isSupportedFileType(String? extension) {
    if (extension == null) return false;

    const supportedExtensions = [
      'pdf',
      'doc',
      'docx',
      'jpg',
      'jpeg',
      'png',
      'txt',
    ];

    return supportedExtensions.contains(extension.toLowerCase());
  }

  // Helper method to format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
