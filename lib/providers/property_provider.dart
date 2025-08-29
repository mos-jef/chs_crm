import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property_file.dart';

class PropertyProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<PropertyFile> _properties = [];
  bool _isLoading = false;
  String _searchQuery = '';
  Map<String, dynamic> _advancedSearchCriteria = {};

  PropertyFile _createUpdatedProperty(
    PropertyFile original, {
    String? id,
    String? fileNumber,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    double? loanAmount,
    double? amountOwed,
    double? arrears,
    String? zillowUrl,
    List<Contact>? contacts,
    List<Document>? documents,
    List<Judgment>? judgments,
    List<Note>? notes,
    List<Trustee>? trustees,
    List<Auction>? auctions,
    VestingInfo? vesting,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PropertyFile(
      id: id ?? original.id,
      fileNumber: fileNumber ?? original.fileNumber,
      address: address ?? original.address,
      city: city ?? original.city,
      state: state ?? original.state,
      zipCode: zipCode ?? original.zipCode,
      loanAmount: loanAmount ?? original.loanAmount,
      amountOwed: amountOwed ?? original.amountOwed,
      arrears: arrears ?? original.arrears,
      zillowUrl: zillowUrl ?? original.zillowUrl,
      contacts: contacts ?? original.contacts,
      documents: documents ?? original.documents,
      judgments: judgments ?? original.judgments,
      notes: notes ?? original.notes,
      trustees: trustees ?? original.trustees,
      auctions: auctions ?? original.auctions,
      vesting: vesting ?? original.vesting,
      createdAt: createdAt ?? original.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Enhanced update method with validation
  Future<void> updatePropertySafe(PropertyFile property) async {
    try {
      // Validate that property has all required fields
      if (property.id.isEmpty) {
        throw Exception('Property ID cannot be empty');
      }

      if (!_validatePropertyFile(property)) {
        throw Exception(
          'PropertyFile validation failed - missing required fields',
        );
      }

      await updateProperty(property);

      // Force a refresh to ensure UI consistency
      await refreshProperty(property.id);
    } catch (e) {
      print('Error in updatePropertySafe: $e');
      // Force a complete reload if update fails
      await loadProperties();
      rethrow;
    }
  }

  /// Validate PropertyFile completeness
  bool _validatePropertyFile(PropertyFile property) {
    if (property.id.isEmpty) return false;
    if (property.fileNumber.isEmpty) return false;
    if (property.address.isEmpty) return false;
    if (property.city.isEmpty) return false;
    if (property.state.isEmpty) return false;
    if (property.zipCode.isEmpty) return false;
    // Add more validations as needed
    return true;
  }

  List<PropertyFile> get properties {
    if (_searchQuery.isEmpty && _advancedSearchCriteria.isEmpty) {
      return _properties;
    }

    return _properties.where((property) {
      // Basic search
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesBasic =
            property.fileNumber.toLowerCase().contains(query) ||
            property.address.toLowerCase().contains(query);
        if (!matchesBasic) return false;
      }

      // Advanced search
      if (_advancedSearchCriteria.isNotEmpty) {
        if (_advancedSearchCriteria.containsKey('fileNumber')) {
          if (!property.fileNumber.toLowerCase().contains(
            _advancedSearchCriteria['fileNumber'].toLowerCase(),
          )) {
            return false;
          }
        }
        if (_advancedSearchCriteria.containsKey('address')) {
          if (!property.address.toLowerCase().contains(
            _advancedSearchCriteria['address'].toLowerCase(),
          )) {
            return false;
          }
        }
        if (_advancedSearchCriteria.containsKey('city')) {
          if (!property.city.toLowerCase().contains(
            _advancedSearchCriteria['city'].toLowerCase(),
          )) {
            return false;
          }
        }
        if (_advancedSearchCriteria.containsKey('state')) {
          if (!property.state.toLowerCase().contains(
            _advancedSearchCriteria['state'].toLowerCase(),
          )) {
            return false;
          }
        }
        if (_advancedSearchCriteria.containsKey('zipCode')) {
          if (!property.zipCode.contains(_advancedSearchCriteria['zipCode'])) {
            return false;
          }
        }
        if (_advancedSearchCriteria.containsKey('minLoan') &&
            property.loanAmount != null) {
          if (property.loanAmount! < _advancedSearchCriteria['minLoan']) {
            return false;
          }
        }
        if (_advancedSearchCriteria.containsKey('maxLoan') &&
            property.loanAmount != null) {
          if (property.loanAmount! > _advancedSearchCriteria['maxLoan']) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  Map<String, dynamic> get advancedSearchCriteria => _advancedSearchCriteria;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setAdvancedSearchCriteria(Map<String, dynamic> criteria) {
    _advancedSearchCriteria = criteria;
    _searchQuery = ''; // Clear basic search when using advanced search
    notifyListeners();
  }

  void clearAllSearch() {
    _searchQuery = '';
    _advancedSearchCriteria = {};
    notifyListeners();
  }

  Future<void> loadProperties() async {
    print('=== LOADING PROPERTIES ===');
    _isLoading = true;
    notifyListeners();

    try {
      final querySnapshot = await _firestore.collection('properties').get();
      print('Found ${querySnapshot.docs.length} properties in Firestore');

      _properties =
          querySnapshot.docs.map((doc) {
            final data = {...doc.data(), 'id': doc.id};
            final property = PropertyFile.fromMap(data);

            // Debug logging for each property
            print('Property ${property.fileNumber}:');
            print('  - Documents: ${property.documents.length}');
            print('  - Notes: ${property.notes.length}');
            print('  - Trustees: ${property.trustees.length}');
            print('  - Auctions: ${property.auctions.length}');

            return property;
          }).toList();

      print('Total properties loaded: ${_properties.length}');
    } catch (e) {
      print('Error loading properties: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProperty(PropertyFile property) async {
    try {
      print('=== ADDING PROPERTY ===');
      print('Property: ${property.fileNumber}');

      final docRef = await _firestore
          .collection('properties')
          .add(property.toMap());

      final newProperty = PropertyFile.fromMap({
        ...property.toMap(),
        'id': docRef.id,
      });

      _properties.add(newProperty);
      print('Property added successfully with ID: ${docRef.id}');
      notifyListeners();
    } catch (e) {
      print('Error adding property: $e');
      throw e;
    }
  }

  Future<void> updateProperty(PropertyFile property) async {
    try {
      print('=== UPDATING PROPERTY (ENHANCED DEBUG) ===');
      print('Property ID: ${property.id}');
      print('Property: ${property.fileNumber}');
      print('Documents: ${property.documents.length}');
      print('Notes: ${property.notes.length}');
      print('Trustees: ${property.trustees.length}');
      print('Auctions: ${property.auctions.length}');
      print('Judgments: ${property.judgments.length}');

      // Detailed logging of what we're about to save
      if (property.notes.isNotEmpty) {
        print('NOTES BEING SAVED:');
        for (var note in property.notes) {
          print(
            '  - "${note.subject}" (${note.id}) - Created: ${note.createdAt}',
          );
        }
      }

      if (property.trustees.isNotEmpty) {
        print('TRUSTEES BEING SAVED:');
        for (var trustee in property.trustees) {
          print(
            '  - "${trustee.name}" at ${trustee.institution} (${trustee.id})',
          );
        }
      }

      final propertyData = property.toMap();

      // CRITICAL: Remove the id field from the data being sent to Firestore
      // Firestore doesn't like when you try to update the document ID field
      propertyData.remove('id');

      print('=== FIRESTORE UPDATE STARTING ===');
      await _firestore
          .collection('properties')
          .doc(property.id)
          .update(propertyData);
      print('=== FIRESTORE UPDATE COMPLETED ===');

      // Update local state - ENHANCED VERSION
      final index = _properties.indexWhere((p) => p.id == property.id);
      if (index != -1) {
        _properties[index] = property;
        print('✅ Updated local property cache at index $index');

        // Verify the update worked locally
        print('LOCAL VERIFICATION:');
        print('  - Notes in cache: ${_properties[index].notes.length}');
        print('  - Trustees in cache: ${_properties[index].trustees.length}');
      } else {
        print('❌ WARNING: Could not find property in local cache!');
        print('Available property IDs in cache:');
        for (var p in _properties) {
          print('  - ${p.id} (${p.fileNumber})');
        }

        // Force reload if we can't find it locally
        print('🔄 Force reloading all properties...');
        await loadProperties();
        return; // Exit early since we reloaded everything
      }

      // Force UI update
      notifyListeners();
      print('🔔 notifyListeners() called');

      // Wait a bit then verify the data is actually in Firestore
      await Future.delayed(Duration(seconds: 1));
      await _verifyFirestoreData(property.id);

      print('✅ Property updated successfully');
    } catch (e) {
      print('❌ Error updating property: $e');
      print('Stack trace: ${StackTrace.current}');

      // Force reload on error
      print('🔄 Force reloading due to error...');
      await loadProperties();
      throw e;
    }
  }

  // Add this new method to verify data was actually saved
  Future<void> _verifyFirestoreData(String propertyId) async {
    try {
      print('=== VERIFYING FIRESTORE DATA ===');
      final doc =
          await _firestore.collection('properties').doc(propertyId).get();

      if (doc.exists) {
        final data = doc.data()!;
        final notes = data['notes'] as List<dynamic>? ?? [];
        final trustees = data['trustees'] as List<dynamic>? ?? [];

        print('📋 Firestore verification:');
        print('  - Notes in Firestore: ${notes.length}');
        print('  - Trustees in Firestore: ${trustees.length}');

        if (notes.isNotEmpty) {
          print('  Notes details:');
          for (var note in notes) {
            print('    * ${note['subject']} (${note['id']})');
          }
        }

        if (trustees.isNotEmpty) {
          print('  Trustees details:');
          for (var trustee in trustees) {
            print(
              '    * ${trustee['name']} at ${trustee['institution']} (${trustee['id']})',
            );
          }
        }
      } else {
        print('❌ Document not found in Firestore!');
      }
    } catch (e) {
      print('❌ Error verifying Firestore data: $e');
    }
  }

  Future<void> deleteProperty(String propertyId) async {
    try {
      await _firestore.collection('properties').doc(propertyId).delete();
      _properties.removeWhere((property) => property.id == propertyId);
      notifyListeners();
    } catch (e) {
      print('Error deleting property: $e');
      throw e;
    }
  }

  // Get a specific property by ID - helps with data consistency
  PropertyFile? getPropertyById(String id) {
    try {
      return _properties.firstWhere((p) => p.id == id);
    } catch (e) {
      print('Property not found in cache: $id');
      return null;
    }
  }

  // Force refresh a specific property from Firestore
  Future<PropertyFile?> refreshProperty(String propertyId) async {
    try {
      print('=== REFRESHING SINGLE PROPERTY ===');
      print('Property ID: $propertyId');

      final doc =
          await _firestore.collection('properties').doc(propertyId).get();

      if (doc.exists) {
        final data = {...doc.data()!, 'id': doc.id};
        final property = PropertyFile.fromMap(data);

        // Update in local cache
        final index = _properties.indexWhere((p) => p.id == propertyId);
        if (index != -1) {
          _properties[index] = property;
        } else {
          _properties.add(property);
        }

        notifyListeners();
        print('Property refreshed successfully');
        return property;
      } else {
        print('Property not found in Firestore: $propertyId');
        return null;
      }
    } catch (e) {
      print('Error refreshing property: $e');
      return null;
    }
  }
}
