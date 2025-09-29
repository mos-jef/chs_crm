// lib/services/property_delete_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/property_file.dart';
import '../services/document_service.dart';

class PropertyDeleteService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Complete property deletion with all associated data
  static Future<bool> deletePropertyComplete(PropertyFile property) async {
    try {
      print('=== STARTING COMPLETE PROPERTY DELETION ===');
      print('Property: ${property.fileNumber} - ${property.address}');

      // Step 1: Delete all associated documents from Firebase Storage
      final storageDeleteResults = await _deleteAllPropertyDocuments(property);

      // Step 2: Delete property from Firestore
      await _firestore.collection('properties').doc(property.id).delete();
      print('✅ Property deleted from Firestore');

      // Step 3: Log the deletion for audit purposes
      await _logPropertyDeletion(property, storageDeleteResults);

      print('✅ Property deletion completed successfully');
      return true;
    } catch (e) {
      print('❌ Error during property deletion: $e');
      return false;
    }
  }

  /// Delete all documents associated with the property
  static Future<Map<String, bool>> _deleteAllPropertyDocuments(
      PropertyFile property) async {
    final deleteResults = <String, bool>{};

    if (property.documents.isEmpty) {
      print('📄 No documents to delete');
      return deleteResults;
    }

    print('📄 Deleting ${property.documents.length} associated documents...');

    for (final document in property.documents) {
      if (document.url != null && document.url!.isNotEmpty) {
        try {
          await DocumentService.deleteDocument(document.url!);
          deleteResults[document.name] = true;
          print('  ✅ Deleted: ${document.name}');
        } catch (e) {
          deleteResults[document.name] = false;
          print('  ❌ Failed to delete: ${document.name} - $e');
        }
      }
    }

    final successCount =
        deleteResults.values.where((success) => success).length;
    print(
        '📄 Document deletion summary: $successCount/${property.documents.length} successful');

    return deleteResults;
  }

  /// Log property deletion for audit trail
  static Future<void> _logPropertyDeletion(
      PropertyFile property, Map<String, bool> storageDeleteResults) async {
    try {
      final deletionLog = {
        'propertyId': property.id,
        'fileNumber': property.fileNumber,
        'address': property.address,
        'city': property.city,
        'state': property.state,
        'zipCode': property.zipCode,
        'deletedAt': FieldValue.serverTimestamp(),
        'documentsDeleted': storageDeleteResults,
        'totalDocuments': property.documents.length,
        'successfulDocumentDeletions':
            storageDeleteResults.values.where((success) => success).length,
      };

      await _firestore.collection('deletion_audit_log').add(deletionLog);
      print('📝 Deletion logged in audit trail');
    } catch (e) {
      print('⚠️  Failed to log deletion (non-critical): $e');
    }
  }

  /// Soft delete - mark property as deleted but don't remove data
  static Future<bool> softDeleteProperty(PropertyFile property) async {
    try {
      print('=== SOFT DELETING PROPERTY ===');
      print('Property: ${property.fileNumber} - ${property.address}');

      await _firestore.collection('properties').doc(property.id).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Property soft deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error during soft delete: $e');
      return false;
    }
  }

  /// Restore soft-deleted property
  static Future<bool> restoreProperty(PropertyFile property) async {
    try {
      print('=== RESTORING PROPERTY ===');
      print('Property: ${property.fileNumber} - ${property.address}');

      await _firestore.collection('properties').doc(property.id).update({
        'isDeleted': false,
        'deletedAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Property restored successfully');
      return true;
    } catch (e) {
      print('❌ Error during property restore: $e');
      return false;
    }
  }

  /// Batch delete multiple properties
  static Future<Map<String, bool>> batchDeleteProperties(
      List<PropertyFile> properties) async {
    final results = <String, bool>{};

    print('=== BATCH DELETING ${properties.length} PROPERTIES ===');

    for (final property in properties) {
      final success = await deletePropertyComplete(property);
      results[property.fileNumber] = success;

      // Add small delay to avoid overwhelming Firebase
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final successCount = results.values.where((success) => success).length;
    print(
        '📊 Batch deletion summary: $successCount/${properties.length} successful');

    return results;
  }

  /// Get properties marked for deletion (soft delete)
  static Future<List<PropertyFile>> getDeletedProperties() async {
    try {
      final querySnapshot = await _firestore
          .collection('properties')
          .where('isDeleted', isEqualTo: true)
          .orderBy('deletedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PropertyFile.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('❌ Error fetching deleted properties: $e');
      return [];
    }
  }

  /// Permanently delete all soft-deleted properties older than specified days
  static Future<int> purgeOldDeletedProperties({int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final querySnapshot = await _firestore
          .collection('properties')
          .where('isDeleted', isEqualTo: true)
          .where('deletedAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      int purgedCount = 0;
      for (final doc in querySnapshot.docs) {
        final property = PropertyFile.fromMap({...doc.data(), 'id': doc.id});
        final success = await deletePropertyComplete(property);
        if (success) purgedCount++;
      }

      print('🗑️  Purged $purgedCount properties older than $daysOld days');
      return purgedCount;
    } catch (e) {
      print('❌ Error during purge operation: $e');
      return 0;
    }
  }
}
