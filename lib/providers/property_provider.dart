import 'package:chs_crm/services/property_delete_service.dart';
import 'package:chs_crm/services/property_enhancement_service.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property_file.dart';

class PropertyProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<PropertyFile> _properties = [];
  bool _isLoading = false;
  String _searchQuery = '';
  Map<String, dynamic> _advancedSearchCriteria = {};
  String _currentSortOption = 'fileNumber_desc'; // Default to newest first

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

  /// Fix address parsing for all existing properties and re-enhance them
  Future<int> fixAllPropertyAddresses() async {
    try {
      print('=== FIXING ALL PROPERTY ADDRESSES ===');
      int fixedCount = 0;

      // Find properties with empty city or zipCode but full address
      final propertiesToFix = _properties
          .where((property) =>
              (property.city.isEmpty || property.zipCode.isEmpty) &&
              property.address.isNotEmpty)
          .toList();

      print(
          'Found ${propertiesToFix.length} properties with address parsing issues');

      for (final property in propertiesToFix) {
        try {
          // Re-parse the address
          final addressComponents = _parseFullAddress(property.address);

          // Create updated property with parsed components
          final fixedProperty = property.copyWith(
            address: addressComponents['streetAddress'] ?? property.address,
            city: addressComponents['city'] ?? '',
            state: addressComponents['state'] ?? property.state,
            zipCode: addressComponents['zipCode'] ?? '',
            updatedAt: DateTime.now(),
          );

          // Now enhance with Zillow URL and county
          final enhancedProperty =
              PropertyEnhancementService.enhanceProperty(fixedProperty);

          // Update in database
          await updateProperty(enhancedProperty);
          fixedCount++;

          print('Fixed and enhanced property: ${property.fileNumber}');
          print('  - Address: ${enhancedProperty.address}');
          print('  - City: ${enhancedProperty.city}');
          print('  - ZIP: ${enhancedProperty.zipCode}');
          print('  - County: ${enhancedProperty.county}');
          print(
              '  - Zillow: ${enhancedProperty.zillowUrl != null ? 'Generated' : 'Failed'}');
        } catch (e) {
          print('Failed to fix property ${property.fileNumber}: $e');
        }
      }

      print('Successfully fixed and enhanced $fixedCount properties');
      return fixedCount;
    } catch (e) {
      print('Error in batch address fix: $e');
      throw e;
    }
  }

// Add this helper method to PropertyProvider:
  static Map<String, String> _parseFullAddress(String fullAddress) {
    try {
      final cleanAddress = fullAddress.trim();

      // Look for state and ZIP at the end: "Street, City, STATE ZIPCODE"
      final stateZipPattern = RegExp(r',\s*([A-Z]{2})\s+(\d{5}(?:-\d{4})?)$');
      final stateZipMatch = stateZipPattern.firstMatch(cleanAddress);

      if (stateZipMatch != null) {
        final state = stateZipMatch.group(1)!;
        final zipCode = stateZipMatch.group(2)!;

        // Remove state and zip to get street and city
        final beforeStateZip =
            cleanAddress.substring(0, stateZipMatch.start).trim();
        final lastCommaIndex = beforeStateZip.lastIndexOf(',');

        if (lastCommaIndex > 0) {
          final streetAddress =
              beforeStateZip.substring(0, lastCommaIndex).trim();
          final city = beforeStateZip.substring(lastCommaIndex + 1).trim();

          return {
            'streetAddress': streetAddress,
            'city': city,
            'state': state,
            'zipCode': zipCode,
          };
        }
      }

      // Fallback: return original as street address
      return {
        'streetAddress': cleanAddress,
        'city': '',
        'state': 'OR',
        'zipCode': '',
      };
    } catch (e) {
      return {
        'streetAddress': fullAddress,
        'city': '',
        'state': 'OR',
        'zipCode': '',
      };
    }
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

  // Getters
  String get currentSortOption => _currentSortOption;

  void setSortOption(String sortOption) {
    _currentSortOption = sortOption;
    notifyListeners();
  }

  List<PropertyFile> get properties {
    var filteredProperties = _properties;

    // Apply search filters first
    if (_searchQuery.isNotEmpty || _advancedSearchCriteria.isNotEmpty) {
      filteredProperties = _properties.where((property) {
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
            if (!property.zipCode
                .contains(_advancedSearchCriteria['zipCode'])) {
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

          // NEW FILTERS - Bank Owned vs Foreclosure
          if (_advancedSearchCriteria.containsKey('bankOwned')) {
            final hasBankOwnedAuction = property.auctions.any(
              (auction) => auction.place.toLowerCase().contains('bank owned'),
            );
            if (!hasBankOwnedAuction) return false;
          }

          if (_advancedSearchCriteria.containsKey('foreclosure')) {
            final hasForeclosureAuction = property.auctions.any(
              (auction) => auction.place.toLowerCase().contains('foreclosure'),
            );
            if (!hasForeclosureAuction) return false;
          }

          // NEW FILTERS - Has Documents
          if (_advancedSearchCriteria.containsKey('hasDocuments')) {
            if (property.documents.isEmpty) return false;
          }

          // NEW FILTERS - Has Notes
          if (_advancedSearchCriteria.containsKey('hasNotes')) {
            if (property.notes.isEmpty) return false;
          }

          // NEW FILTERS - Has Upcoming Auctions
          if (_advancedSearchCriteria.containsKey('hasUpcomingAuctions')) {
            final hasUpcoming = property.auctions.any(
              (auction) =>
                  !auction.auctionCompleted &&
                  auction.auctionDate.isAfter(DateTime.now()),
            );
            if (!hasUpcoming) return false;
          }
        }

        return true;
      }).toList();
    }

    // Apply sorting
    switch (_currentSortOption) {
      case 'fileNumber_asc':
        filteredProperties.sort((a, b) => a.fileNumber.compareTo(b.fileNumber));
        break;
      case 'fileNumber_desc':
        filteredProperties.sort((a, b) => b.fileNumber.compareTo(a.fileNumber));
        break;
      case 'saleDate_asc':
        filteredProperties.sort((a, b) {
          final aDate = _getNextAuctionDate(a);
          final bDate = _getNextAuctionDate(b);
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return aDate.compareTo(bDate);
        });
        break;
      case 'saleDate_desc':
        filteredProperties.sort((a, b) {
          final aDate = _getNextAuctionDate(a);
          final bDate = _getNextAuctionDate(b);
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });
        break;
      case 'totalOwed_asc':
        filteredProperties.sort((a, b) {
          final aTotal = a.totalOwed;
          final bTotal = b.totalOwed;
          return aTotal.compareTo(bTotal);
        });
        break;
      case 'totalOwed_desc':
        filteredProperties.sort((a, b) {
          final aTotal = a.totalOwed;
          final bTotal = b.totalOwed;
          return bTotal.compareTo(aTotal);
        });
        break;
      case 'loanAmount_asc':
        filteredProperties.sort((a, b) {
          final aLoan = a.loanAmount ?? 0;
          final bLoan = b.loanAmount ?? 0;
          return aLoan.compareTo(bLoan);
        });
        break;
      case 'loanAmount_desc':
        filteredProperties.sort((a, b) {
          final aLoan = a.loanAmount ?? 0;
          final bLoan = b.loanAmount ?? 0;
          return bLoan.compareTo(aLoan);
        });
        break;
      case 'address_asc':
        filteredProperties.sort((a, b) => a.address.compareTo(b.address));
        break;
      case 'city_asc':
        filteredProperties.sort((a, b) => a.city.compareTo(b.city));
        break;
      default:
        // Default to newest file number first
        filteredProperties.sort((a, b) => b.fileNumber.compareTo(a.fileNumber));
        break;
    }

    return filteredProperties;
  }

  // Helper method to get next auction date for sorting
  DateTime? _getNextAuctionDate(PropertyFile property) {
    if (property.auctions.isEmpty) return null;

    // Find the next upcoming auction (not completed) or the most recent one
    Auction? nextAuction;

    // First try to find an upcoming auction
    for (var auction in property.auctions) {
      if (!auction.auctionCompleted) {
        if (nextAuction == null ||
            auction.auctionDate.isBefore(nextAuction.auctionDate)) {
          nextAuction = auction;
        }
      }
    }

    // If no upcoming auctions, get the most recent completed one
    if (nextAuction == null) {
      for (var auction in property.auctions) {
        if (nextAuction == null ||
            auction.auctionDate.isAfter(nextAuction.auctionDate)) {
          nextAuction = auction;
        }
      }
    }

    return nextAuction?.auctionDate;
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

      _properties = querySnapshot.docs.map((doc) {
        final data = {...doc.data(), 'id': doc.id};
        final property = PropertyFile.fromMap(data);
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

      final docRef =
          await _firestore.collection('properties').add(property.toMap());

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
      final property = getPropertyById(propertyId);
      if (property == null) {
        throw Exception('Property not found');
      }

      // Use the comprehensive delete service
      final success =
          await PropertyDeleteService.deletePropertyComplete(property);

      if (success) {
        _properties.removeWhere((p) => p.id == propertyId);
        notifyListeners();
      } else {
        throw Exception('Failed to delete property completely');
      }
    } catch (e) {
      print('Error deleting property: $e');
      throw e;
    }
  }

  // Add soft delete capability
  Future<void> softDeleteProperty(String propertyId) async {
    try {
      final property = getPropertyById(propertyId);
      if (property == null) {
        throw Exception('Property not found');
      }

      final success = await PropertyDeleteService.softDeleteProperty(property);

      if (success) {
        await loadProperties(); // Refresh to hide soft-deleted properties
      } else {
        throw Exception('Failed to soft delete property');
      }
    } catch (e) {
      print('Error soft deleting property: $e');
      throw e;
    }
  }

// Add restore capability
  Future<void> restoreProperty(String propertyId) async {
    try {
      final property = getPropertyById(propertyId);
      if (property == null) {
        throw Exception('Property not found');
      }

      final success = await PropertyDeleteService.restoreProperty(property);

      if (success) {
        await loadProperties(); // Refresh to show restored property
      } else {
        throw Exception('Failed to restore property');
      }
    } catch (e) {
      print('Error restoring property: $e');
      throw e;
    }
  }

// Add batch delete capability
  Future<Map<String, bool>> batchDeleteProperties(
      List<String> propertyIds) async {
    try {
      final properties = propertyIds
          .map((id) => getPropertyById(id))
          .where((prop) => prop != null)
          .cast<PropertyFile>()
          .toList();

      final results =
          await PropertyDeleteService.batchDeleteProperties(properties);

      // Remove successful deletions from local cache
      for (final entry in results.entries) {
        if (entry.value) {
          // If deletion was successful
          _properties.removeWhere((p) => p.fileNumber == entry.key);
        }
      }

      notifyListeners();
      return results;
    } catch (e) {
      print('Error batch deleting properties: $e');
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
  /// Batch enhance all existing properties
  Future<int> enhanceAllProperties() async {
    try {
      print('=== ENHANCING ALL PROPERTIES ===');
      int enhancedCount = 0;

      final propertiesToEnhance = _properties
          .where((property) =>
              PropertyEnhancementService.needsEnhancement(property))
          .toList();

      print(
          'Found ${propertiesToEnhance.length} properties that need enhancement');

      for (final property in propertiesToEnhance) {
        try {
          final enhancedProperty =
              PropertyEnhancementService.enhanceProperty(property);
          await updateProperty(enhancedProperty);
          enhancedCount++;
          print('Enhanced property: ${property.fileNumber}');
        } catch (e) {
          print('Failed to enhance property ${property.fileNumber}: $e');
        }
      }

      print('Successfully enhanced $enhancedCount properties');
      return enhancedCount;
    } catch (e) {
      print('Error in batch enhancement: $e');
      throw e;
    }
  }

  /// Enhance a single property
  Future<void> enhanceProperty(String propertyId) async {
    try {
      final property = getPropertyById(propertyId);
      if (property == null) {
        throw Exception('Property not found');
      }

      if (PropertyEnhancementService.needsEnhancement(property)) {
        final enhancedProperty =
            PropertyEnhancementService.enhanceProperty(property);
        await updateProperty(enhancedProperty);
        print('Enhanced property: ${property.fileNumber}');
      } else {
        print('Property ${property.fileNumber} already enhanced');
      }
    } catch (e) {
      print('Error enhancing property: $e');
      throw e;
    }
  }
}
