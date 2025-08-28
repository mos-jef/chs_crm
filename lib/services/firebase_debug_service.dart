import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseDebugService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Comprehensive Firebase connectivity test
  static Future<Map<String, dynamic>> runDiagnostics() async {
    Map<String, dynamic> results = {};

    print('Starting Firebase diagnostics...');

    // 1. Check Authentication
    try {
      final user = _auth.currentUser;
      results['auth'] = {
        'status': user != null ? 'authenticated' : 'not_authenticated',
        'uid': user?.uid,
        'email': user?.email,
        'emailVerified': user?.emailVerified,
      };
      print(
        'Auth Status: ${user != null ? "✓ Authenticated" : "✗ Not authenticated"}',
      );
    } catch (e) {
      results['auth'] = {'status': 'error', 'error': e.toString()};
      print('Auth Error: $e');
    }

    // 2. Test Firestore Connection
    try {
      print('Testing Firestore connection...');
      final testDoc = await _firestore
          .collection('debug_test')
          .doc('connection')
          .get()
          .timeout(const Duration(seconds: 10));
      results['firestore'] = {
        'status': 'connected',
        'document_exists': testDoc.exists,
        'timestamp': DateTime.now().toIso8601String(),
      };
      print('Firestore: ✓ Connected');
    } catch (e) {
      results['firestore'] = {'status': 'error', 'error': e.toString()};
      print('Firestore Error: $e');
    }

    // 3. Test Firebase Storage - Basic Info
    try {
      print('Testing Firebase Storage info...');
      final bucket = _storage.bucket;
      final maxUploadRetryTime = _storage.maxUploadRetryTime;
      final maxDownloadRetryTime = _storage.maxDownloadRetryTime;

      results['storage_info'] = {
        'bucket': bucket,
        'max_upload_retry': maxUploadRetryTime.inMilliseconds,
        'max_download_retry': maxDownloadRetryTime.inMilliseconds,
      };
      print('Storage Info: Bucket = $bucket');
    } catch (e) {
      results['storage_info'] = {'status': 'error', 'error': e.toString()};
      print('Storage Info Error: $e');
    }

    // 4. Test Firebase Storage - Simple Upload
    try {
      print('Testing simple Firebase Storage upload...');

      // Create minimal test data
      final testData = Uint8List.fromList(
        'Hello Firebase Storage Test'.codeUnits,
      );
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testPath = 'debug_test/test_${timestamp}.txt';

      print('Attempting upload to: $testPath');

      final ref = _storage.ref().child(testPath);

      // Try the simplest possible upload
      final uploadTask = ref.putData(testData);

      // Monitor with shorter timeout
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('Upload timed out, canceling...');
          uploadTask.cancel();
          throw Exception('Upload timed out after 30 seconds');
        },
      );

      if (snapshot.state == TaskState.success) {
        final downloadUrl = await ref.getDownloadURL();
        results['storage_upload'] = {
          'status': 'success',
          'path': testPath,
          'download_url': downloadUrl,
          'bytes_transferred': snapshot.bytesTransferred,
          'total_bytes': snapshot.totalBytes,
        };
        print('Storage Upload: ✓ Success');

        // Clean up test file
        try {
          await ref.delete();
          print('Test file cleaned up');
        } catch (e) {
          print('Could not clean up test file: $e');
        }
      } else {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }
    } catch (e) {
      results['storage_upload'] = {'status': 'error', 'error': e.toString()};
      print('Storage Upload Error: $e');
    }

    // 5. Test Firebase Storage - List Operation
    try {
      print('Testing Firebase Storage list operation...');
      final listResult = await _storage
          .ref()
          .child('debug_test')
          .listAll()
          .timeout(const Duration(seconds: 10));

      results['storage_list'] = {
        'status': 'success',
        'items_count': listResult.items.length,
        'prefixes_count': listResult.prefixes.length,
      };
      print('Storage List: ✓ Success (${listResult.items.length} items)');
    } catch (e) {
      results['storage_list'] = {'status': 'error', 'error': e.toString()};
      print('Storage List Error: $e');
    }

    print('Diagnostics complete');
    return results;
  }

  /// Quick test to check if storage is working at all
  static Future<bool> quickStorageTest() async {
    try {
      print('Running quick storage test...');

      // Try to get storage info
      final bucket = _storage.bucket;
      print('Storage bucket: $bucket');

      // Try a very simple operation
      final testData = Uint8List.fromList('test'.codeUnits);
      final ref = _storage.ref().child('quick_test/test.txt');

      final uploadTask = ref.putData(testData);
      await uploadTask.timeout(const Duration(seconds: 15));

      // Clean up
      await ref.delete();

      print('Quick storage test: ✓ PASSED');
      return true;
    } catch (e) {
      print('Quick storage test: ✗ FAILED - $e');
      return false;
    }
  }

  /// Test with different upload configurations
  static Future<String?> testUploadWithConfig({
    required Uint8List data,
    required String path,
    Map<String, String>? metadata,
  }) async {
    try {
      print('Testing upload with custom config...');
      print('Path: $path, Size: ${data.length} bytes');

      final ref = _storage.ref().child(path);

      SettableMetadata? meta;
      if (metadata != null) {
        meta = SettableMetadata(
          contentType: 'text/plain',
          customMetadata: metadata,
        );
      }

      final uploadTask =
          meta != null ? ref.putData(data, meta) : ref.putData(data);

      // Monitor progress
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('Upload progress: ${progress.toStringAsFixed(1)}%');
      });

      final snapshot = await uploadTask.timeout(const Duration(seconds: 30));

      if (snapshot.state == TaskState.success) {
        final url = await ref.getDownloadURL();
        print('Upload successful: $url');
        return url;
      } else {
        throw Exception('Upload failed: ${snapshot.state}');
      }
    } catch (e) {
      print('Upload test failed: $e');
      return null;
    }
  }
}
