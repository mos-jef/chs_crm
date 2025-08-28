import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property_file.dart';

class PropertyProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<PropertyFile> _properties = [];
  bool _isLoading = false;
  String _searchQuery = '';
  Map<String, dynamic> _advancedSearchCriteria = {};

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
      print('=== UPDATING PROPERTY ===');
      print('Property ID: ${property.id}');
      print('Property: ${property.fileNumber}');
      print('Documents: ${property.documents.length}');
      print('Notes: ${property.notes.length}');
      print('Trustees: ${property.trustees.length}');
      print('Auctions: ${property.auctions.length}');

      final propertyData = property.toMap();

      // Debug: Print what we're saving
      print('Saving to Firestore:');
      if (propertyData['documents'] != null) {
        final docs = propertyData['documents'] as List;
        print('  - ${docs.length} documents');
        for (var doc in docs) {
          print('    * ${doc['name']} (${doc['type']})');
        }
      }
      if (propertyData['trustees'] != null) {
        final trustees = propertyData['trustees'] as List;
        print('  - ${trustees.length} trustees');
        for (var trustee in trustees) {
          print('    * ${trustee['name']} at ${trustee['institution']}');
        }
      }

      await _firestore
          .collection('properties')
          .doc(property.id)
          .update(propertyData);

      // Update local state - CRITICAL FIX
      final index = _properties.indexWhere((p) => p.id == property.id);
      if (index != -1) {
        _properties[index] = property;
        print('Updated local property cache at index $index');
      } else {
        print('WARNING: Could not find property in local cache!');
        // Force reload if we can't find it locally
        await loadProperties();
      }

      notifyListeners();
      print('Property updated successfully');
    } catch (e) {
      print('Error updating property: $e');
      throw e;
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
